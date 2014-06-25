#!/usr/bin/ruby 
require 'socket'

port = ARGV.size > 0 ? ARGV[0].to_i : 1818
serv = TCPServer.open(Socket::INADDR_ANY, port)
s = serv.accept
serv.close
s.binmode
while ! s.eof do
	begin
		STDOUT.write(s.readpartial(65536))
	rescue Error 
		s.close
		serv.close
		exit
	end
end
