open schema arcgis;

--/
CREATE or replace PYTHON3 SCALAR SCRIPT arcgis_geocode_test() returns VARCHAR(2000000) AS
import requests
import json
def run(ctx):
	r = requests.get(
		'https://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer/find',
		params={
			'text': 'Neumeyerstr. 48 Nürnberg',
			'f': 'pjson'
		}
	)
	return r.text
/

select arcgis_geocode_test();

--/
CREATE or replace PYTHON3 SCALAR SCRIPT arcgis_reverse_geocode_test() returns VARCHAR(2000000) AS
import requests
import json
def run(ctx):
	r = requests.get(
		'https://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer/reverseGeocode',
		params={
			'location': '11.121198551000418,49.481473190000486',
			'f': 'pjson'
		}
	)
	return r.text
/

select arcgis_reverse_geocode_test();

--/
create or replace python3 scalar script arcgis_geocode(cityid decimal(18,0), city varchar(64), region varchar(64), country_code varchar(64))
	emits (cityid decimal(18,0), x double, y double) as
import requests
import json

## debug
#import sys, socket
#class activate_remote_output:
#	def __init__(self, address):
#		self.s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
#		self.s.connect(address)
#		sys.stdout = sys.stderr = self
#	def write(self, data): return self.s.sendall(data)
#	def close(self): self.s.close()
## here should be the correct address of output client
#activate_remote_output(('192.168.158.1', 50000)) 
#it = 0
#print('Starting up vm_id ' + str(exa.meta.vm_id))
#def cleanup():
#	print('Shutting down vm_id ' + str(exa.meta.vm_id))

def run(ctx):
	r = requests.get(
		'https://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer/findAddressCandidates',
		params={
			'city': ctx['city'],
			'region': ctx['region'],
			'countryCode': ctx['country_code'],
			'maxLocations': 1,
			'f': 'pjson'
		}
	)

## debug
#	global it
#	it = it+1
#	print('vm_id ' + str(exa.meta.vm_id) + ' is processing url ' + r.url + ' in its ' + str(it) + '. iteration')

	candidates = r.json()['candidates']
	if len(candidates) > 0:
		loc = candidates[0]['location']
		ctx.emit(ctx.cityid, loc['x'], loc['y'])
	else:
		ctx.emit(ctx.cityid, None, None)
/

--/
create or replace python3 scalar script arcgis_reverse_geocode(cityid decimal(18,0), x double, y double) emits (cityid decimal(18,0), match_addr varchar(128), country_code varchar(8)) as
import requests
import json

## debug
#import sys, socket
#class activate_remote_output:
#	def __init__(self, address):
#		self.s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
#		self.s.connect(address)
#		sys.stdout = sys.stderr = self
#	def write(self, data): return self.s.sendall(data)
#	def close(self): self.s.close()
## here should be the correct address of output client
#activate_remote_output(('192.168.158.1', 50000)) 
#it = 0
#print('Starting up vm_id ' + str(exa.meta.vm_id))
#def cleanup():
#	print('Shutting down vm_id ' + str(exa.meta.vm_id))

def run(ctx):
	if ctx['x'] is not None:
		r = requests.get(
			'https://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer/reverseGeocode',
			params={
				'location':str(ctx['x'])+','+str(ctx['y']),
				'f': 'pjson'
			}
		)

# debug
#		global it
#		it = it+1
#		print('vm_id ' + str(exa.meta.vm_id) + ' is processing url ' + r.url + ' in its ' + str(it) + '. iteration')
		
		js = r.json()
		ad = js.get('address')
		if ad is not None:
			ctx.emit(ctx['cityid'], ad.get('Match_addr'), ad['CountryCode'])
		else:
			ctx.emit(ctx['cityid'], None, None)
	else:
		ctx.emit(ctx['cityid'], None, None)
/

select cityid, cityname, shortcity, cit.regionid, cit.countryid, reg.regionid, regionname, shortregion, reg.countryid, cou.countryid, countryname, shortcountry, cou.continentid, dialcode, con.continentid, continentname
	from loccities as cit, locregions as reg, loccountries as cou, loccontinents as con
	where cit.regionid = reg.regionid (+)
		and cit.countryid = cou.countryid
		and cou.continentid = con.continentid
;

alter table loccities add column x_y geometry(4326);
merge into loccities as dst
using (
	select arcgis_geocode(cityid, cityname, regionname, shortcountry)
		from loccities as cit, locregions as reg, loccountries as cou, loccontinents as con
		where cit.regionid = reg.regionid (+)
			and cit.countryid = cou.countryid
			and cou.continentid = con.continentid
) as src
on (src.cityid = dst.cityid)
when matched then update set dst.x_y = cast(case when x is not null then 'point('||x||' '||y||')' else null end as geometry(4326));

alter table loccities add column match_addr varchar(128);
alter table loccities add column country_code varchar(8);
merge into loccities as dst
using (
	select arcgis_reverse_geocode(cityid, st_x(x_y), st_y(x_y)) from loccities
) as src
on (src.cityid = dst.cityid)
when matched then update set dst.match_addr = src.match_addr, dst.country_code = src.country_code;

select * from loccities;

/*
with tmp1 as (
	select arcgis_geocode(cityid, cityname, regionname, shortcountry)
		from loccities as cit, locregions as reg, loccountries as cou, loccontinents as con
		where cit.regionid = reg.regionid (+)
			and cit.countryid = cou.countryid
			and cou.continentid = con.continentid
),
tmp2 as (
	select tmp1.*, cast(
			case when x is not null then 'point('||x||' '||y||')'
			else null end
		as geometry(4326)
	) as point from tmp1
),
tmp3 as (
	select tmp2.*, st_x(point) as st_x, st_y(point) as st_y from tmp2
) select arcgis_reverse_geocode(cityid, st_x, st_y) from tmp3;
*/