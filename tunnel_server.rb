require 'socket'

class TunnelServer
  def initialize(control_port, data_port)
    @control_socket = TCPServer.new(control_port)
    @data_socket = TCPServer.new(data_port)
    @servers = {}
  end

  def run
    control_socket_thread = Thread.new do
      loop do
        session = @control_socket.accept

        Thread.new(session, &method(:handle_control_request))
      end
    end

    data_socket_thread = Thread.new do
      loop do
        session = @data_socket.accept

        Thread.new(session, &method(:handle_data_request))
      end
    end

    control_socket_thread.join
    data_socket_thread.join
  end

  def handle_control_request(client)
    puts
    puts '---'

    puts "Handling control request from #{client.inspect}"
    request_line = client.readline
    puts "Received: #{request_line}"

    verb = request_line[/^\w+/]
    domain = request_line[/^\w+\s+(\S+)/, 1]

    case verb
    when 'REGISTER'
      @servers[domain] = client
    else
      raise "Don't know how to handle control request: #{verb}"
    end

    puts '---'
    puts
  end

  def handle_data_request(client)
    puts
    puts '---'
    puts "Handling data request from #{client.inspect}"

    request_line = client.readline
    puts "Received: #{request_line}"

    verb = request_line[/^\w+/]
    domain = request_line[/^\w+\s+(\S+)/, 1]

    case verb
    when 'GET'
      raise "Don't know how to route requests to #{domain}" unless @servers[domain]
      server = @servers[domain]

      # TODO: read, parse and send full HTTP request to server
      server.puts(request_line)

      response = ""
      while line = server.gets
        break if line.strip == "DONE"
        puts "Received response: #{line}"
        response += line
      end
      puts "Responding with: #{response}"
      client.puts(response)
      client.close
    else
      raise "Don't know how to handle data request: #{verb}"
    end

    puts '---'
    puts
  end
end

if __FILE__ == $0
  if ARGV.empty?
    control_port = 8080
    data_port = 80
  elsif ARGV.size == 1
    control_port = ARGV[0].to_i
    data_port = ARGV[1].to_i
  else
    puts 'Usage: tunnel_server.rb [control_port] [data_port]'
    exit 1
  end

  puts "Starting tunnel server on control port #{control_port} and data port #{data_port}"
  tunnel_server = TunnelServer.new(control_port, data_port)
  tunnel_server.run
end
