# Import processes for use with Microsoft Azure Blob Storage™ 
## Background

### Parallel data exchange between EXASOL and Microsoft Azure Blob Storage

You have an Exasol database and want to read data from Microsoft Azure Blob Storage. Beginning with Version 7.0, Exasol supports IMPORT and EXPORT from Azure Blog Storage. You can find more information [here](https://docs.exasol.com/loading_data/load_data_azure_blob.htm) 

## Prerequisites

The theory of how to access files stored in Microsoft Azure Blob Storage via http/https is described here:  
<https://azure.microsoft.com/en-gb/documentation/articles/storage-dotnet-shared-access-signature-part-1/>  
In practice, you will face the following problems:

1. You want to import all files in a specific folder into a specific table. So you need to generate urls for all the files in that folder.
2. You want to use authentication, but you don't want to create the required url signature manually.

## How to read data from Microsoft Azure Blob Storage

## Step 1

The best way to read data is via the HTTP/HTTPS protocol using Exasol's native loading interface EXAloader with the IMPORT statement.

## Step 2

You can make use of Lua scripting to generate the IMPORT SQL commands. Additionally, we use the Python package azure-storage in user-defined functions (UDFs) to generate the URLs for the  IMPORT.

## Additional Notes

Follow the steps described in the comments of the file [azure_blob.sql](https://www.exasol.com/support/secure/attachment/78668/78668_azure_blob.sql "azure_blob.sql")

.

## Additional References

<https://azure.microsoft.com/en-gb/documentation/articles/storage-python-how-to-use-blob-storage/>

<https://docs.exasol.com/cloud_platforms/microsoft_azure.htm>

<https://docs.exasol.com/administration/azure.htm>

<https://docs.exasol.com/loading_data/load_data_azure_blob.htm>

