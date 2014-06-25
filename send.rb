#!/usr/bin/ruby 
require 'socket'

if ARGV.size != 1 && ARGV.size != 2
	print "Usage : send.rb host port\n"
	exit
end
#host = gethostbyname(ARGV[0])
host = ARGV[0]
port = ARGV.size == 2 ? ARGV[1].to_i : 1818


# ruby bug...
if "localhost" == host
	host = "127.0.0.1"
end

s = Socket.new(Socket::Constants::AF_INET, Socket::Constants::SOCK_STREAM, 0)
s.connect( Socket.pack_sockaddr_in(port, host))
s.binmode
while ! STDIN.eof do
	begin
		s.write(STDIN.readpartial(65536))
	rescue EOFError 
		s.close
		exit
	end
end
