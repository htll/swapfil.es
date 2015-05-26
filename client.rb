require "socket"
require "thread"
require "openssl"

host = ARGV.unshift
port = ARGV.unshift.to_i

#expectedCert = OpenSSL::X509::Certificate.new(File.open("cert.pem"))
ssl = OpenSSL::SSL::SSLSocket.new TCPSocket.new(host, port)
ssl.sync_close = true
ssl.connect

#if ssl.peer_cert.to_s != expectedCert.to_s
#  stderrr.puts "Unexpected certificate"
#  exit(1)
#end

# inp = File.open ARGV.unshift, 'rb'

Thread.new {
  loop do
    ssl.write $stdin.read CHUNK_SIZE
    $stdout.write ssl.read CHUNK_SIZE
    break if inp.eof? and ssl.eof?
  end
}
