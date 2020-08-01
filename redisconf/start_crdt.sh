. template/fun.sh

count=$1
slavecount=$2
if [ -z $count ];then
	count=2
fi
if [ -z $slavecount ];then
	slavecount=1
fi


echo "redis count:"$count
initport=6379

function startRedis(){

	currentPort=$1
	gid=$2
	echo ========start redis $currentPort gid:$gid=================

	rm -rf  $currentPort
	makedir $currentPort
	cp template/fun.sh template/redis.sh template/master.conf $currentPort

	cd $currentPort
	sh redis.sh $gid
	cd ..
}


port=$initport

# masters   6379    |   6479     |    6579
# slaves  6389 6390 | 6489  6490 |  6589 6590

# start master-slave
for (( i=0;i<$count;i++ ))
do
		port=$(( $initport + 100*i ))
		echo start master at $port
		startRedis $port $(($i+1))
		for (( j=0;j<$slavecount;j++ ))
		do
				slave_port=$(( $port + $j + 1 ))
				startRedis $slave_port $(($i+1))
				echo "make redis slaveof $initport"
				redis 127.0.0.1 $slave_port "slaveof 127.0.0.1 $port"
		done
done

#make master-master ok
for (( i=0;i<$count;i++ ))
do
	src_port=$(( $initport + i*100  ))
	for(( j=0;j<$count;j++ ))	
	do
		dst_port=$(( $initport + j*100 ))
		if [ $src_port -eq $dst_port ];then
			continue
		fi
		redis-cli -h 127.0.0.1 -p $src_port << EOF
		peerof $(($j+1)) 127.0.0.1 $dst_port
EOF
	done
done

ps -ef | grep '[r]edis-server'
