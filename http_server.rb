require 'socket'

class HTTPServer
  def initialize(port)
    @socket = TCPServer.new(port)
  end

  def run
    loop do
      session = @socket.accept

      Thread.new(session, &method(:handle_request))
    end
  end

  def handle_request(client)
    request = client.gets
    puts request

    client.puts("HTTP/1.1 200")
    client.puts("Content-Type: text/html")
    client.puts
    client.puts("Hello world! The time is #{Time.now}")

    client.close
  end
end

if __FILE__ == $0
  if ARGV.empty?
    port = 80
  elsif ARGV.size == 1
    port = ARGV[0].to_i
  else
    puts 'Usage: http_server.rb [port]'
    exit 1
  end

  puts "Starting HTTP server on port #{port}"
  http_server = HTTPServer.new(port)
  http_server.run
end
