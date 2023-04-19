# How to replace a network card 
## Background

There might be a need for you to replace the network interface cards (NIC), or you may need to upgrade the network interface cards of a database server or the management server.

## How to replace a network card

To replace a NIC in an Exasol cluster, you do not need to reinstall Exasol, but you have to change the Exasol Cluster configuration so the new network card is visible. You can follow these steps to replace the network card:

1. If you have a passive node, swap it with the server node. This way, the node on which you would like to change the network card is now the passive node and it can be powered off without affecting the database's availability.  
**NOTE:** If you do not have a passive node, then schedule a maintenance window to perform this task, as you will have to stop the database.
2. Connect to EXAoperation, stop the Database or the Databases, and shutdown the Storage services.
3. Next, go to **Nodes** in EXAoperation, select the server, and go to **Actions -> Shutdown**. Ensure the server is turned off before the next step.
4. Open the server and replace the network card.
5. Next, you need to change the node's MAC address to reflect the newly added network card. To do this, login to EXAoperation, under **Configuration -> Nodes**, select the desired node and click **Edit**.
6. Enter the MAC address and save the configuration.
7. Power on the server. Give it sometime before the server is ready and available once again.
8. Start the Storage services and the Database or Databases (in the case of no passive node).

## Additional References

* [Start/Stop Database](https://docs.exasol.com/administration/on-premise/manage_database/start_stop_db.htm)
* [Stop and Start Nodes](https://docs.exasol.com/administration/on-premise/nodes/stop_start_nodes.htm)
* [Node Management](https://docs.exasol.com/administration/on-premise/manage_nodes.htm)
