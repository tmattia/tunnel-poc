require 'socket'

class TunnelClient
  def initialize(domain, remote_host, remote_port)
    @domain = domain

    puts "Connecting to tunnel server at #{remote_host}:#{remote_port}"
    @tunnel = TCPSocket.new(remote_host, remote_port)
  end

  def run
    puts "Registering with tunnel server to handle requests for #{@domain}"
    @tunnel.puts("REGISTER #{@domain}")

    # TODO: read, parse and process full HTTP request from tunnel
    loop do
      line = @tunnel.gets
      puts "Received: #{line}"

      puts "Responding with HTTP response"
      @tunnel.puts("HTTP/1.1 200")
      @tunnel.puts("Content-Type: text/html")
      @tunnel.puts
      @tunnel.puts("Hello world! The time is #{Time.now}")
      @tunnel.puts("DONE")
      puts "Done writing response"
    end

    @tunnel.close
  end
end


if __FILE__ == $0
  if ARGV.empty?
    domain = 'http://localhost/'
    remote_host = 'ec2-34-210-221-34.us-west-2.compute.amazonaws.com'
    remote_port = 8080
  elsif ARGV.size == 3
    domain = ARGV[0]
    remote_host = ARGV[1]
    remote_port = ARGV[2].to_i
  else
    puts 'Usage: tunnel_client.rb [domain] [remote_host] [remote_port]'
    exit 1
  end

  tunnel_client = TunnelClient.new(domain, remote_host, remote_port)
  tunnel_client.run
end
