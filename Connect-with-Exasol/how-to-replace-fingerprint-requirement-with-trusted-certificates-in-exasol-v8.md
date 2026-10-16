# How to Replace Fingerprint Requirement with Trusted Certificates in Exasol v8

## Question

Can we create a certificate to avoid having to add the "Fingerprint" in the URL when connecting to an Exasol v8 instance?  
If yes, what steps do we need to follow?

## Answer

Yes, you can configure your Exasol v8 instance and client environment to use a proper TLS certificate chain instead of relying on the certificate fingerprint in the connection URL.

The reason you need the fingerprint is likely because your Exasol instance is using a default self-signed certificate which is not trusted by your client's operating system or application's trust store.

Manually adding the certificate "Fingerprint" to your Exasol v8 connection URLs requires installing a server certificate on your Exasol instance that your clients (like Tableau or DBVisualizer) trust automatically.

There are two primary methods to achieve this, based on who issues and signs the certificate:

- **CA-Signed Certificate (Recommended):** Uses a certificate issued by a globally trusted Certificate Authority (CA).
- **Self-Signed Certificate (Internal Use):** Uses a certificate you generate and sign yourself, often by creating a private Root CA.

Here is a comparison of the approaches:

| **Feature** | **CA-Signed Certificate** | **Self-Signed Certificate** |
| --- | --- | --- |
| **Trust Source** | Root CA is pre-trusted globally. | **The specific certificate** must be manually trusted by the client. |
| **Security Level** | High (third party verified identity). | Medium (only proves **you** are the one who issued it). |
| **Client Configuration** | Usually **none** (automatic verification). | **Manual import** of the certificate into the client trust store. |

### Approach A: CA-Signed Certificate (Standard PKI)

This is the **industry-standard, most secure, and simplest approach for client configuration**.

#### Key Advantage

The client (e.g., Tableau's JRE) already trusts the Root CA, meaning you generally **do not need to modify the client's trust store**.

#### Required Steps

| **Step** | **Action** | **Description** |
| --- | --- | --- |
| **1\. Obtain Files** | Acquire the **Server Certificate**, **Private Key**, and the **CA Chain** (Intermediate and Root CAs). | The certificate's Common Name (CN) must match the hostname clients use to connect to Exasol. |
| **2\. Create Chain** | Combine the files into a single certificate chain file (e.g., cert_chain.pem). | This file must contain the Server Certificate first, followed by the Intermediate CA(s), and ending with the Root CA. |
| **3\. Upload to Exasol** | Use confd_client to upload the cert_chain.pem and the corresponding unencrypted private key (server_key.pem). | confd_client cert_update cert: '"{< /path/to/cert_chain.pem}"' key: '"{< /path/to/server_key.pem}"' |
| **4\. Restart DB** | Restart your Exasol database. | This activates the new certificate for client connections. |
| **5\. Connect** | Update your connection string to the standard format. | No fingerprint is required. The client automatically verifies the entire chain up to the globally trusted Root CA. |

### Approach B: Self-Signed Certificate (Custom Internal CA)

This approach is suitable if you cannot use a public CA but still want a robust method that avoids fingerprints. Your proposed plan falls under this approach.

#### Key Advantage

You have **full control** over the certificate issuance process and the associated cost is zero.

#### Required Steps

| **Step** | **Action** | **Description** |
| --- | --- | --- |
| **1\. Generate TLS Files** | Generate a **Root CA Certificate** (rootCA_cert.pem) and use its key to sign a **Server Certificate** (server_cert.pem). | This creates a private PKI. The CN of the server cert must match the Exasol hostname. |
| **2\. Create Chain** | Combine the Server Certificate and the Root CA Certificate into a chain (cert_chain.pem). | cat server_cert.pem rootCA_cert.pem > cert_chain.pem |
| **3\. Upload to Exasol** | Use confd_client to upload the cert_chain.pem and the **Server Private Key** (server_key.pem). | This replaces Exasol's default self-signed cert with your custom self-signed cert. |
| **4\. Restart DB** | Restart your Exasol database to activate the new certificate. | This is required for the new TLS files to take effect. |
| **5\. Import CA on Client (CRITICAL)** | Use the keytool utility to import your custom **Root CA Certificate** (rootCA_cert.pem) into the client's Java Trust Store (cacerts). | This manually instructs the client's JRE (e.g., Tableau's JRE) to trust any certificate signed by your custom CA. |
| **6\. Connect** | Update your connection string to the standard format. | The client now finds your Root CA in its trust store and accepts the server certificate. |

**Example keytool command for Step 5:**

```bash
keytool -import -alias exa_custom_root_ca -noprompt -storepass changeit -file "/path/to/rootCA_cert.pem" -keystore "&lt;Client_JRE&gt;/lib/security/cacerts"  
```

### Recommendation and Next Step

We highly recommend **Approach A (CA-Signed Certificate)**, as it maximizes security and minimizes ongoing configuration effort across different client machines.

If you proceed with **Approach B (Self-Signed)**, the most common hurdle is locating and correctly modifying the **cacerts** file for the specific client application (e.g., Tableau Desktop).

## References

Generating TLS files yourself to avoid providing a fingerprint
Upload TLS Certificate - On Premise | Exasol DB Documentation


* [Generating TLS files yourself to avoid providing a fingerprint](https://exasol.my.site.com/s/article/Generating-TLS-files-yourself-to-avoid-providing-a-fingerprint?language=en_US)
* [Upload TLS Certificate - On Premise | Exasol DB Documentation](https://docs.exasol.com/db/latest/administration/on-premise/access_management/tls_certificate.htm)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
