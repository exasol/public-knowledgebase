# Installing the Datadog Agent 
### Prerequisites

The datadog-agent has one dependency which is '/bin/sh'. It is safe to just install it, also in regards to future updates of Exasol.

### Installation

For CentOS 7.x just run on each machine (as user root):


```
DD_API_KEY=<Your-API-Key> bash -c "$(curl -L https://raw.githubusercontent.com/DataDog/datadog-agent/master/cmd/agent/install_script.sh)" 
```
### Changing hostnames

The hostname can be changed in '/etc/datadog-agent/datadog.yaml'. Afterwards, restart the agent as user root with 'systemctl restart datadog-agent'.

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 