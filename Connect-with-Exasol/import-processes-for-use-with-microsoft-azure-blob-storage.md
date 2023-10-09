# Import processes for use with Microsoft Azure Blob Storage™ 
## Background

### Parallel data exchange between EXASOL and Microsoft Azure Blob Storage

You have an Exasol database and want to read data from Microsoft Azure Blob Storage. Beginning with Version 7.0, Exasol supports IMPORT and EXPORT from Azure Blog Storage. You can find more information [here](https://docs.exasol.com/loading_data/load_data_azure_blob.htm).

## Prerequisites

The theory of how to access files stored in Microsoft Azure Blob Storage via HTTP/HTTPS is described here:  
<https://azure.microsoft.com/en-gb/documentation/articles/storage-dotnet-shared-access-signature-part-1/>  
In practice, you will face the following problems:

1. You want to import all files in a specific folder into a specific table. So you need to generate urls for all the files in that folder.
2. You want to use authentication, but you don't want to create the required URL signature manually.

## How to read data from Microsoft Azure Blob Storage

## Step 1

The best way to read data is via the HTTP/HTTPS protocol using Exasol's native loading interface EXAloader with the IMPORT statement.

## Step 2

You can make use of Lua scripting to generate the IMPORT SQL commands. Additionally, we use the Python package azure-storage in user-defined functions (UDFs) to generate the URLs for the  IMPORT.

## Additional Notes

Follow the steps described in the comments of the file [azure_blob.sql](https://github.com/exasol/public-knowledgebase/blob/main/Connect-with-Exasol/attachments/azure_blob.sql "azure_blob.sql").

The script in file `azure_blob.sql` needs to be adapted for the newer version of `azure-storage` python module.
The following call (with dependencies) could be used as a starting point: https://github.com/Azure-Samples/AzureStorageSnippets/blob/master/blobs/howto/python/blob-devguide-py/blob-devguide-create-sas.py#L219

## Additional References

* <https://azure.microsoft.com/en-gb/documentation/articles/storage-python-how-to-use-blob-storage/>

* <https://github.com/Azure-Samples/AzureStorageSnippets/blob/master/blobs/howto/python/blob-devguide-py/blob-devguide-create-sas.py#L219>

* [Exasol on Microsoft Azure](https://docs.exasol.com/db/7.1/get_started/cloud_platforms/azure.htm)

* [Azure Administration](https://docs.exasol.com/db/7.1/administration/azure/administration.htm)

* [Load Data from Azure Blob Storage](https://docs.exasol.com/loading_data/load_data_azure_blob.htm)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 