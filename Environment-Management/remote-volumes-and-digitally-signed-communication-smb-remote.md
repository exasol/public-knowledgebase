# Remote Volumes and digitally signed communication (SMB remote archive volumes) 
## Background

This article describes how to improve the speed of your SMB share with disabling the policy **Microsoft network server: Digitally sign communications (always)**

## Symptoms

* creating backups takes unusual long
* performance of the remote archive volumes are poor (only a few MiB/s)
* remote share is a Microsoft Windows server
* no performance problems by using "smbclient" on other Linux clients

## Explanation

Open the "Local Group Policy Editor" on your Windows server and goto "Windows Settings > Security Settings > Local Policies > Security Option". To improve the speed of your share you have to disable the policy "Microsoft network server: Digitally sing communications (always)". After changing the policy you should be able to read and write with normal speed again.

![](images/snap27_1.png)

## Additional References

<https://docs.exasol.com/administration/on-premise/manage_storage/create_remote_archive_volume.htm>

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 