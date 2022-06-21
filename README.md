# Installation

$ bundle install

# Running

## Proxy

$ ruby proxy.rb 8088

## HTTPServer

$ ruby http_server.rb

## Making requests

### To HTTPServer Directly

$ curl localhost

### Using Proxy

$ curl localhost --proxy localhost:8088

# Deployment

## Copy files
$ scp -i "proxy-poc.pem" proxy.rb ubuntu@ec2-34-210-221-34.us-west-2.compute.amazonaws.com:/home/ubuntu/proxy/

## Start proxy

ssh -i "proxy-poc.pem" ubuntu@ec2-34-210-221-34.us-west-2.compute.amazonaws.com "ruby /home/ubuntu/proxy.rb 8080"

## Stop proxy

ssh -i "proxy-poc.pem" ubuntu@ec2-34-210-221-34.us-west-2.compute.amazonaws.com "killall ruby"
