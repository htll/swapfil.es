#!/usr/bin/ruby

require "openssl"
require "socket"
require "timeout"
require "thread"

CHUNK_SIZE = 4 * 1024
PORT = ARGV.shift.to_i

# ctx = OpenSSL::SSL::SSLContext.new
# ctx.cert = OpenSSL::X509::Certificate.new File.open("cert.pem")
# ctx.key = OpenSSL::PKey::RSA.new File.open("priv.pem")

# server = OpenSSL::SSL::SSLServer.new TCPServer.new(PORT), ctx
server = TCPServer.new PORT

puts "Listening on port #{PORT}"

connections = Hash.new

Thread.new {
  loop do
    before = Time.now

    # kek
    connections.each do |scale, conn|
      conn, size, name = conn
      conn.puts "PING"
      begin 
        timeout 2 do
          throw Timeout::Error unless conn.gets.chomp == "PONG" # wrong answer is like no answer
        end
      rescue Timeout::Error
        puts "Timed out!"
        conn.close
        connections.delete scale
      end
    end

    interval = 5 - (Time.now-before)
    sleep(interval) if interval > 0
  end
}

loop do
  conn = server.accept
  size, name = conn.gets.chomp.split ":", 2

  if !/^\d+$/.match size or size.to_i == 0
    conn.puts "ERROR invalid filesize '#{size}'"
    conn.close
    next
  end

  size = size.to_i
  name = name.gsub /[^0-9A-z.\-]/, '_' # no slashes etc.

  scale = Math.log(size).round
  scale = 1

  if connections.has_key? scale and not connections[scale][0].closed?
    Thread.new {
      a = conn
      b, b_size, b_name = connections.delete scale
      a.puts "GO"
      b.puts "GO"
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
