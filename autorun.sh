#!/bin/bash 

function usage 
{
	echo 'Usage : ' $0 'target-file-to-be-tested' '[command-to-be-executed arguments...]'
	echo ""
	exit -1
}


if [ $# -ge 1 ]; then
    TARGET=$1
else
    usage
fi

shift

if [ $# -ge 1 ]; then
	CMD=$1
	shift
else
	CMD=$TARGET
fi

wheel=('-'  '\'  '|'  '/')
wheel_color=(31 32 33 34 35 36 37)
i=0
j=0
default_mtime=00000000000
executed_mtime=$default_mtime
options=()

OS=$(uname -s)
case $OS in
	(Darwin)
		options=(-q -f "%m" "$TARGET")
		;;
	(Linux)
		options=(-c "%Y" "$TARGET")
		;;
	(CYGWIN*)
		options=(-c "%Y" "$TARGET")
		;;
	(*)
		echo "Cannot detect OS"
		exit
esac

echo "-------["$0"]-------------"
echo "-- Monitoring command     : 'stat "${options[*]}"'"
echo "-- Command to be executed : '"$CMD $*"'"
while true
do
	mtime=$(stat ${options[*]} || echo $default_mtime)

	if [ \( "L"$executed_mtime != "L"$mtime \)  -a \( "L"$mtime != "L"$default_mtime \) ]; then
		echo
		echo === START =============================
		echo EXEC: $CMD $*
		echo .......................................
		$CMD "$@"
		echo .......................................
		echo 
		executed_mtime=$mtime
	fi

	let "i = ($i + 1) % ${#wheel[*]}"
	let "j = ($j + 1) % ${#wheel_color[*]}"
	echo -n -e "\r"
	echo -n  "[${wheel_color[$j]}m"${wheel[$i]}"[0m"
	if /usr/bin/read -t 1; then
		executed_mtime=00000000000000000
	fi

#		for a in 1 2 3 4 5 ; do
#			let "i = ($i + 1) % ${#wheel[*]}"
#			let "j = ($j + 1) % ${#wheel_color[*]}"
#			echo -n -e "\r"
#			echo -n  "[${wheel_color[$j]}m"${wheel[$i]}"[0m"
#			#sleep 0.2
#			if /usr/bin/read -t 1; then
#				executed_mtime=00000000000000000
#				echo "ENTER"
#				break
#			fi
#		done
done
