require 'socket'
require 'uri'
require 'openssl'

class Proxy
  def initialize(port)
    @socket = TCPServer.new(port)
  end

  def run
    loop do
      session = @socket.accept

      Thread.new(session, &method(:handle_request))
    end
  ensure
    @socket.close if @socket
  end

  def handle_request(client)
    request_line = client.readline
    puts request_line

    # Parse first request line
    verb    = request_line[/^\w+/]
    url     = request_line[/^\w+\s+(\S+)/, 1]
    version = request_line[/HTTP\/(1\.\d)\s*$/, 1]


    case verb
    when 'GET', 'POST', 'PUT', 'OPTIONS'
      uri = URI.parse(url)
    else
      raise "Received unknown verb: #{verb}"
    end

    server = TCPSocket.new(uri.host, (uri.port.nil? ? 80 : uri.port))

    # Write the initial input to the destination server
    if uri.path && uri.query
      payload = "#{verb} #{uri.path}?#{uri.query} HTTP/#{version}\r\n"
    else
      payload = "#{verb} #{url} HTTP/#{version}\r\n"
    end
    server.write(payload)

    content_len = 0

    loop do
      line = client.readline

      # Extract content length from client request
      if line =~ /^Content-Length:\s+(\d+)\s*$/
        content_len = $1.to_i
      end

      # Strip proxy headers
      if line =~ /^proxy/i
        next
      elsif line.strip.empty?
        server.write("Connection: close\r\n\r\n")

        if content_len >= 0
          # Read the remaining client payload and write it to the server
          server.write(client.read(content_len))
        end

        break
      else
        server.write(line)
      end
    end

    buff = ""
    loop do
      # Read response from server
      server.read(4048, buff)

      # Write response back to client
      client.write(buff)
      break if buff.size < 4048
    end

    # Close the sockets
    client.close
    server.close
  end
end


if __FILE__ == $0
  if ARGV.empty?
    port = 8080
  elsif ARGV.size == 1
    port = ARGV[0].to_i
  else
    puts 'Usage: proxy.rb [port]'
    exit 1
  end

  puts "Starting proxy on port #{port}"
  proxy = Proxy.new(port)
  proxy.run
end
