DIR=`dirname $0`
FULL_DIR=`pwd`/$DIR
echo $DIR

CONFIG=$DIR/master.conf
DATA=$DIR/data
LOG=$DIR/log
CRDT_NAMESPACE=test_cluster
CRDT=crdt.so
CRDT_DIR=
GID=$1
SLEEP=$1
if [ -z "$GID" ];then
	GID=1
fi
if [ -z "$SLEEP" ];then
	SLEEP=1
fi


. $DIR/fun.sh

PORT=`getPort $FULL_DIR`

makedir $DATA
makedir $LOG

backlog $LOG

if [ -f $DIR/slave.conf ]
then
	CONFIG=$DIR/slave.conf
fi

##########ctdt support
echo gid:$GID
if [ -f $FULL_DIR/$CRDT ];then
	CRDT_DIR=$FULL_DIR/$CRDT
	echo crdt support: $CRDT_DIR
elif [ -f $FULL_DIR/../$CRDT ];then
	CRDT_DIR=$FULL_DIR/../$CRDT
	echo crdt support: $CRDT_DIR
fi
sed -i '/loadmodule/d' $DIR/*.conf
if [ -f "$CRDT_DIR" ];then
    sed -i '$aloadmodule '$CRDT_DIR $DIR/*.conf
fi

sed -i '/crdt-gid/d' $DIR/*.conf
if [ -f "$CRDT_DIR" ];then
	sed -i '$acrdt-gid '$CRDT_NAMESPACE' '$GID $DIR/*.conf
fi

##########ctdt support


if [ -n "$PORT"  ];then
    echo "port from dir:$PORT"
    sed -i "s/port.*/port $PORT/" $DIR/*.conf
fi

PORT=`cat $CONFIG | grep port | awk '{print $2}'`

echo "Using config file:"$CONFIG $PORT

preCount=0
for pid in `ps -ef | grep 'redis-serve[r]' | grep "$PORT" | awk '{print $2}'`; do
	echo "killing" $pid
	kill -9 $pid
	preCount=$(( $preCount + 1 ))
done

if [ $preCount -ge 0 ];then
	sleep 1
fi

DATA_DIR=$FULL_DIR"/data"
sed -i  "s#dir.*#dir $DATA_DIR#"   $DIR/*.conf

REDIS=redis-server
if [ -f $DIR/redis-server ];then
	REDIS=$DIR/redis-server
	echo using $REDIS
fi
nohup $REDIS $CONFIG  > $LOG/master.log 2>&1 &
sleep $SLEEP
