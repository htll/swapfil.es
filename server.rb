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

class TCPSocket
  attr_accessor :name, :size, :scale

  def init
    @size, @name = self.gets.chomp.split ":", 2

    if !/^\d+$/.match @size or @size.to_i == 0
      self.puts "ERROR invalid filesize '#{@size}'"
      self.close
      throw "ERROR"
    end

    @size = @size.to_i
    @name = @name.gsub /[^0-9A-z.\-]/, '_' # no slashes etc.

    @scale = Math.log(@size).round
    @scale = 1 # @TODO: debug
  end
end

Thread.new {
  loop do
    before = Time.now

    # kek
    connections.each do |scale, conn|
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
  conn.init

  if connections.has_key? conn.scale and not connections[conn.scale].closed?
    Thread.new {
      a = conn
      b = connections.delete a.scale
      a.puts "GO"
      b.puts "GO"
      b.puts "#{a.size}:#{a.name}"
      a.puts "#{b.size}:#{b.name}"

      loop do
        a.write b.read [CHUNK_SIZE, b.size].min
        b.write a.read [CHUNK_SIZE, a.size].min

        b.size -= [CHUNK_SIZE, b.size].min
        a.size -= [CHUNK_SIZE, a.size].min
        break if b.size == 0 and a.size == 0
      end
      a.close
      b.close
    }
  else
    connections[conn.scale] = conn
  end
end
