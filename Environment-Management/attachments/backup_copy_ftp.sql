CREATE SCHEMA TEST;
OPEN SCHEMA TEST;

--
-- UDF to incrementaly copy all local backups to an remote system
-- 
-- To use it, simply set the correct access URLs and IP addresses to
-- the remote nodes, create the UDF and call it in following SQL:
-- 
-- SQL_EXA> SELECT syncBackups(IPROC) FROM EXA_LOADAVG;
--
-- The copy process runs completely parallel, distributed over all
-- nodes and only files missing in the remote system are copied, so
-- this UDF can be called on regulary. Backup files which are removed
-- from the source will alse be removed in the remote system.
-- 
--/
CREATE OR REPLACE PYTHON SCALAR SCRIPT syncBackups(iproc INT) EMITS (iproc INT, lnum INT, line VARCHAR(2000000)) AS
from socket import inet_ntoa, AF_INET, SOCK_DGRAM, socket
from fcntl import ioctl
from struct import pack
from ftplib import FTP_TLS
from cStringIO import StringIO
from urlparse import urlparse

LOCAL_URL    = 'ftp://admin:admin@%s/v0001'
REMOTE_URL   = 'ftp://admin:admin@%s/v0002'
REMOTE_NODES = [ '27.1.0.11',
                 '27.1.0.12',
                 '27.1.0.13',
                 '27.1.0.14', ]

class _ftp_writer(object):
    def __init__(self, ftp, fpath): self._fpath = fpath; self._ftp = ftp
    def __enter__(self):
        self._ftp.voidcmd('TYPE I')
        self._conn = self._ftp.transfercmd('STOR %s' % self._fpath)
        self.length = 0
        return self
    def __exit__(self, type, value, traceback):
        self._conn.close(); self._ftp.voidresp()
    def write(self, data):
        if data is not None:
            self._conn.sendall(data)
            self.length += len(data)
        
class ArchiveVolume:
    def __init__(self, host, port, user, pwd, vol):
        self._conn = (host, port, user, pwd)
        self._vol = vol
        self._ftp = FTP_TLS()
        self._ftp.connect(host, port)
        self._ftp.login(user, pwd)
        self._ftp.prot_p()
        volumes = set(); self._ftp.retrlines('NLST', volumes.add)
        if vol not in volumes:
            raise RuntimeError('Volume %s not found' % repr(vol))
        self._ftp.sendcmd('CWD %s' % vol)

    def _ls(self, path):
        status = self._ftp.sendcmd('CWD /%s/%s' % (self._vol, path))
        if not status.startswith('250 '):
            raise RuntimeError('List of path %s failed: %s' % (repr(path), status))
        filelist = []; self._ftp.retrlines('NLST', filelist.append)
        return sorted([fname for fname in filelist if not fname.endswith('.tar.gz') and fname != '~'])

    def goBackup(self, dbname, backupid, level, nodeid):
        self._ftp.sendcmd('CWD /%s/%s' % (self._vol, '/'.join((dbname, backupid, level, nodeid))))
    def dbNames(self): return self._ls('')
    def backupIds(self, dbname): return self._ls(dbname)
    def backupLevel(self, dbname, backupid): return self._ls('%s/%s' % (dbname, backupid))[0]
    def nodesList(self, dbname, backupid, level = None):
        if level is None: level = self.backupLevel(dbname, backupid)
        return self._ls('/'.join((dbname, backupid, self.backupLevel(dbname, backupid)))), level
    def filesList(self, dbname, backupid, nodeid, level = None):
        if level is None: level = self.backupLevel(dbname, backupid)
        return self._ls('/'.join((dbname, backupid, level, nodeid))), level
    def writeFile(self, fpath): return _ftp_writer(self._ftp, fpath)
    def removeFile(self, dbname, backupid, level, nodeid, fname):
        self._ftp.sendcmd('DELE /%s' % '/'.join((self._vol, dbname, backupid, level, nodeid, fname)))
    def copyFile(self, dst, dbname, backupid, level, nodeid, fname):
        pathdata = [dbname, backupid, level, nodeid]
        fpath = []
        while len(pathdata) > 0:
            dat = pathdata.pop(0)
            fpath.append(dat)
            dest = '/'.join(fpath)
            if dat not in dst._ls('/'.join(fpath)):
                dst._ftp.mkd(dest)
        self.goBackup(*fpath)
        dst.goBackup(*fpath)
        fpath.append(fname)
        fpath = '/'.join(fpath)
        with dst.writeFile(fname) as fd:
            self._ftp.retrbinary('RETR %s' % fname, fd.write)
            return fd.length

def getBackupList(vol):
    lst = set()
    for db in vol.dbNames():
        try: backupIdsList = vol.backupIds(db)
        except: continue
        for bid in backupIdsList:
            try: nodeslist, level = vol.nodesList(db, bid)
            except: continue
            for nid in nodeslist:
                try: fileslist, level = vol.filesList(db, bid, nid, level = level)
                except: continue
                for fname in fileslist:
                    lst.add((db, bid, level, nid, fname))
    return lst

def syncBackups(source, destination, node_id, debug = False):
    if node_id is not None: node = "node_%d" % node_id
    else: node = None
    src_url, dst_url = urlparse(source), urlparse(destination)
    if src_url.scheme != 'ftp' or dst_url.scheme != 'ftp':
        raise RuntimeError('Only FTP access protocol is supported')
    if src_url.port is None: src_port = 2021
    else: src_port = src_url.port
    if dst_url.port is None: dst_port = 2021
    else: dst_port = dst_url.port
    src_vol = ArchiveVolume(src_url.hostname, int(src_port), src_url.username, src_url.password, src_url.path.split('/')[1])
    dst_vol = ArchiveVolume(dst_url.hostname, int(dst_port), dst_url.username, dst_url.password, dst_url.path.split('/')[1])
    src_lst, dst_lst = getBackupList(src_vol), getBackupList(dst_vol)
    for fpath in sorted(src_lst):
        if fpath in dst_lst: continue
        if node is not None and fpath[3] != node: continue
        length = src_vol.copyFile(dst_vol, *fpath)
        if debug: print "cp", '/'.join(fpath), "->", length
    for fpath in sorted(dst_lst):
        if fpath in src_lst: continue
        if node is not None and fpath[3] != node: continue
        if debug: print "rm", '/'.join(fpath)
        try: dst_vol.removeFile(*fpath)
        except:
            if debug: print "rm", repr(fpath), "(-)"

def run(ctx):
    sys.stdout = sys.stderr = output = StringIO()
    nid = int(ctx.iproc)
    sfd = socket(AF_INET, SOCK_DGRAM)
    currentip = inet_ntoa(ioctl(sfd.fileno(), 0x8915, pack('256s', 'eth0'))[20:24])
    sfd.close()
    syncBackups(LOCAL_URL % currentip,
                REMOTE_URL % REMOTE_NODES[nid],
                int(nid), True)
    lnum = 0
    for line in output.getvalue().split('\n'):
        if len(line.strip()) == 0: continue
        ctx.emit(nid, lnum, line)
        lnum += 1

/

SELECT syncBackups(IPROC) FROM EXA_LOADAVG;


