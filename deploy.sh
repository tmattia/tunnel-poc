scp -i "proxy-poc.pem" proxy.rb ubuntu@ec2-34-210-221-34.us-west-2.compute.amazonaws.com:/home/ubuntu/proxy/
scp -i "proxy-poc.pem" tunnel_server.rb ubuntu@ec2-34-210-221-34.us-west-2.compute.amazonaws.com:/home/ubuntu/proxy/
ssh -i "proxy-poc.pem" ubuntu@ec2-34-210-221-34.us-west-2.compute.amazonaws.com "killall ruby"
# ssh -i "proxy-poc.pem" ubuntu@ec2-34-210-221-34.us-west-2.compute.amazonaws.com "ruby /home/ubuntu/proxy/proxy.rb 8080 &"
ssh -i "proxy-poc.pem" ubuntu@ec2-34-210-221-34.us-west-2.compute.amazonaws.com "ruby /home/ubuntu/proxy/tunnel_server.rb 8088 8080 &"
