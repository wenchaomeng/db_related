#!/bin/bash -x
set -x

BASE_PATH=$(dirname $0)

MODE=GTID
MYSQL_MASTER_ROOT_PASSWORD=root
MYSQL_MASTER_ADDRESS=127.0.0.1
MYSQL_MASTER_PORT=3306
MYSQL_SLAVE_ROOT_PASSWORD=root
MYSQL_SLAVE_ADDRESS=127.0.0.1
MYSQL_SLAVE_PORT=3307
MYSQL_REPLICATION_USER=repl
MYSQL_REPLICATION_PASSWORD=repl


#echo "stopping slave in SLAVE MYSQL"
#mysql --host database_slave -uroot -p$MYSQL_SLAVE_ROOT_PASSWORD -AN -e "stop slave;";
#mysql --host database_slave -uroot -p$MYSQL_SLAVE_ROOT_PASSWORD -AN -e "reset slave all;";

echo "stopping slave in SLAVE MYSQL $MYSQL_SLAVE_ADDRESS:$MYSQL_SLAVE_PORT "
mysql --host $MYSQL_SLAVE_ADDRESS --port $MYSQL_SLAVE_PORT -uroot -p$MYSQL_SLAVE_ROOT_PASSWORD -AN -e "stop slave;";
mysql --host $MYSQL_SLAVE_ADDRESS --port $MYSQL_SLAVE_PORT -uroot -p$MYSQL_SLAVE_ROOT_PASSWORD -AN -e "reset slave all;";

echo "creating replication user in MASTER MYSQL"

mysql --host $MYSQL_MASTER_ADDRESS --port $MYSQL_MASTER_PORT -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -AN -e "create user '$MYSQL_REPLICATION_USER'@'%';"
mysql --host $MYSQL_MASTER_ADDRESS --port $MYSQL_MASTER_PORT -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -AN -e "grant replication slave on *.* to '$MYSQL_REPLICATION_USER'@'%' identified by '$MYSQL_REPLICATION_PASSWORD';"
mysql --host $MYSQL_MASTER_ADDRESS --port $MYSQL_MASTER_PORT -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -AN -e "flush privileges;"


echo "getting MASTER MYSQL config"

if [ $MODE == "GTID" ];then
	echo "set SLAVE to upstream MASTER using gtid"
	mysql --host $MYSQL_SLAVE_ADDRESS --port $MYSQL_SLAVE_PORT -uroot -p$MYSQL_SLAVE_ROOT_PASSWORD -AN -e "change master to master_host='$MYSQL_MASTER_ADDRESS',master_port=$MYSQL_MASTER_PORT,master_user='$MYSQL_REPLICATION_USER',master_password='$MYSQL_REPLICATION_PASSWORD',MASTER_AUTO_POSITION=1;"
else
	echo "set SLAVE to upstream MASTER using using file position"
	Master_File="$(mysql --host $MYSQL_MASTER_ADDRESS --port $MYSQL_MASTER_PORT -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -e 'show master status \G' | grep File | sed -n -e 's/^.*: //p')"
	Master_Position="$(mysql --host $MYSQL_MASTER_ADDRESS --port $MYSQL_MASTER_PORT -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -e 'show master status \G' | grep Position | egrep -o '[0-9]+')"
	mysql --host $MYSQL_SLAVE_ADDRESS --port $MYSQL_SLAVE_PORT -uroot -p$MYSQL_SLAVE_ROOT_PASSWORD -AN -e "change master to master_host='$MYSQL_MASTER_ADDRESS',master_port=$MYSQL_MASTER_PORT,master_user='$MYSQL_REPLICATION_USER',master_password='$MYSQL_REPLICATION_PASSWORD',master_log_file='$Master_File',master_log_pos=$Master_Position;"
fi

echo "start sync: MASTER to SLAVE"
mysql --host $MYSQL_SLAVE_ADDRESS --port $MYSQL_SLAVE_PORT -uroot -p$MYSQL_SLAVE_ROOT_PASSWORD -AN -e "start slave;"
mysql --host $MYSQL_SLAVE_ADDRESS --port $MYSQL_SLAVE_PORT -uroot -p$MYSQL_SLAVE_ROOT_PASSWORD -e "show slave status \G;"


echo "mysql fine tuning and extra conf"

echo "increasing connection limit"
mysql --host $MYSQL_SLAVE_ADDRESS --port $MYSQL_SLAVE_PORT -uroot -p$MYSQL_SLAVE_ROOT_PASSWORD -AN -e "set GLOBAL max_connections=2000;"
mysql --host $MYSQL_MASTER_ADDRESS --port $MYSQL_MASTER_PORT -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -AN -e "set GLOBAL max_connections=2000;"


echo "disabling sql_mode = ONLY_FULL_GROUP_BY"
mysql --host $MYSQL_SLAVE_ADDRESS --port $MYSQL_SLAVE_PORT -uroot -p$MYSQL_SLAVE_ROOT_PASSWORD -AN -e "SET GLOBAL sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));"
mysql --host $MYSQL_MASTER_ADDRESS --port $MYSQL_MASTER_PORT -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -AN -e "SET GLOBAL sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));"
