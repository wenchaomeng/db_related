
ptoy=""
ptjq=""

currentDC=$ptjq

for ip in $currentDC
do
	echo $ip
	curl -s http://$ip:8080/api/current/debug | egrep xpipe_dr_pt_cluster_601
done
