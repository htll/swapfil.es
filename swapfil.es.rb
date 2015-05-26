#!/usr/bin/ruby

require "openssl"
require "socket"
require "thread"

CHUNK_SIZE = 4 * 1024
PORT = 6666

# ctx = OpenSSL::SSL::SSLContext.new
# ctx.cert = OpenSSL::X509::Certificate.new File.open("cert.pem")
# ctx.key = OpenSSL::PKey::RSA.new File.open("priv.pem")

# server = OpenSSL::SSL::SSLServer.new TCPServer.new(PORT), ctx
server = TCPServer.new PORT

puts "Listening on port #{PORT}"

connections = Hash.new

loop do
  conn = server.accept
  size, name = conn.gets.chomp.split ":", 2
  size = size.to_i

  scale = Math.log(size).round
  puts "Got file '#{name}' of scale #{scale}"

  if connections.has_key? scale
    Thread.new {
      a = conn
      b, b_size, b_name = connections.delete scale
      b.puts "#{size}:#{name}"
      a.puts "#{b_size}:#{b_name}"

      loop do
        a.write b.read [CHUNK_SIZE, b_size].min
        b.write a.read [CHUNK_SIZE, size].min

        b_size -= [CHUNK_SIZE, b_size].min
        size -= [CHUNK_SIZE, size].min
        break if b_size == 0 and size == 0
      end
      a.close
      b.close
    }
  else
    connections[scale] = [conn, size, name]
  end
end
