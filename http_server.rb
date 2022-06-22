require 'socket'

class HTTPServer
  def initialize(port)
    @http_server = TCPServer.new(port)
  end

  def handle_request(session)
    request = session.gets
    puts request

    session.print "HTTP/1.1 200\r\n"
    session.print "Content-Type: text/html\r\n"
    session.print "\r\n"
    session.print "Hello world! The time is #{Time.now}"

    session.close
  end

  def run
    loop do
      session = @http_server.accept

      Thread.new(session, &method(:handle_request))
    end
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
