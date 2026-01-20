
# 03 - Security & SSL (Local HTTPS)

This guide documents the implementation of full HTTPS encryption for the local `.lab` domain. Since these domains are private and cannot be validated by public authorities (like Let's Encrypt), we act as our own Certificate Authority (CA).

## 1. The Concept (PKI)
To achieve the "Green Lock" locally, we establish a simplified Public Key Infrastructure (PKI):
1.  **Root CA:** We create a "Master Authority" and tell our devices to trust it.
2.  **Leaf Certificate:** We use the Root CA to sign a wildcard certificate (`*.lab`).
3.  **Termination:** Nginx presents this certificate to clients.



## 2. Generating the Certificates
All commands are run on the Ubuntu Server using `openssl`.

### 2.1 Create the Root CA
First, we create the private key and the public root certificate.

```bash
mkdir -p ~/certs && cd ~/certs

# 1. Generate Root Key (Keep this safe!)
openssl genrsa -des3 -out rootCA.key 2048
# Input a passphrase when prompted.

# 2. Generate Root Certificate (Valid for 10 years)
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 3650 -out rootCA.pem

```

* **Prompt inputs:**
* Country/State: Optional.
* Common Name (CN): **"Omar Lab Root CA"** (This is what appears in the browser).



### 2.2 Create the Wildcard Certificate

Now we mint a certificate valid for `*.lab`.

```bash
# 1. Generate the Private Key
openssl genrsa -out star_lab.key 2048

# 2. Create the Certificate Signing Request (CSR)
openssl req -new -key star_lab.key -out star_lab.csr
# Common Name (CN): *.lab

```

### 2.3 The Extension File (Vital for Chrome/Edge)

Modern browsers require "Subject Alt Names" (SANs). We create a config file to define these.

Create `v3.ext`:

```ini
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = *.lab
DNS.2 = lab

```

### 2.4 Sign the Certificate

Use the Root CA to sign the CSR, applying the extensions.

```bash
openssl x509 -req -in star_lab.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out star_lab.crt -days 3650 -sha256 -extfile v3.ext

```

* **Output:** You now have `star_lab.crt` (Public Cert) and `star_lab.key` (Private Key).

## 3. Nginx Configuration

We import these files into Nginx Proxy Manager to handle SSL termination.

1. **Import:**
* Go to **SSL Certificates** -> **Add Custom Certificate**.
* **Name:** `Wildcard Lab`.
* **Key:** Upload `star_lab.key`.
* **Certificate:** Upload `star_lab.crt`.


2. **Apply:**
* Edit a Proxy Host (e.g., `uptime.lab`).
* **SSL Tab:** Select "Wildcard Lab".
* **Settings:** Enable `Force SSL` and `HTTP/2 Support`.



## 4. Client Trust (Windows)

For the browser to trust the certificate, the **Root CA** must be installed in the client's Trusted Store.

1. **Transfer:** Copy `rootCA.pem` from the server to the Windows machine.
2. **Rename:** Change extension to `.crt` (e.g., `rootCA.crt`).
3. **Install:**
* Double-click the file -> **Install Certificate**.
* Store Location: **Local Machine**.
* Certificate Store: **Trusted Root Certification Authorities**.


4. **Verify:** Restart the browser and visit `https://uptime.lab`. The connection should be secure.

