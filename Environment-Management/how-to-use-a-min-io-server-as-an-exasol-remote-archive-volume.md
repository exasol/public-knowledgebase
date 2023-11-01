# How to use a min.io server as an Exasol remote archive volume 
## Background

min.io is an S3-compatible storage service (see <https://min.io>) that can be used as a backup destination (remote archive volume) for on-premise Exasol setups. Unfortunately, as of Exasol 6.2, there remains a minor incompatibility that requires patching the min.io server in order for Exasol to correctly recognize it. The steps below walk you through making your min.io service Exasol-compatible.

## Prerequisites

1. Have min.io installed in a location that Exasol has access to
2. Ability to reconfigure, recompile, and redeploy min.io
3. Ability to add DNS aliases
4. Have a min.io bucket and access/secret keys setup

## How to use min.io as an Exasol remote archive volume

1. Enable SSL in min.io and have it listen on port 443 (Exasol will ignore any other port specified)
2. Assuming that your min.io server is minio.yourdomain.comand it has a bucket named backups, create a DNS alias backups.minio.yourdomain.com which also resolves to the same IP as minio.yourdomain.com
3. In the min.io startup script set theMINIO_DOMAINENV variable tominio.yourdomain.com.  This will cause min.io to extract the bucket name from the virtual host passed to it instead of extracting it from the URL path (which is the default)
4. In the min.io startup script set the MINIO_REGION_NAMEENV variable tous-east-1 (or other region of your choice). This will cause min.io to include that in all HTTP response headers.
5. Check out the min.io source code from <https://github.com/minio/minio.git> and apply the patch below. See the repository's Dockerfile for how to rebuild it:  
```go
--- /cmd/api-headers.go
+++ /cmd/api-headers.go
@@ -51,7 +51,8 @@ func setCommonHeaders(w http.ResponseWriter) {
    // Set `x-amz-bucket-region` only if region is set on the server
    // by default minio uses an empty region.
    if region := globalServerRegion; region != "" {
-       w.Header().Set(xhttp.AmzBucketRegion, region)
+       h := strings.ToLower(xhttp.AmzBucketRegion)
+       w.Header()[h] = append(w.Header()[h], region)
    }
    w.Header().Set(xhttp.AcceptRanges, "bytes")
```
6. Redeploy your min.io server with the patch
7. In the Exasol ExaOperation interface for adding a remote archive volume
	* Set the Archive URL to [https://backups.minio.yourdomain.com](https://backups.minio.yourdomain.com/)
	* Specify the access and secret keys in the username/password fields
	* Specify an Option ofs3(and any other applicable options)

## Additional References

* <https://min.io>
* <https://github.com/minio>
* <https://docs.exasol.com/db/latest/administration/aws/manage_storage/create_remote_archive_volume.htm>

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 