# Upload an Exasol Support Archive from the Command Line

## Disclaimer

This script is provided **as-is** for convenience. It is not part of the Exasol product and is **not actively maintained** by Exasol Support. Although it is expected to continue working, future updates or compatibility fixes are not guaranteed.

## Overview

In some environments, customers must transfer a Support Archive through multiple systems before it can be uploaded to the Exasol Log Upload service. This process can be time-consuming and inconvenient.

The following script allows you to upload a Support Archive directly from the command line on an Exasol data node.

## Prerequisites

Before running the script, ensure the following utilities are installed:

- `curl`
- `jq`
- `grep`
- `mktemp`

## Create the Upload Script

Create the following script on an Exasol data node (for example, `upload_exasol_logs.sh`):

```bash
#!/bin/bash
for cmd in jq curl grep mktemp; do
    command -v "$cmd" >/dev/null 2>&1 || {
        echo "$cmd required" >&2
        exit 1
    }
done
usage() {
    echo "Usage: $0 <seafile_url> <file_path>" >&2
    echo "Example: $0 https://seafile.example.com/f/abc123 /path/to/file.txt" >&2
    exit 1
}
url="$1"
file="$2"
[ -n "$url" ] && [ -n "$file" ] || usage
case "$url" in
*/) ;;
*) url="$url/" ;;
esac
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
parent_dir="$(curl -sL "$url" | grep dirName | awk '{print $2}' | sed 's/^\(.*\),$/\1/g' | jq -r)"
host="${url#*//}"
host="${host%%/*}"
id="${url%/}"
id="${id##*/}"
upload_link=$(curl -sL "${url%%//*}//$host/api/v2.1/upload-links/$id/upload/" | jq -r '.upload_link')
curl --header 'accept: application/json' \
    --progress-bar \
    -F "file=@$file" \
    -F "parent_dir=/$parent_dir" \
    "$upload_link?ret-json=1" \
    -o "$tmp"
jq < "$tmp"
```

Make the script executable:

```bash
chmod +x upload_exasol_logs.sh
```

## Upload a Support Archive

Run the script by providing the upload URL received from Exasol Support and the path to the Support Archive.

```bash
./upload_exasol_logs.sh \
  https://logupload.exasol.com/u/d/64ded56......fbb819/ \
  /exa/tmp/support/exacluster_debuginfo_2026_07_08-16_08_41.tar.gz
```

If the upload is successful, the script prints the JSON response returned by the upload service.

## Additional References

None.

---

*We appreciate your contributions! Help improve the Exasol Knowledge Base by submitting updates on [GitHub](https://github.com/exasol/public-knowledgebase).*
