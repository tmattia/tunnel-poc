#!/usr/bin/env ruby
# A quick and dirty implementation of an HTTP proxy server in Ruby
# because I did not want to install anything.
#
# Copyright (C) 2009-2014 Torsten Becker <torsten.becker@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'socket'
require 'uri'
require 'openssl'


class Proxy
  def run(port)
    begin
      # Start our server to handle connections (will raise things on errors)
      @socket = TCPServer.new port

      # Handle every request in another thread
      loop do
        s = @socket.accept
        Thread.new s, &method(:handle_request)
      end

      # CTRL-C
    rescue Interrupt
      puts 'Got Interrupt..'
      # Ensure that we release the socket on errors
    ensure
      if @socket
        @socket.close
        puts 'Socked closed..'
      end
      puts 'Quitting.'
    end
  end

  def handle_request to_client
    request_line = to_client.readline
    puts "Request line: #{request_line}"

    # Parse first request line
    verb    = request_line[/^\w+/]
    url     = request_line[/^\w+\s+(\S+)/, 1]
    version = request_line[/HTTP\/(1\.\d)\s*$/, 1]
    puts "Verb: #{verb}"
    puts "URL: #{url}"
    puts "Version: #{version}"

    https = false


    case verb
    when 'CONNECT'
      # Establish HTTPS connection
      url_with_prefix = "https://#{url}"
      uri = URI.parse(url_with_prefix)
      https = true
    when 'GET', 'POST', 'PUT', 'OPTIONS'
      # Make HTTP request
      uri = URI.parse(url)
    else
      raise "Received unknown verb: #{verb}"
    end
    puts "URI Host: #{uri.host}"
    puts "URI Port: #{uri.port}"
    puts "URI Path: #{uri.path}"
    puts "URI Query: #{uri.query}"

    # Show what got requested
    puts((" %4s "%verb) + url)


    # Open a socket to the destination server
    socket = TCPSocket.new(uri.host, (uri.port.nil? ? 80 : uri.port))

    if https
      ctx = OpenSSL::SSL::SSLContext.new
      ctx.set_params(verify_mode: OpenSSL::SSL::VERIFY_PEER)
      to_server = OpenSSL::SSL::SSLSocket.new(socket, ctx) do |sock|
        sock.sync_close = true
        sock.connect
      end
    else
      to_server = socket
    end

    # Write the initial input to the destination server
    if uri.path && uri.query
      payload = "#{verb} #{uri.path}?#{uri.query} HTTP/#{version}\r\n"
    else
      payload = "#{verb} #{url} HTTP/#{version}\r\n"
    end
    puts "Writing payload to server: #{payload}"
    to_server.write(payload)

    content_len = 0

    loop do
      line = to_client.readline

      # Extract content length from client request
      if line =~ /^Content-Length:\s+(\d+)\s*$/
        content_len = $1.to_i
      end

      # Strip proxy headers
      if line =~ /^proxy/i
        next
      elsif line.strip.empty?
        to_server.write("Connection: close\r\n\r\n")

        if content_len >= 0
          # Read the remaining client payload and write it to the server
          to_server.write(to_client.read(content_len))
        end

        break
      else
        to_server.write(line)
      end
    end

    buff = ""
    loop do
      # Read response from server
      to_server.read(4048, buff)

      # Write response back to client
      to_client.write(buff)
      break if buff.size < 4048
    end

    # Close the sockets
    to_client.close
    to_server.close
  end
end


# Get parameters and start the server
if ARGV.empty?
  port = 8008
elsif ARGV.size == 1
  port = ARGV[0].to_i
else
  puts 'Usage: proxy.rb [port]'
  exit 1
end

Proxy.new.run port
