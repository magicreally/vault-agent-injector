
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

