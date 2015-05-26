#!/usr/bin/ruby

require "socket"
require "openssl"

CHUNK_SIZE = 4 * 1024

host = ARGV.shift
port = ARGV.shift.to_i

#expectedCert = OpenSSL::X509::Certificate.new(File.open("cert.pem"))
# ssl = OpenSSL::SSL::SSLSocket.new TCPSocket.new(host, port)
# ssl.sync_close = true
# ssl.connect
ssl = TCPSocket.new host, port

#if ssl.peer_cert.to_s != expectedCert.to_s
#  stderrr.puts "Unexpected certificate"
#  exit(1)
#end

inp = File.open ARGV.shift, "rb"
ssl.puts "#{inp.size}:#{File.basename(inp.path)}"

ssl.puts "PONG" until ssl.gets.chomp == "GO"

size, name = ssl.gets.chomp.split ':', 2
name = "_" + name while File.exists? name # unique name

out = File.open( name, "wb" )
print "fetching file '#{name}' (#{size}B)..."

send = Thread.new {
  ssl.write inp.read CHUNK_SIZE until inp.eof?
}

recv = Thread.new {
  size = size.to_i
  out.write ssl.read [CHUNK_SIZE, size - out.pos].min while out.pos < size
}

send.join
recv.join

ssl.close
out.close

puts "   done!"
