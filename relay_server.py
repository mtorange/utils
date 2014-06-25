#!/usr/bin/env python
## code from. http://code.activestate.com/recipes/114642/

"""
usage 'relay_server.py --from listen_port --to protocol://host:port'

RelayServer forwards the port to the host specified.
The optional newport parameter may be used to
redirect to a different port.

eg. relay_server.py --from 80 --to tcp://webserver:80
    Forward all incoming WWW sessions to webserver.

    relay_server.py --from 8080 --to ssl://localhost:443
    Forward all 8080 port sessions to https on localhost.
"""

import sys
from socket import *
from threading import Thread
import time
import ssl
import argparse
import re

LOGGING = 1
DEBUG = False

def log( s ):
    if LOGGING:
        logfilename = "logs/relay_server.log.%s" % time.strftime("%Y%m%d")
        f = open(logfilename, "a");
        f.write('%s:%s\n' % ( time.ctime(), s ))
        f.flush()
        f.close()

class Config:
    def __init__(self):
        self.parser = argparse.ArgumentParser()
        self.parser.add_argument('--from',
                                 type=int,
                                 help='listen port number (eg, 7000)',
                                 dest='listenPort',
                                 metavar='port',
                                 required=True)
        self.parser.add_argument('--to',
                                 help='relay destination (eg, tcp://10.0.0.1:80, ssl://10.1.1.1:443)',
                                 dest='address',
                                 metavar='address',
                                 required=True)
        self.parser.add_argument('-d',  '--debug',
                                 help='debug mode on',  action='store_true')

    def parse(self):
        args = self.parser.parse_args()

        try:
            (args.protocol, address) = args.address.split('://')
            (args.host, args.port) = address.split(':')

            if args.port != None:
                args.port = int(args.port)
        except Exception, e:
            args.protocol = args.host = args.port = None

        return args

class PipeThread( Thread ):
    pipes = []
    def __init__( self, source, sink, filter_func=None ):
        Thread.__init__( self )
        self.source = source
        self.sink = sink
        self.filter_func = filter_func

        log( 'Creating new pipe thread  %s ( %s -> %s )' % \
            ( self, source.getpeername(), sink.getpeername() ))
        PipeThread.pipes.append( self )
        log( '%s pipes active' % len( PipeThread.pipes ))

    def run( self ):
        while 1:
            try:
                data = self.source.recv( 1024 )
                if not data: break
                if self.filter_func:
                    data = self.filter_func(data)
                else:
                    if 'HTTP/1.1 100 Continue' in data:
                        continue
                if DEBUG: log('(( %s ))' %  data)
                self.sink.send( data )
            except:
                break

        log( '%s terminating' % self )
        PipeThread.pipes.remove( self )
        log( '%s pipes active' % len( PipeThread.pipes ))

class RelayServer( Thread ):
    def __init__( self, port, newhost, newport, ssl_on=False, send_filter_func=None, recv_filter_func=None ):
        Thread.__init__( self )
        log( 'Redirecting: localhost:%s -> %s:%s' % ( port, newhost, newport ))
        self.newhost = newhost
        self.newport = newport
        self.sock = socket( AF_INET, SOCK_STREAM )
        self.sock.setsockopt( SOL_SOCKET, SO_REUSEADDR, 1)
        self.sock.bind(( '', port ))
        self.sock.listen(5)
        self.ssl_on = ssl_on
        self.send_filter_func = send_filter_func
        self.recv_filter_func = recv_filter_func

    def run( self ):
        while 1:
            newsock, address = self.sock.accept()
            log( 'Creating new session for %s %s ' % address )
            fwd = s = socket( AF_INET,  SOCK_STREAM )
            if self.ssl_on == True:
                fwd = ssl.wrap_socket(s)

            fwd.connect(( self.newhost, self.newport ))
            PipeThread( newsock, fwd, self.send_filter_func ).start()
            PipeThread( fwd, newsock, self.recv_filter_func ).start()

def filter_by_host(host, port):
    from_pattern = r'Host: (.+)'
    to_pattern   = 'Host: %s:%s' % (host, port)
    def filter(data):
        if 'Host: ' in data:
            return re.sub(from_pattern, to_pattern, data)
        return data
    return filter

if __name__ == '__main__':
    print 'Starting RelayServer'
    args = Config().parse()

    if not (args.listenPort and args.protocol and args.host and args.port):
        print 'check usage!';
        sys.exit(1)

    DEBUG  = args.debug;
    ssl_on = True if 'ssl' == args.protocol.lower() else False
    send_filter_func = filter_by_host(args.host, args.port)

    RelayServer( args.listenPort, args.host, args.port, ssl_on, send_filter_func, None ).start()

