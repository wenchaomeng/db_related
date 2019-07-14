DIR=`dirname $0`
FULL_DIR=`pwd`/$DIR
echo $DIR

CONFIG=$DIR/master.conf
DATA=$DIR/data
LOG=$DIR/log

. $DIR/fun.sh

PORT=`getPort $FULL_DIR`

makedir $DATA
makedir $LOG

if [ -f $DIR/slave.conf ]
then
	CONFIG=$DIR/slave.conf
fi

if [ -n "$PORT"  ];then
    echo "port from dir:$PORT"
    sed -i "s/port.*/port $PORT/" $DIR/*.conf
fi

PORT=`cat $CONFIG | grep port | awk '{print $2}'`

echo "Using config file:"$CONFIG $PORT

for pid in `ps -ef | grep 'redis-serve[r]' | grep "$PORT" | awk '{print $2}'`; do
	echo "killing" $pid
	kill -9 $pid
done

sleep 1

DATA_DIR=$FULL_DIR"/data"
sed -i  "s#dir.*#dir $DATA_DIR#"   $DIR/*.conf

REDIS=redis-server
if [ -f $DIR/redis-server ];then
	REDIS=$DIR/redis-server
	echo using $REDIS
fi
nohup $REDIS $CONFIG  > $LOG/master.log 2>&1 &
sleep 2
setProtectedMode 127.0.0.1 $PORT

