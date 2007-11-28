#! /bin/sh

MP_PID=$(ps -wx -o pid,command | grep MarcoPolo | grep MacOS | awk '{ print $1 }')
echo "Monitoring pid $MP_PID"

SLEEP_INTERVAL=10

last_vsize=-1
while true ; do
	rsize=$(ps -p $MP_PID -o rsz | tail -1 | tr -d ' ')
	vsize=$(ps -p $MP_PID -o vsize | tail -1 | tr -d ' ')
	printf "RSIZE/VSIZE: $rsize/$vsize KB"

	if [ $last_vsize -eq -1 ]; then
		echo
	else
		r_gain=$(($rsize - $last_rsize))
		r_rate=$(($r_gain / $SLEEP_INTERVAL))
		v_gain=$(($vsize - $last_vsize))
		v_rate=$(($v_gain / $SLEEP_INTERVAL))
		echo " (gain: $r_gain/$v_gain ==> $r_rate/$v_rate KB/s)"
	fi

	last_rsize=$rsize
	last_vsize=$vsize
	sleep $SLEEP_INTERVAL
done
