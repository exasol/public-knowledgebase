# Add a new license server 
## Background

This is a test example done on VirtualBox, please change your hardware settings as required to perform this operation.

This will show the basics only not the full configuration process, we'll keep the documentation updated.

## Prerequisites

You need a working Exasol Cluster with a working license server.

## How to Add an additional license server

## Step 1

Boot the server with the EXAsuite's ISO, (use the same version that you have already have installed, if you are planning to update the cluster then install the new version that you want). Remember to download the ISO from [Exasol Download Section - Downloads - EXASOL User Portal](https://www.exasol.com/portal/display/DOWNLOAD/Exasol+Download+Section)

## Step 2

Type install and press ENTER to continue.

![](images/2.png)

## Step 3

Select Encrypt device, that's the recommended option otherwise skip it and then select OK to continue.

![](images/3.png)

## Step 4

Select the License server number from 2 to 10 (so you can have up to 9 license servers), that's the last IP octet (you should select a different number than the actual license server), also make sure that the private IP subnet is in the same one as of the actual working license server. When done select OK to continue.

![](images/4.png)

## Step 5

Select Install as additional license server and then select OK to continue.

![](images/5.png)

## Step 6

Enter the current cluster root password twice. This is Exasol privileged password and it depends on the version that you are installing. Only Exasol team has access to this password. When done select OK to continue.

![](images/6.png)

## Step 7

Enter the new desired license node UUID or you can just click on create a new UUID and it'll generate a random UUID for you.

![](images/7.png)

## Step 8

Select the public IP subnet and netmask (should match the same network as the working license server but of course a different IP, the last octet should be different) when done select OK to continue.

![](images/8.png)

## Step 9

On the Advanced network configuration window perform any changes if required, otherwise select OK to continue.

![](images/9.png)

## Step 10

You should see this screen only if you selected to encrypt your device on step (3) in this situation choose a password and enter it twice (maybe the same one as the previous license server if it's going to be replaced, otherwise choose a new one and store it on password safe). When done select OK to continue.

![](images/10.png)

## Step 11

The installation will start, wait until it's finished (it can take from 15min to 45min depending on your computing power).

![](images/11.png)

## Step 12

After the installation is complete the server will be restarted automatically. If you still have the CD/DVD/ISO configured on your server/VM then just press ENTER to boot from the hard disk and you can remove it safely, the system will boot up.

![](images/12.png)

## Step 13

You should see this screen only if you selected to encrypt your device on step (3). You'll have to enter the HDD encryption password you chose before on step (10).

![](images/13.png)

## Step 14

The system will be ready after a couple of minutes and you'll be able to login as root/maintenance if required. The license webserver should be still starting please wait a couple of minutes and then log in into the public IP address that you have selected for it on the https protocol.

![](images/14.png)

## Step 15

Wait for a couple of minutes until the new license server is up and then login into the new IP of the new license server using the https protocol. The username/password combinations for the users maintenance/root/admin/etc will be the same as for the original license server.

![](images/15.png)

## Step 16

You can now go to Nodes link on the left tab and you'll see the two license servers available.

![](images/16.png)

## Step 17

If you want to change the IP of any of the license nodes you can do it.

For that log in as the maintenance user on the license server where you want to update the IP select "Configure network" and press ENTER.

![](images/17.png)

## Step 18

Change the last octet to a value from 2 to 10 different from the other license server's IP, in this situation I've selected 8, and then select OK and press ENTER to continue.

![](images/18.png)

## Step 19

The IP change will not be reflected until you restart EXAClusterOS, for that select the option "Stop EXAClusterOS" and press ENTER, then OK and press ENTER again to continue.

![](images/19.png)

## Step 20

Now you'll see the ExaClusterOS status as "Not running" and "Offline" select the option "Start EXAClusterOS" and press ENTER, then select OK and press ENTER again to continue.

![](images/21.png)

## Step 21

Click on refresh until you can see that the EXAClusterOS status is "Running" and "Online".

![](images/23.png)

## Step 22

You should be ready to connect to the new IP, also on the nodes section for the license servers the IP change will be reflected.

*Important: the node number will stay on n09, it will not change to n08.

![](images/24.png)

## Step 23

Finally update the node priorities, for that go to EXAOperation on the left under Services, then click on "Node Priorities", click on the new node you've added, in this case is node n0009 (but it could be another from from 0002 to 0008 remember) and click on Raise Priority until it's located in the top, to the same with n00010 (the original and first) license node and put it under the new node you've added.

![](images/25.png)

In this situation it'll look like this, click on Apply to save the changes.

![](images/26.png)

## Additional Notes

Follow the next steps only if you want to remove one of the license servers.

## Step 1

Shutdown the databases: for that on the Services tab in the left select EXASolution, select all the databases, click on Shutdown and then on OK to continue.

![](images/27.png)

![](images/28.png)

## Step 2

Stop the Storage service:  for that on the Services tab in the left select EXAStorage and then click on "Shutdown Storage Service" and OK to continue.

![](images/29.png)

![](images/30.png)

## Step 3

Stop the Cluster Services: for that on the Configuration tab in the left select "Nodes" select all the nodes on the combo box select "Stop cluster services" and then click on "Execute" and OK to continue.

![](images/31.png)![](images/32.png)

## Step 4

Move EXAOperations to the License node that we want to keep.

Since we'll remove the first and original license server n0010 we'll first move EXAOperation to the other available license node, the new node you've added, for this example it's n0009 and we click on "Move to specified Node" this will take possible a couple of minutes depending on your computing power.

![](images/33.png)

If you did this task from the node that had EXAOperation running you'll get a browser error that there was a connection failure. Please wait a little and try to connect to the other license node on the https port.

## Step 5

Shutdown the license server that you want to remove, for example we'll remove the old license server that we had n0010. You can do it logged in into any of both license servers.

For that go to the Nodes section on the left and click Shutdown on Node: n0010 and then click on OK to continue.

![](images/34.png)

You could get a message like this:

![](images/35.png)

## Step 6

Click on nodes again and you'll see that the Node n0010 is Shutdown.

![](images/36.png)

## Step 7

Now it'll stay like that, and there won't be any issue but if you want to remove Node n0010 from the License Nodes list you need to reboot the license node n0009 for that click on Reboot and then on OK to continue.

![](images/37.png)

*If you have an encryption password please go to the server's console and enter the password so the server can boot.

## Step 8

After rebooting the old license node will be gone.

![](images/38.png)

## Step 9

Now you can follow the normal startup procedure for your cluster:

Select all nodes and from the Actions combo box select "Start cluster services" and then click on "Execute".

![](images/38.png)

You should see all nodes in Running / Active state:

![](images/40.png)

On the Services tab click on EXAStorage and then on "Startup Storage Service" then click on OK and wait.

![](images/41.png)

All your storage volumes should be on ONLINE state.

![](images/42.png)

Now of the left tab on Services select EXASolution and select all your databases and click on Start, wait until the page is refreshed automatically, remember that you can follow all this steps in the Monitoring tab on the left selecting the logservice configured and then the Tail tab.

![](images/43.png)

After some time all your databases will be up and running.

![](images/44.png)

## Additional References

[Install Exasol on a Hardware - On Premise | Exasol Documentation](https://docs.exasol.com/administration/on-premise/installation/install_exasol_hw.htm)

