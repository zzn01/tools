#!/usr/bin/env sh


# src mode: shost/dport/dhost can not change, sport can change
# dst mode: shost/sport/dhost can not change, dport can change
mode="src"
interval=60

show_help(){
	echo "Usage: $0 [-i interval] <-S/-D> <shost:sport> <dhost:dport>"
	exit 1
}
while getopts "SDhi:" opt; do
	case "$opt" in
		h|\?)
			show_help
			exit 0
			;;
		S)  mode="src"
			;;
		D)  mode="dst"
			;;
		i)  interval=$OPTARG
			;;
	esac
done

shift $((OPTIND-1))

shost="`echo $1 | awk -F: '{print $1}'`"
sport="`echo $1 | awk -F: '{print $2}'`"
dhost="`echo $2 | awk -F: '{print $1}'`"
dport="`echo $2 | awk -F: '{print $2}'`"

ss_args=""

get_sport(){
	echo $1 | awk '{print $4}' | cut -d: -f2
}

get_dport(){
	echo $1 | awk '{print $5}' | cut -d: -f2
}


if [ "x$mode" = "xdst" ] ; then
	if [ -z "$sport" ] ; then
		echo "Error: dst mode must specify sport."
		show_help
	fi

	if [ -z "$dport" ] ; then
		dport=0
	fi

	ss_args="dst $dhost src $shost sport = :$sport"
	grep_args=$dhost:$dport 
else
	if [ -z "$dport" ] ; then
		echo "Error: src mode must specify dport."
		show_help
	fi

	if [ -z "$sport" ] ; then
		sport=0
	fi

	ss_args="dst $dhost src $shost dport = :$dport"
	grep_args=$shost:$sport 
fi

while true 
do
	DATE=`date +"%F %H:%M:%S"`
	MSG=`ss -nti $ss_args | grep -A1 "$grep_args"| paste - -` 

	if [ -z "$MSG" ] ; then
		#echo $dhost:$dport not exist
		MSG=`ss -nti $ss_args | grep -A1 "$dhost:"| tail -n 2 | paste - -` 
		#echo $MSG

		if [ "x$mode" = "xdst" ] ; then
			dport=`get_dport "$MSG"`
			grep_args=$dhost:$dport 
		else
			sport=`get_sport "$MSG"`
			grep_args=$shost:$sport 
		fi
	fi
	echo $DATE $MSG
	
	sleep $interval
done


