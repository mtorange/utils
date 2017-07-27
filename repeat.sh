#!/bin/bash 

function usage 
{
	echo 'Usage :' $0 'interval(seconds)' 'command-to-be-executed [arguments...]'
	echo ""
	exit -1
}
isnum() { 
	awk -v a="$1" 'BEGIN {print (a == a + 0)}'; 
}




args=`getopt s:v $*`
if [ $? != 0 ]; then
	usage
fi

set -- $args
INTERVAL=1
VERBOSE="false"
for i do
	case "$i" in
		-s)
			INTERVAL=$2
			shift
			shift
			;;
		-v)
			VERBOSE="true"
			shift
			;;
		--)
			shift
			break
			;;
	esac
done

if [ $# -lt 1 ]; then
	usage
fi

if [  "1" != `isnum $INTERVAL` ]; then
	usage
fi

CMD=$1
shift

if [ $VERBOSE == "true" ]; then
	echo "Command:" $CMD "$@"
	echo "Interval:" $INTERVAL "second(s)"
fi

while true
do
	$CMD "$@"
	sleep $INTERVAL
done
