#!/usr/bin/perl
use Socket;
if ($#ARGV == -1) { print "Usage : send.pl host port\n";exit;}
my $host = $ARGV[0];
my $proto = getprotobyname('tcp');
my $port = $#ARGV > 0 ? $ARGV[1] : 1818;
$handle = &Connect2Server($host, $port, 2);
while (<STDIN>) {
        print $handle $_;
}
close $handle;
exit;

sub interrupt {
        print "interrupted\n";
        exit;
}
sub Connect2Server {
        my ($host, $port) = @_;
        my $find = 0;
        my $sin;

        socket(Socket_Handle, PF_INET, SOCK_STREAM, $proto) || die "Socket: $!";
        $sin = sockaddr_in($port, inet_aton($host));

        select(Socket_Handle);
        $| = 1;
        select(stdout);

        $result = connect(Socket_Handle, $sin);
        if ($result != 1) {
                print "Connection Fail!!\n";
                exit;
        }
        return Socket_Handle;
}
