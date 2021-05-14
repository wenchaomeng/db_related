ulimit -HSn 100000
ulimit -n

for pid in `ps -ef  | egrep "pd-serve[r]|tikv-serve[r]" | awk '{print $2}'`
do
	echo killing .... $pid
	kill $pid
done

sleep 2 

echo "===============start pd=================="
pd-server --name=pd --data-dir=/tmp/pd/data --client-urls="http://127.0.0.1:2379" --peer-urls="http://127.0.0.1:2380" --initial-cluster="pd=http://127.0.0.1:2380" --log-file=/tmp/pd/log/pd.log > pd.log 2>&1 &
echo "===============start tikv=================="
tikv-server --pd-endpoints="127.0.0.1:2379" --addr="127.0.0.1:20160" --data-dir=/tmp/tikv/data --log-file=/tmp/tikv/log/tikv.log  > tikv.log 2>&1 &

sleep 1
ps -ef  | egrep "pd-serve[r]|tikv-serve[r]" 
