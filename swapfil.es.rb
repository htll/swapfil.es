#!/usr/bin/ruby

require "openssl"
require "socket"

PORT = 6666

ctx = OpenSSL::SSL::SSLContext.new
ctx.cert = OpenSSL::X509::Certificate.new File.open("cert.pem")
ctx.key = OpenSSL::PKey::RSA.new File.open("priv.pem")

server = OpenSSL::SSL::SSLServer.new TCPServer.new(PORT), ctx

puts "Listening on port #{listeningPort}"

loop do
  connection = sslServer.accept
  Thread.new {
    # wait for two connections (a, b)
    # loop do
      # a.write b.read CHUNK_SIZE
      # b.write a.read CHUNK_SIZE
      # break if a.eof? and b.eof?
    # end
  }
end
