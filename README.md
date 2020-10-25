# 2-way SSL (Reference implementation)

# Building the environment

## Requirements:

- Docker
- OpenSSL

## Steps involved

1. [Generate Certificates]()

2. [Build a docker image containing Ubuntu installed with Nginx and python Flask app]()

3.

### Generate self-signed CA certificates:

##### generate a RANDFILE
This is for serving as seed data when generating the certificates in the steps below. Only required if you're paranoid about security.

```
dd if=/dev/urandom of=~/.rnd bs=256 count=1
```

##### Root CA
```
openssl genrsa -out certs/ca.key 4096
openssl req -x509 -new -nodes -days 3650 -key certs/ca.key -out certs/ca.crt -subj "/C=SG/O=ReplaceMe/OU=Private Certificate Authority/CN=replaceme.com"
```

##### Server certificate

```
openssl genrsa -out certs/server.key 4096
openssl req -new -key certs/server.key -out certs/server.csr -config nginx/server_cert.conf
openssl x509 -req -days 3650 -in certs/server.csr -CA certs/ca.crt -CAkey certs/ca.key -CAcreateserial -out certs/server.crt -extensions v3_req -extfile nginx/server_cert_v3_ext.conf
```

To view the certificate:

```
openssl x509 -noout -text -in certs/server.crt
```

##### Client certificate

```
openssl genrsa -out certs/client.key 4096
openssl req -new -key certs/client.key -out certs/client.csr -config nginx/client_cert.conf
openssl x509 -req -days 3650 -in certs/client.csr -CA certs/ca.crt -CAkey certs/ca.key -CAcreateserial -out certs/client.crt -extensions v3_req -extfile nginx/client_cert_v3_ext.conf
```

To view the certificate:

```
openssl x509 -noout -text -in certs/client.crt
```

##### Client certificate with invalid CA

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

### Build Docker

```
docker build --target ref2wayssl_base -t ref2wayssl_base .
docker build --target ref2wayssl -t ref2wayssl .
```

# Running the environment

```
docker run -p 80:80 -p 443:443 -it --rm ref2wayssl
```

# Verify

### No client certificate supplied
```
curl https://dev.localhost/hello --cacert certs/ca.crt
```

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

### Invalid client certificate supplied
```
curl https://dev.localhost/hello --cacert certs/ca.crt --key certs/client_bad.key --cert certs/client_bad.crt
```

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

### Valid client certificate supplied
```
curl https://dev.localhost/hello --cacert certs/ca.crt --key certs/client.key --cert certs/client.crt
```

```json
{"success":true}
```
