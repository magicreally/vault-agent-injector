**Injecting Secrets into Kubernetes Pods via Vault Helm Sidecar**
Using Vault for secret management in applications involves:

Logging in and getting a token.
Handling the token's lifecycle.
Getting secrets from Vault.
Managing the duration of dynamic secrets.
Vault Agent simplifies these tasks, ensuring applications don't need to know about Vault. But you must install and configure Vault Agent alongside applications as a sidecar.

The Vault Helm chart helps run Vault and the Vault Agent Sidecar Injector. This injector, using the Sidecar container pattern and Kubernetes mutating admission webhook, adds a Vault Agent container to pods with specific notes to manage secrets.

Benefits include:

Applications don't need to know about Vault; secrets are stored in the container's files.
No changes are needed for existing deployments; notes can be updated.
Access to secrets can be controlled through Kubernetes service accounts and namespaces.
In this tutorial, you'll set up Vault and the injector service using the Vault Helm chart. Then, you'll deploy multiple applications to show how the injector service gets and handles secrets for them.

Prerequisites
This tutorial requires:

[Docker](https://www.docker.com/products/docker-desktop/)

[Kubernetes command-line interface (CLI)](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

[Helm CLI](https://helm.sh/docs/intro/install/)

[Minikube](https://minikube.sigs.k8s.io/docs/start/)

**Clone GitHub repositories**
Retrieve the all yaml file from my github repository
 ```bash
git clone https://github.com/magicreally/vault-agent-injector.git
```
Move into the clones repository.
```bash
 cd vault-agent-injector
 ```
**Start Minikube**
Minikube is a CLI tool that provisions and manages the lifecycle of single-node Kubernetes clusters locally inside Virtual Machines (VM) on your system.

Start a Kubernetes cluster.
```bash
minikube start
```
```console
😄  minikube v1.30.1 on Darwin 13.3.1 (arm64)
✨  Using the docker driver based on existing profile
👍  Starting control plane node minikube in cluster minikube
🚜  Pulling base image ...
🔄  Restarting existing docker container for "minikube" ...
🐳  Preparing Kubernetes v1.26.3 on Docker 23.0.2 ...
🔗  Configuring bridge CNI (Container Networking Interface) ...
🔎  Verifying Kubernetes components...
   ▪ Using image gcr.io/k8s-minikube/storage-provisioner:v5
🌟  Enabled addons: storage-provisioner, default-storageclass
🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
```
**Install the Vault Helm chart**
The most advisable method for deploying Vault on Kubernetes is through the use of the Helm chart. Helm serves as a package manager, facilitating the installation and configuration of all essential components for running Vault in various modes. A Helm chart comprises templates allowing for conditional and parameterized execution. These parameters can be configured either through command-line inputs or specified in YAML files.

- Add the HashiCorp Helm repository.
```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
```
- Update all the repositories to ensure helm is aware of the latest versions
```bash
helm repo update
```
- install the latest version of the Vault server running in development mode.
```bash
helm install vault hashicorp/vault --set "server.dev.enabled=true"
```
- Display all the pods in the default namespace.
```bash
kubectl get pods
```
```console 
NAME                                    READY   STATUS    RESTARTS   AGE
vault-0                                 1/1     Running   0          80s
vault-agent-injector-5945fb98b5-tpglz   1/1     Running   0 
```
The vault-0 pod runs a Vault server in development mode. The vault-agent-injector pod performs the injection based on the annotations present or patched on a deployment.

for running bash script and inject secrets into pods 
```bash
./injector.sh
``````
