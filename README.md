# NetHack Kubernetes 
This repo contains files required to run [dgamelaunch](https://github.com/paxed/dgamelaunch.git)'s in as a container for local or cloud kubernetes deployment.

> Note 1: This readme was generated with help from [claude](https://claude.ai/)
> Note 2: This has only been tested for the arm64 case

## Overview

This repository contains Kubernetes manifests and configurations for deploying a scalable NetHack gaming server infrastructure. The setup includes:

- **dgamelaunch** - Network game launcher for multiplayer NetHack
- **SSH Access** - Secure shell access for players
- **Persistent Storage** - Game saves, user data, and databases

### Prerequisites
Depending on your target architecture, you will need one or more of the following

- **Container Runtime**:
  - Podman (rootless alternative, see [PODMAN.md](PODMAN.md))
- **Kubernetes Cluster** (v1.20+)
  - Local: Docker Desktop, podman desktop, minikube, k0s, kind
  - Cloud: EKS, GKE, AKS
- **kubectl** configured for your cluster
- **Helm** (optional, for easier deployment)
- **skaffold**

### Local Developement

1. Clone

```bash
# Clone the repository with submodules
git clone --recursive https://github.com/psubacz/nethack-kuberentes.git
cd nethack-kuberentes

# OR if already cloned without submodules
git submodule update --init --recursive
```


2. Configure

In the `configs` directory, there are handful of configs that should be set prior to build. By defualt they are setup for development purposes only.

3. generate keys

```bash
ssh-keygen -t ed25519 -f nethack_sshkey -N ""
```

3. build

```bash
# Optional - Stop and remove the old container
podman stop nethack
podman rm nethack

# Build the dgamelaunch image
podman build -t nethack-k8s:latest .

podman run -d \
  --name nethack \
  -p 9000:22 \
  localhost/nethack-k8s:latest
```
  -v nethack-data:/opt/nethack \
  -v nethack-ssh:/home/nethack/.ssh \
  -v /dev/null:/opt/nethack/dev/null:ro \
  -v /dev/zero:/opt/nethack/dev/zero:ro \
4. Run

```bash
podman run -d \
  --name nethack \
  -p 9000:22 \
  localhost/nethack-k8s:latest
```

Quick explaination of the options for the uninitiated

* --name nethack-dgamelaunch: Gives the container a friendly name instead of a random generated one
* -d: Runs in "detached" mode (in the background, not attached to your terminal)
* -p 2222:22: Maps port 2222 on your host machine to port 22 inside the container
* -v nethack-data:/opt/nethack: Creates a named volume called "nethack-data" and mounts it to /opt/nethack inside the container
* -v nethack-ssh:/home/nethack/.ssh: Creates a named volume for SSH keys and configuration
* -v nethack-data:/opt/nethack: Bind mounts the host's /dev/null and /dev/zero into the container's chroot environment :ro: Mounts them read-only (security best practice)
* -v nethack-ssh:/home/nethack/.ssh: Bind mounts the host's /dev/null and /dev/zero into the container's chroot environment :ro: Mounts them read-only (security best practice)

5. Play

```bash
ssh -p 9000 nethack@localhost
```
