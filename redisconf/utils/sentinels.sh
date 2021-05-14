function count(){
	while read line
	do
		ip=`echo $line | awk '{print $1}'`	
		port=`echo $line | awk '{print $2}'`	
		count=`redis-cli -h $ip -p $port sentinel masters | egrep "\+" | wc -l`
		echo =====process sentinel $ip $port "sentinel count:" $count
	done < $1
}
function command(){
	while read line
	do
		ip=`echo $line | awk '{print $1}'`	
		port=`echo $line | awk '{print $2}'`	
		echo ====$ip $port
		redis-cli -h $ip -p $port $2 
	done < $1
}
function removeAll(){
		while read line
		do
			ip=`echo $line | awk '{print $1}'`	
			port=`echo $line | awk '{print $2}'`	
			echo =====process sentinel $ip $port
			names=`redis-cli -h $ip -p $port sentinel masters | egrep "\+"`
			echo before remove  `echo $names | wc -w`
			for name in $names
			do
				redis-cli -h $ip -p $port sentinel remove $name
			done
			echo after remove  `redis-cli -h $ip -p $port sentinel masters | egrep "name" | wc -l`
		done < $1
}
function test(){
	echo $@
}

#removeAll sentinels_real.data
#count sentinels_real.data
command sentinels_real.data "sentinel masters"  | egrep "==|name"

test a b c
