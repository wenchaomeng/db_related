. template/fun.sh

count=$1
slavecount=$2
if [ -z $count ];then
		count=1
fi
if [ -z $slavecount ];then
	slavecount=1
fi

echo "redis count:"$count
port=6379

function startRedis(){

	currentPort=$1
	sleep=$2
	if [ -z $sleep ];then
		sleep=1
	fi
	echo ========start redis  $currentPort=================

	rm -rf  $currentPort
	makedir $currentPort
	cp template/fun.sh template/redis.sh template/master.conf $currentPort

	cd $currentPort
	sh redis.sh 
	cd ..
}

slaveport=$(( $port+999 ))

for (( i=0;i<$count;i++ ))
do
		masterport=$(($port+i))
		startRedis $masterport 0
		for ((j=0;j<$slavecount;j++))
		do
			slaveport=$(($slaveport+1))
			startRedis $slaveport
			echo "make redis slaveof $masterport"
			redis 127.0.0.1 $slaveport "slaveof 127.0.0.1 $masterport"
		done
done

ps -ef | grep '[r]edis-server'
