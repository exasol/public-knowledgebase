# Setting up Exasol single sign-on with Active Directory Kerberos
## Prerequisites
* AD: installed and configured to authenticate users, domain is configured (which hosts users to be SSO in Exasol DB), admin access to AD
* Exasol DB 7.1: installed and configured, admin access to Exaoperation, dba access to DB
* Client machine: able authenticate with AD (get kerberos tgt for the client user), able to establish connection to Exasol DB, Exaplus installed (https://downloads.exasol.com/clients-and-drivers/exaplus)

## Configuring SSO for ExasolDB
###  1. Create Exasol service account in AD
Create a new user in AD domain to represent Exasol DB service.

This can be done by following commands in power shell:
```
$password = ConvertTo-SecureString "{Service account password}" -AsPlainText -Force
New-ADUser -Name "{Service account name}" -AccountPassword $password -Enabled $true
```
> **{Service account name}** \- arbitrary Exasol service user alias \
> **{Service account password}** \- password for Exasol service user

**Example**
```
$password = ConvertTo-SecureString "Password123!" -AsPlainText -Force
New-ADUser -Name "exauser_dev" -AccountPassword $password -Enabled $true
```


or in "Active Directory Users and Computers" UI:

![image](https://github.com/exasol/public-knowledgebase/assets/20660165/db244eca-d0fc-4a1c-80bb-5a8ae83ebba6)

***Noctice: service user can have an arbitrary name, it is just an alias for an Exasol ervice***

###  2. Anable supports AES 128/256 bit encryption for exaol service user
In "Active Directory Users and Computers" go to previously created Exasol user -> Properties -> Account -> Account options -> check "This account supports AES 128 bit encryption" and "This account supports AES 256 bit encryption" checkboxes.

![image](https://github.com/exasol/public-knowledgebase/assets/20660165/3d209665-3cce-42d7-999d-9e14e7b5749c)

###  3. Register SPN for exaol service user
In order to register SPN execute following command in power shell: 

```
setspn -S {Exasol service name}/{Exasol host name}.{AD domian} {Service account name}
```

> **{Exasol service name}** \- this parameter represents a **kerberos service name** of particular exasol instance. This is the first out of 2 parameters which will be used during user authentication. It is arbitrary now, but later on it will be critical to use the exasct value which is set up here.\
> **{Exasol host name}** \- this parameter represents a **kerberos host name** of particular exasol instance. This is the second out of 2 parameters which will be used during user authentication. It is arbitrary now, but later on it will be critical to use the exasct value which is set up here\
> **{AD domian}** \- Active Directory domain of the Exasol service user created during step 1\
> **{Service account name}** \- Exasol service user created during step 1

To check that SPN was registered correctly run the following command in power shell:
```
setspn -L {Service account name}
```

**Example**
```
setspn -S exasol/exacluster_dev.boxes.test exauser_dev
```
![image](https://github.com/exasol/public-knowledgebase/assets/20660165/0068e6da-822b-4a10-b259-588dc2ba2daf)

###  4. Generate keytab file for Exasol service
With help of the following ktpass command generate a keytab for Exasol service which will later be uploaded in Exaopertaion:

```
ktpass -out {Keytab path}\exasol_service.keytab -princ {Exasol service name}/{Exasol host name}.{AD domian}@{Kerberos realm} -mapuser {NETBIOS}\{Service account name} -mapop set -pass {Service account password} -ptype KRB5_NT_PRINCIPAL -crypto all
```
> **{Keytab path}** \- Arbitrary local directory where keytab file will be created. \
> **{Exasol service name}** \- Exasol **kerberos service name** which was set in step 3. \
> **{Exasol host name}** \- Exasol **kerberos host name** which was set in step 3. \
> **{AD domian}** \- Active Directory domain name of the Exasol service user created during step 1. \
> **{Kerberos realm}** \- In AD it is usually the domian name written in all capital letters. \
> **{NETBIOS}** \- Active Directory domain's Netbios (subdomain) name. Can be found in AD domain properties. \
> **{Service account name}** \- Exasol service user created during step 1. \
> **{Service account password}** \- Password of the Exasol service user created during step 1.

**Example**
```
ktpass -out C:\temp\exasol_service.keytab -princ exasol/exacluster_dev.boxes.test@BOXES.TEST -mapuser BOXES\exauser_dev -mapop set -pass Password123! -ptype KRB5_NT_PRINCIPAL -crypto all
```

###  5. Upload service keytab in Exaoperation
* Login to Exaoperation of the Exasol DB instance which you need to be accessible with AD SSO.
* Shutdow the database
![image](https://github.com/exasol/public-knowledgebase/assets/20660165/22bb6371-7c1d-49aa-99ad-48a71b2314af)
* Go to the database link and wait until the **State** became **Selected**
* In keytab section click **Choose file** and select the keytab file generated in step 4.
* Click **Upload keytab file** button.
![image](https://github.com/exasol/public-knowledgebase/assets/20660165/b6585dbf-ef95-4a80-a5c3-dcd0bba3b39e)
* Then click **Edit** button to go to Edit db page
* Specify the **Kerberos Realm** parameter using Kerberos realm from step 4 and click **Apply**
![image](https://github.com/exasol/public-knowledgebase/assets/20660165/a8a79d0d-4507-443c-b3f7-24b625e0d930)
* Startup the database and wiat unitl it goes online
![image](https://github.com/exasol/public-knowledgebase/assets/20660165/966fca88-1c6b-485d-bbc8-648d9247b197)


