#!/usr/bin/ruby 
require 'optparse'
require 'socket'
require 'thread'

$opt_bind_port = nil
$opt_dest_port = nil
$opt_dest_host = nil
$opt_verbose = false
$opt_timeout = -1
$opt_display_contents = false
$opt_display_contents_as_binary = false
$opt_display_contents_as_color = false
$opt_max_connection = 10



$printables = (0..255).map{ |b| b.chr}.join.gsub(/[^[:print:]]{1,1}/, ".")
#$printables = (0..255).map{ |b| format("%s",  /[[:print:]]/ === b.chr ? b.chr : '.')}
$hexStrings = (0..255).map{ |b| format("%02X", b)}

def displayContents(direction, data)
	if ($opt_display_contents_as_color) 
		STDERR.printf("%s", direction ? "[s[32m" : "[s[33m")
	end
	if ($opt_display_contents_as_binary)
		obuf = ""
		n = 0
		data.each_byte { |b|
			print $hexStrings[b], " "
			print ":  " if 3 == n.modulo(4)
			obuf << $printables[b]
			n += 1
			if 16 == n
				puts obuf
				obuf = ""
				n = 0
			end
		}
		if n > 0 
			(n..15).each { |v|
				print "  ", " "
				print ":  " if 3 == v.modulo(4)
				obuf << " "
			}
			puts obuf
		end
	else
		STDERR.printf("%s", data);
	end
end

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


optParser = OptionParser.new { |opts|
	opts.banner = "Usage: relay.rb [options]"
	opts.on("-p", "--bind-port port", OptionParser::DecimalInteger, "Bind Port") do |v|
		$opt_bind_port = v
	end
	opts.on("-y", "--dest-port port", OptionParser::DecimalInteger, "Destination Port") do |v|
		$opt_dest_port = v
	end
	opts.on("-z", "--dest-host address", OptionParser::String,  "Destination Address") do |v|
		$opt_dest_host = v
	end
	opts.on("-m", "--max-connection number", OptionParser::DecimalInteger, "Max Concurrent Connection") do |v|
		$opt_max_connection = v
	end
	opts.on("-t", "--timeout millisecond", OptionParser::DecimalInteger, "Socket timeout") do |v|
		$opt_timeout = v
	end
	opts.on("-d", "--display-contents", "Display contents") do |v|
		$opt_display_contents = v
	end
	opts.on("-b", "--binary-display", "Display contents as binary form") do |v|
		$opt_display_contents_as_binary = v
	end
	opts.on("-c", "--colored-display", "Display contents as colored form") do |v|
		$opt_display_contents_as_color = v
	end
	opts.on("-v", "--verbose", "Verbose mode") do |v|
		$opt_verbose = v
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

if $opt_bind_port.nil? or $opt_dest_port.nil? or $opt_dest_host.nil?
	STDERR.puts optParser
	exit
end

STDOUT.sync = true if $opt_display_contents

printf(
		" -- Setting --------------\n"+
		" Target          : %s:%d\n"+
		" Port            : %d\n"+
		" Connection Max  : %d\n"+
		" Network Timeout : %s\n"+
		" -------------------------\n",
		$opt_dest_host, $opt_dest_port, 
		$opt_bind_port, $opt_max_connection, $opt_timeout <= 0 ? "Infinite" : "#{$opt_timeout.to_s} ms")
###
mutex = Mutex.new
cond = ConditionVariable.new
threadCount = 0
selectTimeout = ($opt_timeout <= 0) ? nil : ($opt_timeout / 1000.0)


serv = TCPServer.open(Socket::INADDR_ANY, $opt_bind_port)
while true do
	mutex.synchronize  do
		while threadCount >= $opt_max_connection 
			cond.wait(mutex)
		end
	end
	s = serv.accept
	mutex.synchronize do
		threadCount += 1
	end
	Thread.new do
		threadStr = format("%03d(%03d/%03d)", Thread.current.object_id % 1000, threadCount, $opt_max_connection)
		STDOUT.puts("#{threadStr}-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-= connected") if $opt_verbose

		s1 = s
		s2 = Socket.new(Socket::Constants::AF_INET, Socket::Constants::SOCK_STREAM, 0)
		begin
			connectWithTimeout(s2, Socket.pack_sockaddr_in($opt_dest_port, $opt_dest_host), selectTimeout)
			s1.binmode
			s2.binmode

			while true do
				rs, ws = IO.select([s1, s2], [], nil, selectTimeout)
				raise Errno::ETIMEDOUT if rs.nil?
				rs.each { |r|
					dest = (r == s1) ? s2 : s1
					data = r.readpartial(65535)
					displayContents(r == s1, data) if $opt_display_contents
					dest.write(data)
				}
			end
		rescue EOFError
			STDOUT.puts("#{threadStr}............................................................... closed") if $opt_verbose
			s1.close
			s2.close
		rescue Exception => e
			STDOUT.puts("#{threadStr}................................................................ error") if $opt_verbose
			STDERR.puts("#{threadStr}:ERROR:#{e}")
			#STDERR.puts e.backtrace
			s1.close
			s2.close
		end
		mutex.synchronize do
			threadCount -= 1
			cond.signal
		end
	end
end

