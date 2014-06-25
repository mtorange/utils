#!/usr/bin/ruby 
require 'optparse'
require 'socket'

opt_verbose = false
opt_port = nil
opt_host = nil
opt_timeout = -1

optParser = OptionParser.new { |opts|
	opts.banner = "Usage: bitrans.rb -p port [-s server] [-v] [-t]"
	opts.on("-p", "--port port", OptionParser::DecimalInteger, "Bind Port or Destination Port") do |v|
		opt_port = v
	end
	opts.on("-s", "--server host", "Destination Host") do |v|
		opt_host = v
	end
	opts.on("-t", "--timeout milliseconds", OptionParser::DecimalInteger, "Socket timeout") do |v|
		opt_timeout = v
	end
	opts.on("-v", "--verbose", "Verbose mode") do |v|
		opt_verbose = v
	end
	opts.on('-h', '--help', 'Diaply this help') do 
		STDERR.puts opts
		exit
	end
}

begin
	optParser.parse!(ARGV)
rescue OptionParser::ParseError => e
	STDERR.puts e
	STDERR.puts
	STDERR.puts optParser
	exit
end

if opt_port.nil?
	STDERR.puts optParser
	exit
end

selectTimeout = (opt_timeout <= 0) ? nil : (opt_timeout / 1000.0)


def connectWithTimeout(socket, addr, timeout)
	begin
		socket.connect_nonblock( addr )
	rescue Errno::EINPROGRESS
		r, w, e = IO.select(nil, [socket], [socket], timeout)
		raise Errno::ETIMEDOUT if w.nil?
		begin
			socket.connect_nonblock( addr )
			#z = socket.getsockopt(Socket::SOL_SOCKET, Socket::SO_ERROR)
			#if (ECONNREFUSED == z[0]) raise "ECONNREFUSED"
		rescue Errno::EISCONN
		end
	end
end

socket = nil
begin
	if opt_host.nil?
		#server
		STDERR.puts "Listening ....." if opt_verbose
		serv = TCPServer.open(Socket::INADDR_ANY, opt_port)
		socket = serv.accept
		serv.close
		STDERR.puts "Connection received ....." if opt_verbose
	else
		#client
		STDERR.puts "Connecting ....." if opt_verbose
		socket = Socket.new(Socket::Constants::AF_INET, Socket::Constants::SOCK_STREAM, 0)
		connectWithTimeout(socket, Socket.pack_sockaddr_in(opt_port, opt_host), selectTimeout)
		STDERR.puts "Connected ....." if opt_verbose
	end
	socket.binmode
	STDIN.binmode


	selectSet = [STDIN, socket]
	while true do
		rs, ws = IO.select(selectSet, nil, nil, selectTimeout)
		raise Errno::ETIMEDOUT if rs.nil?
		rs.each { |r|
			dest = (r == socket) ? STDOUT : socket
			begin 
				dest.write(r.readpartial(65535))
			rescue EOFError=>e
				raise e if r == socket
				selectSet = [socket]
				socket.shutdown(Socket::SHUT_WR)
			end
		}
	end
rescue Interrupt
	raise
rescue EOFError=>e
	STDERR.puts "Connection closed" if opt_verbose
	socket.close if not socket.nil?
rescue Exception=> e
	STDERR.puts "ERROR:#{e}"
	STDERR.puts e.inspect
	STDERR.puts e.backtrace
	socket.close if not socket.nil?
end

