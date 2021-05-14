. ./ips.sh

ptoy=$meta_uat_ptoy
ptjq=$meta_uat_ptjq
logfile=grep.log

currentDC=$ptoy

function findCluster(){
	ips=$1
	cluster=$2

	echo "ips:"$ips
	echo "cluster:"$cluster
	for ip in $ips
	do
    	echo "==========:"$ip
    	curl -s http://$ip:8080/api/current/debug | egrep $cluster
	done

}

function grepLog(){

	ips=$1
	cmd=$2
	log=$3
	for ip in $ips
	do
    	echo "==========:"$ip
		./utils/expect_jump_cmd.sh  $ip $user $password "$cmd" $log
	done
}

#findCluster "$ptjq" "_601_"
grepLog "$ptjq" 'egrep "changeprimarydc/check.*connect timed out" /opt/logs/100004375/metaserver.log' $logfile &
tail -f $logfile
