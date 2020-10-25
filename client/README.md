# Running `demoapiclient`

## Install

```
python setup.py develop
```

## Test (General routes)

#### No client certificate supplied

Run:

```
./test_communication.py ncc
```

Response:

```
Server replied with status_code: 400

headers:
{'Connection': 'close',
 'Content-Length': '246',
 'Content-Type': 'text/html'}

body:
<html>
<head><title>400 No required SSL certificate was sent</title></head>
<body bgcolor="white">
<center><h1>400 Bad Request</h1></center>
<center>No required SSL certificate was sent</center>
<hr><center>nginx</center>
</body>
</html>
```

#### Invalid client certificate supplied

Run:

```
./test_communication.py icc
```

Response:

```
Server replied with status_code: 400

headers:
{'Connection': 'close',
 'Content-Length': '224',
 'Content-Type': 'text/html'}

body:
<html>
<head><title>400 The SSL certificate error</title></head>
<body bgcolor="white">
<center><h1>400 Bad Request</h1></center>
<center>The SSL certificate error</center>
<hr><center>nginx</center>
</body>
</html>
```

#### Valid client certificate supplied

Run:

```
./test_communication.py vcc
```

Response:

```
Server replied with status_code: 200

headers:
{'Cache-Control': 'no-cache',
 'Connection': 'keep-alive',
 'Content-Length': '17',
 'Content-Type': 'application/json'}

body:
{"success":true}
```

## Test (Secure routes)

#### Ping hello route without client token

Run:

```
./test_communication.py psh
```

Response:

```
Server replied with status_code: 401

headers:
{'Connection': 'keep-alive',
 'Content-Length': '49',
 'Content-Type': 'application/json'}

body:
{"error":"Invalid client token","success":false}
```

#### Ping hello route with client token

Run:

```
./test_communication.py psh --token
```

Response:

```
Server replied with status_code: 200

headers:
{'Cache-Control': 'no-cache',
 'Connection': 'keep-alive',
 'Content-Length': '17',
 'Content-Type': 'application/json',
 'X-SERVER-CLIENT-TOKEN': 'this is a shared secret from server to client'}

body:
{"success":true}
```

#### Lookup code without client token

Run:

```
./test_communication.py lku
```

Response:

```
Server replied with status_code: 401

headers:
{'Connection': 'keep-alive',
 'Content-Length': '49',
 'Content-Type': 'application/json'}

body:
{"error":"Invalid client token","success":false}
```

#### Lookup code with client token ("unknown" code)

Run:

```
./test_communication.py lku --token "unknown"
```

Response:

```
Server replied with status_code: 404

headers:
{'Connection': 'keep-alive',
 'Content-Length': '63',
 'Content-Type': 'application/json'}

body:
{"data":null,"error":"Unknown code `unknown`","success":false}
```

#### Lookup code with client token ("known" code)

Run:

```
./test_communication.py lku --token "known"
```

Response:

```
Server replied with status_code: 200

headers:
{'Cache-Control': 'no-cache',
 'Connection': 'keep-alive',
 'Content-Length': '41',
 'Content-Type': 'application/json',
 'Date': 'Sun, 25 Oct 2020 14:18:39 GMT',
 'Server': 'nginx',
 'X-SERVER-CLIENT-TOKEN': 'this is a shared secret from server to client'}

body:
{"data":{"code":"known"},"success":true}
```
