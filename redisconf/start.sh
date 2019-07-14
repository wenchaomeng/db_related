. template/fun.sh

count=$1
if [ -z $count ];then
		count=2
fi

echo "redis count:"$count
port=6379

function startRedis(){

	currentPort=$1
	echo ========start redis  $currentPort=================

	rm -rf  $currentPort
	makedir $currentPort
	cp template/fun.sh template/redis.sh template/master.conf $currentPort

	cd $currentPort
	sh redis.sh
	cd ..
}

initport=$port
startRedis $port

for (( i=1;i<$count;i++ ))
do
		port=$(( $port + 100 ))
		startRedis $port
		echo "make redis slaveof $initport"
		redis 127.0.0.1 $port "slaveof 127.0.0.1 $initport"
done

ps -ef | grep '[r]edis-server'
