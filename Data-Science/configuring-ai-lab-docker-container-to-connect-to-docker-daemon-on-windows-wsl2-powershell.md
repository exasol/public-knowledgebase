# Configuring AI-Lab Docker Container to Connect to Docker Daemon on Windows (WSL2 & PowerShell)

## Question

How do I install and run the AI-Lab Docker image using Windows PowerShell, including how to enable access to the Docker daemon?

## Answer

### Prerequisites

* Windows 10/11 with Docker Desktop installed.
* Docker Desktop must use WSL 2 (Windows Subsystem for Linux 2) to support mounting the Docker socket (docker.sock) and directories from Windows.

### ⚠ Important Limitations and Considerations ⚠

* **Security:** Mounting the Docker socket can be dangerous; restrict usage to trusted environments only.
* **File Access:** Only files/directories present on your Windows system (visible to Docker/WSL2) can be mounted.
* **Compatibility:** Mounting docker.sock is only possible with Docker Desktop + WSL2.

### Steps

#### 1 - Configure Your Variables

Open Windows PowerShell and set the following environment variables for convenience (you can change the values as needed):

```bash
$VERSION = "3.1.0"             # Set your desired AI Lab version
$LISTEN_IP = "0.0.0.0"         # IP address to bind; keep this for most cases
$VOLUME = "my-vol"             # Name of the Docker volume to attach
$CONTAINER_NAME = "ai-lab"     # Container name
```

#### 2 - Enable AI-Lab Container Access to the Docker Daemon

Run the Docker container:

```bash
docker run `
  --name "$CONTAINER_NAME" `
  --volume "${VOLUME}:/home/jupyter/notebooks" `
  --volume "//var/run/docker.sock:/var/run/docker.sock" `
  --publish "${LISTEN_IP}:49494:49494" `
  "exasol/ai-lab:${VERSION}"
```
##### Parameters

* **--name "$CONTAINER_NAME":** Sets the container name (replace with your preferred name or environment variable).
* **--volume "${VOLUME}:/home/jupyter/notebooks":** Mounts a host path (VOLUME) to the container.
* **--volume "//var/run/docker.sock:/var/run/docker.sock":** Allows Docker-in-Docker or enables the container to communicate with the Docker daemon.
* **--publish "${LISTEN_IP}:49494:49494":** Maps host port 49494 to container port 49494, bound to LISTEN_IP.
"exasol/ai-lab:${VERSION}": Specifies the image with a tag (VERSION).

##### Note

The backtick (`) at the end of each line allows you to split the command across multiple lines in PowerShell for better readability.

##### ⚠ Security Note ⚠

Exposing the Docker socket (/var/run/docker.sock) inside the container poses significant security risks. Only enable this if you fully understand the implications.

#### Accessing Jupyter Notebooks

Once the container is running, open your web browser and navigate to:
http://localhost:49494

## References

* [AI-Lab with Integrated Exasol Docker-DB](https://github.com/exasol/ai-lab/blob/3.1.0/doc/user_guide/docker/docker-usage.md#ai-lab-with-integrated-exasol-docker-db)
* [Accelerate Your AI Journey with Exasol](https://www.exasol.com/use-cases/exasol-ai/)


*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
