#! /bin/sh

MP_PID=$(ps -wx -o pid,command | grep MarcoPolo | grep MacOS | awk '{ print $1 }')
echo "Monitoring pid $MP_PID"

SLEEP_INTERVAL=10

last_vsize=-1
while true ; do
	vsize=$(ps -p $MP_PID -o vsize | tail -1)
	if [ $last_vsize -eq -1 ]; then
		echo "VSIZE: $vsize KB"
	else
		gain=$(($vsize - $last_vsize))
		rate=$(($gain / $SLEEP_INTERVAL))
		echo "VSIZE: $vsize KB (gain: $gain == $rate/s)"
	fi

	last_vsize=$vsize
	sleep $SLEEP_INTERVAL
done
