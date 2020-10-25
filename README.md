# 2-way SSL (Reference implementation)

This is an implementation to demonstrate how 2-way SSL works. The following serves to depict the high-level architecture
and the components used in this project. 

<img src="https://github.com/oromico/2way-ssl-ref-implementation/blob/main/resources/2way-ssl-ref-implementation.png" />

- `demoapiclient` - A simple python program to make Restful call to `demoapiserver`. (for details, please refer [client README](https://github.com/oromico/2way-ssl-ref-implementation/blob/main/client/README.md))
- `demoapiserver` - A Flask application demonstrating 2-way SSL identity verification. (for details, please refer [server README](https://github.com/oromico/2way-ssl-ref-implementation/blob/main/server/README.md))

To run this project, you will need:

1. Docker
2. OpenSSL
3. `curl` command

(_Note: All commands listed in this README are only tested in an Ubuntu 18.04 environment._)

The following are the steps required to build and run this project:

1. [Generate Certificates](#generate-self-signed-ca-certificates)

2. [Build a docker image containing Ubuntu installed with Nginx and python Flask app](#build-the-docker-image)

3. [Running `demoapiserver`](#running-the-environment)

4. [Verifying your setup works](#verifying-the-setup)

---

## Building the environment

### Generate self-signed CA certificates

**Generate a RANDFILE**

This is for serving as seed data when generating the certificates in the steps below. Only required if you're
paranoid about security.

```
dd if=/dev/urandom of=~/.rnd bs=256 count=1
```

**Generating the Root CA**

```
openssl genrsa -out certs/ca.key 4096
openssl req -x509 -new -nodes -days 3650 -key certs/ca.key -out certs/ca.crt -subj "/C=SG/O=ReplaceMe/OU=Private Certificate Authority/CN=replaceme.com"
```

**Generating the Server certificate**

```
openssl genrsa -out certs/server.key 4096
openssl req -new -key certs/server.key -out certs/server.csr -config nginx/server_cert.conf
openssl x509 -req -days 3650 -in certs/server.csr -CA certs/ca.crt -CAkey certs/ca.key -CAcreateserial -out certs/server.crt -extensions v3_req -extfile nginx/server_cert_v3_ext.conf
```

To view the certificate:

```
openssl x509 -noout -text -in certs/server.crt
```

Note: In actual production, you will want the Server Certificate to be signed by a proper Certificate Authority (CA)
such as IdenTrust, DigiCert, Letsencrypt, etc. 

**Generating the Client certificate**

```
openssl genrsa -out certs/client.key 4096
openssl req -new -key certs/client.key -out certs/client.csr -config nginx/client_cert.conf
openssl x509 -req -days 3650 -in certs/client.csr -CA certs/ca.crt -CAkey certs/ca.key -CAcreateserial -out certs/client.crt -extensions v3_req -extfile nginx/client_cert_v3_ext.conf
```

To view the certificate:

```
openssl x509 -noout -text -in certs/client.crt
```

**Generating Client certificate with invalid CA**

This Client Certificate is used to demonstrate what will happen if the Client is untrusted.

```
openssl genrsa -out certs/ca_bad.key 4096
openssl req -x509 -new -nodes -days 3650 -key certs/ca_bad.key -out certs/ca_bad.crt -subj "/C=SG/O=Bad Actor/OU=Bad Certificate Authority/CN=evil.com"

openssl genrsa -out certs/client_bad.key 4096
openssl req -new -key certs/client_bad.key -out certs/client_bad.csr -config nginx/client_cert.conf
openssl x509 -req -days 3650 -in certs/client_bad.csr -CA certs/ca_bad.crt -CAkey certs/ca_bad.key -CAcreateserial -out certs/client_bad.crt -extensions v3_req -extfile nginx/client_cert_v3_ext.conf
```

To view the certificate:

```
openssl x509 -noout -text -in certs/client_bad.crt
```

### Build the Docker image

```
docker build --target ref2wayssl_base -t ref2wayssl_base .
docker build --target ref2wayssl -t ref2wayssl .
```

## Running the environment

```
docker run -p 80:80 -p 443:443 -it --rm ref2wayssl
```

## Verifying the setup

**No client certificate supplied**

Request:

```
curl https://dev.localhost/hello --cacert certs/ca.crt
```

Response:

```html
<html>
<head><title>400 No required SSL certificate was sent</title></head>
<body bgcolor="white">
<center><h1>400 Bad Request</h1></center>
<center>No required SSL certificate was sent</center>
<hr><center>nginx</center>
</body>
</html>
```

**Invalid client certificate supplied**

Request:

```
curl https://dev.localhost/hello --cacert certs/ca.crt --key certs/client_bad.key --cert certs/client_bad.crt
```

Response:

```html
<html>
<head><title>400 The SSL certificate error</title></head>
<body bgcolor="white">
<center><h1>400 Bad Request</h1></center>
<center>The SSL certificate error</center>
<hr><center>nginx</center>
</body>
</html>
```

**Valid client certificate supplied**

Request:

```
curl https://dev.localhost/hello --cacert certs/ca.crt --key certs/client.key --cert certs/client.crt
```

Response:

```json
{"success":true}
```
