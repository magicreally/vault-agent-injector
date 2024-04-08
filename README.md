 ***Problem**
```note
 change default Vault encryption from base64 to aes-256
```
***What we did?**

 the primary objective was to enhance the security of authentication mechanisms within the application by transitioning from the use of Base64 encoding to more robust encryption methods such as AES-256 or another method of encryption. To achieve this, I used of the capabilities of the Transit engine provided by Vault, a highly secure and scalable secrets management solution. The Transit engine allows for encryption and decryption operations on data payloads, providing a seamless way to integrate advanced encryption techniques into the authentication process.

  As vault only use of base64 decoding and do not support of another encryption I used of transit engine to encrypt a plain text to a ciphertext and then store it in the vault as value of a key. If you are interested in to realize how it is work, you can check automat bash script and read the comment. As it so like the vault injector and transit engine documentation we avoid of repetitive text in here.

To ensure secure storage and management of sensitive information, the Key-Value version 2 (kv-v2) secrets engine is enabled at the designated path internal. This step allows for structured and flexible management of secrets within Vault's key-value store.
vault secrets enable -path=internal kv-v2
Furthermore, to harness the cryptographic capabilities within Vault, the transit engine is enabled. The transit engine offers functionalities such as encryption and decryption, essential for securing sensitive data during storage and transmission.
vault secrets enable transit
Next, the plaintext username and password are defined to facilitate authentication processes within the system. These credentials serve as the basis for user authentication and access control.
```console
PODUSERNAME="TESTUSER"
PODPAAS="PASSWORD123456"
```
A named encryption key, crucial for encrypting and decrypting sensitive information, is created within the transit engine. This encryption key forms the foundation for encrypting the plaintext password securely.
```bash
vault write -f transit/keys/my-key
```

Subsequently, the plaintext password is encrypted using the transit engine, and the resulting encrypted ciphertext is stored in a variable for further use. This encrypted password ensures the confidentiality and integrity of sensitive authentication information.
```bash

ENCRYPTED_PASSWORD=$(vault write -format=json transit/encrypt/my-key plaintext=$(echo -n "$PODPAAS" | base64) | awk '/ciphertext/{print $2}' | tr -d '"')
```

A secret containing the encrypted password, along with the associated username, is created at the specified path internal/database/config. This ensures that sensitive credentials are securely stored within Vault, safeguarding them against unauthorized access.
```bash
vault kv put internal/database/config username="$PODUSERNAME" password="$ENCRYPTED_PASSWORD"
```
Lastly, to confirm the successful creation of the secret containing the username and encrypted password, a verification step is performed. This ensures that the secret is correctly defined at the designated path within Vault.
```bash

vault kv get internal/database/config
```

Prerequisites
This tutorial requires:

[Docker](https://www.docker.com/products/docker-desktop/)

[Kubernetes command-line interface (CLI)](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

[Helm CLI](https://helm.sh/docs/intro/install/)

[Minikube](https://minikube.sigs.k8s.io/docs/start/)

  also we provide more details about [Transit Engine](doc/transit-engin.md), [Vault](doc/Vault.md) and [Kubernetes](doc/kubernets.md), you can read them by clicking on each one.

 
**Clone GitHub repositories**

Retrieve the all yaml file from my github repository
 ```bash
git clone https://github.com/magicreally/vault-agent-injector.git
```
Move into the clones repository.
```bash
 cd vault-agent-injector
 ```
 **1: Install the Vault Helm chart**

The most advisable method for deploying Vault on Kubernetes is through the use of the Helm chart. Helm serves as a package manager, facilitating the installation and configuration of all essential components for running Vault in various modes. A Helm chart comprises templates allowing for conditional and parameterized execution. These parameters can be configured either through command-line inputs or specified in YAML files.

**1.1** Add the HashiCorp Helm repository.
```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
```
**1.2**  Update all the repositories to ensure helm is aware of the latest versions
```bash
helm repo update
```
**1.3** install the latest version of the Vault server running in development mode.
```bash
helm install vault hashicorp/vault --set "server.dev.enabled=true"
```
**1.4** Display all the pods in the default namespace.
```bash
kubectl get pods
```
```console 
NAME                                    READY   STATUS    RESTARTS   AGE
vault-0                                 1/1     Running   0          80s
vault-agent-injector-5945fb98b5-tpglz   1/1     Running   0 
```
The vault-0 pod runs a Vault server in development mode. The vault-agent-injector pod performs the injection based on the annotations present or patched on a deployment.
 
 **2: Set a secret in Vault**

 **2.1** Start an interactive shell session on the vault-0 pod.
```bash
kubectl exec -it vault-0 -- /bin/sh
```
 **2.2** Enable kv-v2 secrets at the path internal.
```bash
vault secrets enable -path=internal kv-v2
```
 **2.3** Create a secret at path internal/database/config with a username and password.
```bash
vault kv put internal/database/config username="db-readonly-username" password="db-secret-password"
```
 **2.4** Verify that the secret is defined at the path internal/database/config.

```bash
vault kv get internal/database/config
```
**2.5** Lastly, exit the vault-0 pod.
```bash
exit
```
**3: Configure Kubernetes authentication**

**3.1** Start an interactive shell session on the vault-0 pod.
```bash
 kubectl exec -it vault-0 -- /bin/sh
 ```
**3.2** Enable the Kubernetes authentication method.
```bash
 vault auth enable kubernetes
 ```
 **3.3** Configure the Kubernetes authentication method to use the location of the Kubernetes API.

```bash
 vault write auth/kubernetes/config \
      kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443"
```      

**3.4** Write out the policy named internal-app that enables the read capability for secrets at path internal/data/database/config.
```bash
 vault policy write internal-app - <<EOF
path "internal/data/database/config" {
   capabilities = ["read"]
}
EOF
```
**3.5** Create a Kubernetes authentication role named internal-app.
```bash
vault write auth/kubernetes/role/internal-app \
      bound_service_account_names=internal-app \
      bound_service_account_namespaces=default \
      policies=internal-app \
      ttl=24h
```
**3.6** Lastly, exit the vault-0 pod.
```bash
exit
```
**4: Define a Kubernetes service account**

The Vault Kubernetes authentication role defined a Kubernetes service account named internal-app.

A service account provides an identity for processes that run in a Pod. With this identity we will be able to run the application within the cluster.
**4.1** Get all the service accounts in the default namespace.
```bash
kubectl get serviceaccounts
```
**4.2** Create a Kubernetes service account named internal-app in the default namespace.
```bash
kubectl create sa internal-app
```
**4.3** Verify that the service account has been created.

```bash
kubectl get serviceaccounts
```
**5: Launch an application**

You have created a sample application, published it to DockerHub, and created a Kubernetes deployment that launches this application.

**5.1** Display the deployment for the orgchart application.
```bash
cat deployment-orgchart.yaml
```
**5.2** Apply the deployment defined in deployment-orgchart.yaml.
```bash
kubectl apply --filename deployment-orgchart.yaml
```
**5.3** Get all the pods in the default namespace and note down the name of the pod with a name prefixed with "orgchart-".

```bash
kubectl get pods
```
**5.4** Verify that no secrets are written to the orgchart container in the orgchart pod.

```bash
kubectl exec \
      $(kubectl get pod -l app=orgchart -o jsonpath="{.items[0].metadata.name}") \
      --container orgchart -- ls /vault/secrets
```
The output displays that there is no such file or directory named /vault/secrets:
```console
ls: /vault/secrets: No such file or directory
command terminated with exit code 1
```

**6: Inject secrets into the pod**

The deployment is running the pod with the internal-app Kubernetes service account in the default namespace. The Vault Agent Injector only modifies a deployment if it contains a specific set of annotations. An existing deployment may have its definition patched to include the necessary annotations.
**6.1** Display the deployment patch patch-inject-secrets.yaml.
```bash
cat patch-inject-secrets.yaml
```
**6.2** Patch the orgchart deployment defined in patch-inject-secrets.yaml.
```bash
kubectl patch deployment orgchart --patch "$(cat patch-inject-secrets.yaml)"
```
A new orgchart pod starts alongside the existing pod. When it is ready the original terminates and removes itself from the list of active pods.
**6.3** Get all the pods in the default namespace.
```bash
kubectl get pods
```
Wait until the re-deployed orgchart pod reports that it is Running and ready (2/2).

This new pod now launches two containers. The application container, named orgchart, and the Vault Agent container, named vault-agent.
**6.4** Display the logs of the vault-agent container in the new orgchart pod.
```bash
kubectl logs \
      $(kubectl get pod -l app=orgchart -o jsonpath="{.items[0].metadata.name}") \
      --container vault-agent
```
**6.5** Display the secret written to the orgchart container.
```bash
kubectl exec \
      $(kubectl get pod -l app=orgchart -o jsonpath="{.items[0].metadata.name}") \
      --container orgchart -- cat /vault/secrets/database-config.txt
```


We provide the whole of these prompts in an automatic bash script and you can implement by one command.

for running bash script and inject secrets into pods 
```bash
./injector.sh
``````
