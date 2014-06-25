#!/usr/bin/perl
use Socket;
my $ListenPort = $#ARGV != -1 ? $ARGV[0] : 1818;
my $proto = getprotobyname('tcp');
socket(Listen_Handle, PF_INET, SOCK_STREAM, $proto) || die "$0: Cannot socket: $!\n";
my $Sin = sockaddr_in($ListenPort, INADDR_ANY);
bind(Listen_Handle, $Sin) || die "$0: Cannot bind: $!\n";
listen(Listen_Handle, 5) || die "$0: Cannot listen: $!\n";

$remote = accept(NEWSOCKET, Listen_Handle) || die "$0: Unacceptable: $!\n";
$SIG{INT} = \&interrupt;
($RemotePort, $RemoteAddr) = sockaddr_in($remote);

while (<NEWSOCKET>) {
        print $_;
}
close NEWSOCKET;
exit;
sub interrupt {
        close Listen_Handle;
        close NEWSOCKET;
        print "interrupted\n";
        exit;
}
