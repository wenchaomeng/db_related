LOGDIR=sen_log
DATADIR=sen_data


. ./fun.sh
makedir  $LOGDIR
makedir  $DATADIR

for pid in `ps -ef | grep 'redis-sentine[l]' | awk '{print $2}'`; do
    echo "killing" $pid
    kill -9 $pid
done


FULL_DATA_DIR=`pwd`"/$DATADIR"
echo "data dir:$FULL_DATA_DIR"
sed -i  "s#dir.*#dir $FULL_DATA_DIR#"   *.conf

sed -i '/epoch/d' sentinel*.conf
sed -i '/known-/d' sentinel*.conf
sed -i '/sentinel /d' sentinel*.conf
sed -i '$asentinel monitor myredis 127.0.0.1 6379 3' sentinel*.conf

echo "before:================="
ps -ef | grep  "redis-sentine[l]"
echo "before:================="

nohup redis-sentinel sentinel.conf > $LOGDIR/sentinel.log 2>&1 &
nohup redis-sentinel sentinel1.conf > $LOGDIR/sentinel1.log 2>&1 &
nohup redis-sentinel sentinel2.conf > $LOGDIR/sentinel2.log 2>&1 &


echo "after:================="
ps -ef | grep  "redis-sentine[l]"
echo "after:================="
