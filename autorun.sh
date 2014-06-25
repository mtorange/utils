#!/bin/bash 

function usage 
{
	echo 'Usage : ' $0 'target-file' ' [args]'
	echo ""
	exit -1
}


if [ $# -ge 1 ]; then
    TARGET=$1
else
    usage
fi

shift

wheel=('-'  '\'  '|'  '/')
i=0
executed_mtime=00000000000

while true
do
	mtime=`stat -f "%m" $TARGET`
	if [ $executed_mtime != $mtime ]; then
		echo
		echo === START =============================
		echo EXEC: $TARGET $*
		echo .......................................
		$TARGET $*
		echo .......................................
		echo 
		executed_mtime=$mtime
	else
		for a in 1 2 3 4 5 6 7 8 9 0 ; do
			let "i = ($i + 1) % 4"
			echo -n -e "\r"
			echo -n  ${wheel[$i]} 
			sleep 0.1
		done
	fi
done
