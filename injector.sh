#!/bin/bash
kubectl get pods
# Commands to run inside the pod
commands=$(cat <<'EOF'
# Enable kv-v2 secrets at the path internal.
vault secrets enable -path=internal kv-v2

# Enable the transit engine
vault secrets enable transit

# Define your plaintext username and password
PODUSERNAME="TESTUSER"
PODPAAS="PASSWORD123456"

# Create a named encryption key
vault write -f transit/keys/my-key

# Encrypt the password using the transit engine
ENCRYPTED_PASSWORD=$(vault write -format=json transit/encrypt/my-key plaintext=$(echo -n "$PODPAAS" | base64) | awk '/ciphertext/{print $2}' | tr -d '"')

# Create a secret at path internal/database/config with an encrypted password
vault kv put internal/database/config username="$PODUSERNAME" password="$ENCRYPTED_PASSWORD"

# Verify that the secret is defined at the path internal/database/config.
vault kv get internal/database/config
EOF
)

# Execute the commands inside the pod
echo "$commands" | kubectl exec -it vault-0 -- /bin/sh

sleep 5
#Configure Kubernetes authentication for Vault.
# Commands to run inside the pod
commands=$(cat <<'EOF'
#Enable the Kubernetes authentication method.
vault auth enable kubernetes

#Configure the Kubernetes authentication method to use the location of the Kubernetes API.
vault write auth/kubernetes/config \
      kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443"

#Write out the policy named internal-app that enables the read capability for secrets at path internal/data/database/config.
vault policy write internal-app - <<EOFPOL
path "internal/data/database/config" {
   capabilities = ["read"]
}
EOFPOL

#Create a Kubernetes authentication role named internal-app.
vault write auth/kubernetes/role/internal-app \
      bound_service_account_names=internal-app \
      bound_service_account_namespaces=default \
      policies=internal-app \
      ttl=240h

#exit the vault-0 pod.
exit
EOF
)

# Execute the commands inside the pod
echo "$commands" | kubectl exec -it vault-0 -- /bin/sh

sleep 5
 #Define a Kubernetes service account
 kubectl get serviceaccounts
sleep 3
 #Create a Kubernetes service account named internal-app in the default namespace.
 kubectl create sa internal-app
sleep 3

 #Verify that the service account has been created.
 kubectl get serviceaccounts
sleep 3

 #Launch an application
kubectl apply --filename deployment-orgchart.yaml
sleep 10

#Verify that no secrets are written to the orgchart container in the orgchart pod.
 kubectl exec \
      $(kubectl get pod -l app=orgchart -o jsonpath="{.items[0].metadata.name}") \
      --container orgchart -- ls /vault/secrets

#Inject secrets into the pod
#Patch the orgchart deployment defined in patch-inject-secrets.yaml.
kubectl patch deployment orgchart --patch "$(cat patch-inject-secrets.yaml)"
sleep 10

#Display the logs of the vault-agent container in the new orgchart pod.
kubectl logs \
      $(kubectl get pod -l app=orgchart -o jsonpath="{.items[0].metadata.name}") \
      --container vault-agent
#Display the secret written to the orgchart container.
kubectl exec \
      $(kubectl get pod -l app=orgchart -o jsonpath="{.items[0].metadata.name}") \
      --container orgchart -- cat /vault/secrets/database-config.txt
#Apply a template to the injected secrets
#Apply the updated annotations.
kubectl patch deployment orgchart --patch "$(cat patch-inject-secrets-as-template.yaml)"
#display the secret written to the orgchart container in the orgchart pod.
kubectl exec \
      $(kubectl get pod -l app=orgchart -o jsonpath="{.items[0].metadata.name}") \
      -c orgchart -- cat /vault/secrets/database-config.txt
#Pod with annotations
#apply the pod defined in pod-payroll.yaml.
kubectl apply --filename pod-payroll.yaml
sleep 10

#Display the secret written to the payroll container in the payroll pod.
kubectl exec \
      payroll \
      --container payroll -- cat /vault/secrets/database-config.txt
#Secrets are bound to the service account
#Apply the deployment and service account defined in deployment-website.yaml.
kubectl apply --filename deployment-website.yaml
sleep 10

#Display the logs of the vault-agent-init container in the website pod.
kubectl logs \
      $(kubectl get pod -l app=website -o jsonpath="{.items[0].metadata.name}") \
      --container vault-agent-init
#Patch the website deployment defined in patch-website.yaml.
kubectl patch deployment website --patch "$(cat patch-website.yaml)"
sleep 10

#display the secret written to the website container in the website pod.
kubectl exec \
      $(kubectl get pod -l app=website -o jsonpath="{.items[0].metadata.name}") \
      --container website -- cat /vault/secrets/database-config.txt
#Secrets are bound to the namespace
#Create the offsite namespace.
kubectl create namespace offsite
sleep 10

#Set the current context to the offsite namespace.
kubectl config set-context --current --namespace offsite
#Create a Kubernetes service account named internal-app in the offsite namespace.
kubectl create sa internal-app
sleep 10

#Apply the deployment defined in deployment-issues.yaml.
kubectl apply --filename deployment-issues.yaml
#Display the logs of the vault-agent-init container in the issues pod.
kubectl logs \
   $(kubectl get pod -l app=issues -o jsonpath="{.items[0].metadata.name}") \
   --container vault-agent-init
#Start an interactive shell session on the vault-0 pod in the default namespace.
commands=$(cat <<'EOF'
#Create a Kubernetes authentication role named offsite-app.
vault write auth/kubernetes/role/offsite-app \
   bound_service_account_names=internal-app \
   bound_service_account_namespaces=offsite \
   policies=internal-app \
   ttl=240h

#exit the vault-0 pod.
exit
EOF
)

# Execute the commands inside the pod
echo "$commands" | kubectl exec --namespace default -it vault-0 -- /bin/sh
#Patch the issues deployment defined in patch-issues.yaml.
kubectl patch deployment issues --patch "$(cat patch-issues.yaml)"
sleep 10

#Finally, display the secret written to the issues container in the issues pod.
kubectl exec \
   $(kubectl get pod -l app=issues -o jsonpath="{.items[0].metadata.name}") \
   --container issues -- cat /vault/secrets/database-config.txt




