# Overview

Proof-of-concept code to expose a local HTTP server over the cloud using
Ruby's stdlib socket libraries.

I started by building a basic understanding of the HTTP protocol with:

- `http_server.rb`: simple HTTP server that responds to basic GET
  requests with the local time.
- `proxy.rb`: simple HTTP proxy that forwards requests to another host.

Next up, I built a tunnel client and server inspired by ngrok to expose
a local HTTP server over the cloud without needing port forwarding:

- `tunnel_server.rb`: exposes two external sockets: control and data.
  Control is used by remote servers to self-register with the tunnel.
  Data is used by regular HTTP clients to transparently call the remote
  servers over the cloud.
- `tunnel_client.rb`: self-registers with the tunnel server to handle
  reqeusts for a given domain.

An indirect goal is to have a bare-minimum setup with regards to
libraries, deployment, hosting, etc. I opted to host things in a plain
EC2 box and deploy using a simple bash script that runs commands over
SSH.

# Installation

```
$ bundle install
```

# Running locally

## Proxy

```
$ ruby proxy.rb 8088
```

## HTTPServer

```
$ ruby http_server.rb
```

## Tunnel Server

```
$ ruby tunnel_server.rb
```

## Tunnel Client

```
$ ruby tunnel_client.rb 'http://localhost/' localhost 8080
```

## Making requests

### To HTTPServer Directly

```
$ curl localhost
```

### Using Proxy

```
$ curl localhost --proxy localhost:8088
```

### Using Tunnel over the cloud

```
$ curl localhost --proxy ec2-34-210-221-34.us-west-2.compute.amazonaws.com:8080
```

# Deployment

```
./deploy.sh
```
