
**Transit secrets engine**

The transit secrets engine in Vault provides "cryptography as a service" for data in transit, handling encryption, decryption, signing, verification, and more. It encrypts data from applications, storing the encrypted data in a primary data store, and supports key derivation for versatile key usage. Convergent encryption ensures consistent ciphertext with the same input values. The engine also allows datakey generation, providing high-entropy keys encrypted with a named key, with the option to return the key in plaintext for immediate use or disable for auditing compliance.

**Working set management**

The Transit engine supports versioning of keys. Key versions that are earlier than a key's specified min_decryption_version gets archived, and the rest of the key versions belong to the working set. This is a performance consideration to keep key loading fast, as well as a security consideration: by disallowing decryption of old versions of keys, found ciphertext corresponding to obsolete (but sensitive) data can not be decrypted by most users, but in an emergency the min_decryption_version can be moved back to allow for legitimate decryption.

**Key types**

As of now, the transit secrets engine supports the following key types (all key types also generate separate HMAC keys):

`aes128-gcm96:` AES-GCM with a 128-bit AES key and a 96-bit nonce; supports encryption, decryption, key derivation, and convergent encryption
aes256-gcm96: AES-GCM with a 256-bit AES key and a 96-bit nonce; supports encryption, decryption, key derivation, and convergent encryption (default)
chacha20-poly1305: ChaCha20-Poly1305 with a 256-bit key; supports encryption, decryption, key derivation, and convergent encryption
ed25519: Ed25519; supports signing, signature verification, and key derivation
ecdsa-p256: ECDSA using curve P-256; supports signing and signature verification
ecdsa-p384: ECDSA using curve P-384; supports signing and signature verification
ecdsa-p521: ECDSA using curve P-521; supports signing and signature verification
rsa-2048: 2048-bit RSA key; supports encryption, decryption, signing, and signature verification
rsa-3072: 3072-bit RSA key; supports encryption, decryption, signing, and signature verification
rsa-4096: 4096-bit RSA key; supports encryption, decryption, signing, and signature verification
hmac: HMAC; supporting HMAC generation and verification.
managed_key: Managed key; supports a variety of operations depending on the backing key management solution. See Managed Keys for more information.
Note: In FIPS 140-2 mode, the following algorithms are not certified and thus should not be used: chacha20-poly1305 and ed25519.

Note: All key types support HMAC operations through the use of a second randomly generated key created key creation time or rotation. The HMAC key type only supports HMAC, and behaves identically to other algorithms with respect to the HMAC operations but supports key import. By default, the HMAC key type uses a 256-bit key.

RSA operations use one of the following methods:

OAEP (encrypt, decrypt), with SHA-256 hash function and MGF,
PSS (sign, verify), with configurable hash function also used for MGF, and
PKCS#1v1.5: (sign, verify), with configurable hash function.

**Convergent encryption**

Convergent encryption is a mode where the same set of plaintext+context always result in the same ciphertext.

**Prerequisites**

To perform the tasks described in this tutorial, you need to have the following:

**Vault** installed

Complete the **lab setup** section to use either a Vault dev mode server or HCP Vault cluster
jq installed

**Lab setup**

Open a terminal and start a Vault dev server with root as the root token.

```bash 
vault server -dev -dev-root-token-id root
```
The Vault dev server defaults to running at 127.0.0.1:8200. The server is also initialized and unsealed.

Insecure operation

Do not run a Vault dev server in production. This approach is only used here to simplify the unsealing process for this demonstration.

Export an environment variable for the vault CLI to address the Vault server.

```bash 
export VAULT_ADDR="http://127.0.0.1:8200"
```
Export an environment variable for the vault CLI to authenticate with the Vault server.

```bash 
export VAULT_TOKEN=root 
```

The Vault server is ready.

**Configure transit secrets engine**

**Setup**

Most secrets engines must be configured in advance before they can perform their functions. These steps are usually completed by an operator or configuration management tool.
Enable the Transit secrets engine:
```bash 
$ vault secrets enable transit
```
```console
Success! Enabled the transit secrets engine at: transit/
```
By default, the secrets engine will mount at the name of the engine. To enable the secrets engine at a different path, use the -path argument.
```bash
 vault secrets enable -path=encryption transit
```
Create an encryption key ring named orders by executing the following command.
```bash
 vault write -f transit/keys/orders
```
**Create a token for Vault clients**

Vault clients must authenticate with Vault and acquire a valid token with appropriate policies allowing to request data encryption and decryption using the specific key.
![alt text](https://developer.hashicorp.com/_next/image?url=https%3A%2F%2Fcontent.hashicorp.com%2Fapi%2Fassets%3Fproduct%3Dtutorials%26version%3Dmain%26asset%3Dpublic%252Fimg%252Fvault%252Fvault-transit-13.png%26width%3D2313%26height%3D429&w=3840&q=75)
When the transit secrets engine is enabled at transit, the policy must include the following:
```console
path "transit/encrypt/<key_name>" {
   capabilities = [ "update" ]
}

path "transit/decrypt/<key_name>" {
   capabilities = [ "update" ]
}
```
This tutorial uses the vault token create command to generate a client token and skips the authentication step.

Create a policy named app-orders.
```bash
 vault policy write app-orders -<<EOF
path "transit/encrypt/orders" {
   capabilities = [ "update" ]
}
path "transit/decrypt/orders" {
   capabilities = [ "update" ]
}
EOF
```
The policy is created or updated; if it already exists.

Example output:
```console
Success! Uploaded policy: app-orders 
```
Create a token with app-orders policy attached.
```bash
 vault token create -policy=app-orders
```
Example output:
```console
Key                  Value
---                  -----
token                hvs.CAESIIGSlbFFoYgqdzTu2lwnoDteRshqcWdVSAUohC2w-gZ2GicKImh2cy54cjRiQ1lMaHptSm44eVAySmFNWk9FNk4ueU54TmkQlQQ
token_accessor       lzzyhDwNzO3wO9ai734Bf14g.yNxNi
token_duration       1h
token_renewable      true
token_policies       ["app-orders" "default"]
identity_policies    []
policies             ["app-orders" "default"]
```
The token is returned with the app-orders policy attached.

Re-run the command and create a APP_ORDER_TOKEN environment variable to store the generated client token value.
```bash
 export APP_ORDER_TOKEN=$(vault token create \
    -policy=app-orders \
    -format=json | jq -r '.auth | .client_token')
```

Retrieve the transit wrapping key
```bash 
 vault read transit/wrapping_key
```
This returns a 4096-bit RSA key.

**Encrypt** some plaintext data using the /encrypt endpoint with a named key:
```bash
vault write transit/encrypt/my-key plaintext=$(echo "my secret data" | base64)
```
```console
Key           Value
---           -----
ciphertext    vault:v1:8SDd3WHDOjf7mq69CyCqYjBXAiQQAVZRkFM13ok481zoCmHnSeDX9vyf7w==
```
**Decrypt** a piece of data using the /decrypt endpoint with a named key:

```bash
vault write transit/decrypt/my-key ciphertext=vault:v1:8SDd3WHDOjf7mq69CyCqYjBXAiQQAVZRkFM13ok481zoCmHnSeDX9vyf7w==
```

```console
Key          Value
---          -----
plaintext    bXkgc2VjcmV0IGRhdGEK
```
The resulting data is base64-encoded (see the note above for details on why). Decode it to get the raw plaintext:
```bash
base64 --decode <<< "bXkgc2VjcmV0IGRhdGEK"
```
It is also possible to script this decryption using some clever shell scripting in one command:
```bash
vault write -field=plaintext transit/decrypt/my-key ciphertext=... | base64 --decode
```
**Rotate** the underlying encryption key. This will generate a new encryption key and add it to the keyring for the named key:
```bash
$ vault write -f transit/keys/my-key/rotate
```
configure automatic rotation for the orders key every 24 hours.
```bash
vault write transit/keys/my-key/config auto_rotate_period=24h
```
Upgrade already-encrypted data to a new key. Vault will decrypt the value using the appropriate key in the keyring and then encrypt the resulting plaintext with the newest key in the keyring.
```bash
 vault write transit/rewrap/my-key ciphertext=vault:v1:8SDd3WHDOjf7mq69CyCqYjBXAiQQAVZRkFM13ok481zoCmHnSeDX9vyf7w==
```
```console
Key           Value
---           -----
ciphertext    vault:v2:0VHTTBb2EyyNYHsa3XiXsvXOQSLKulH+NqS4eRZdtc2TwQCxqJ7PUipvqQ==

```
for add encryption and decryption to a pod you should apply below yaml

```bash
kubectl apply -f aes256-encryption.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: encrypted-pod
  labels:
    name: encrypted-pod
spec:
  containers:
  - name: encrypted-pod
    image: nginx
    #command: ["/bin/sh", "-c"]
    #args:
     #   - |
      #    your_key=$(openssl rand -hex 32)
       #   your_iv=$(openssl rand -hex 16)
       #   secret_data="my secret"
       #   encrypted_data=$(echo -n "$secret_data" | openssl enc -aes-256-cbc -K "$your_key" -iv "$your_iv" -base64)
       #   decrypted_data=$(echo "$encrypted_data" | base64 -d | openssl enc -d -aes-256-cbc -K "$your_key" -iv "$your_iv")
       #   echo $decrypted_data
    resources:
      limits:
        memory: "12Mi"
        cpu: "5m"
```

