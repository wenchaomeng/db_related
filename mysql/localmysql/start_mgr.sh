REPL_USER=repl
REPL_PASS=repl
PORTS="4306 4307 4308"
USER_SQL_LOGBIN=0

function create_repl (){
		host=$1
		port=$2
		echo create repl user $REPL_USER pass $REPL_PASS on $host:$port
		mysql -uroot -proot --host $host  --port $port -An << EOF
			SET SQL_LOG_BIN=$(( $USER_SQL_LOGBIN ));
			CREATE USER '$REPL_USER'@'%' IDENTIFIED BY '$REPL_PASS';
			GRANT REPLICATION SLAVE ON *.* TO '$REPL_USER'@'%';
			FLUSH PRIVILEGES;
			SET SQL_LOG_BIN=$(( 1- $USER_SQL_LOGBIN ));
			
EOF
}

function start_group_replication(){
	host=$1
	port=$2
	first=$3

	if [ -z "$first" ];then
		first=yes
	fi

	if [ $first = "yes" ];then
		echo first mgr member group_replication_bootstrap_group=ON
		mysql -uroot -proot --host $host  --port $port -An << EOF
    CHANGE MASTER TO MASTER_USER='$REPL_USER', MASTER_PASSWORD='$REPL_PASS' FOR CHANNEL 'group_replication_recovery';
	SET GLOBAL group_replication_bootstrap_group=ON;
	START GROUP_REPLICATION;
	SET GLOBAL group_replication_bootstrap_group=OFF;
EOF
	else
		echo not first mgr member group_replication_bootstrap_group=ON
		mysql -uroot -proot --host $host  --port $port -An << EOF
    CHANGE MASTER TO MASTER_USER='$REPL_USER', MASTER_PASSWORD='$REPL_PASS' FOR CHANNEL 'group_replication_recovery';
	START GROUP_REPLICATION;
EOF
	fi
}

function show_replication_group_members(){
	host=$1
	port=$2
	
	 mysql -uroot -proot --host $host  --port $port -An << EOF
	SELECT * FROM performance_schema.replication_group_members;
EOF
}

function replace_ports(){
	ports=$1
	file=$2
	for port in $ports
	do
		if ! [ -z $MGR_ADDRESSES ];then
			MGR_ADDRESSES="$MGR_ADDRESSES",
		fi
		MGR_ADDRESSES="$MGR_ADDRESSES"127.0.0.1:"$(( $port*10 + 1 ))"
	done
	sed -i 's/group_replication_group_seeds=".*"/group_replication_group_seeds="'$MGR_ADDRESSES'"/' $file

}

first=yes
replace_ports "$PORTS" mgr.template



########for test purpose
#create_repl 127.0.0.1 4306
#first=yes
#PORTS="4307 4308"
########for test purpose

for port in $PORTS
do
	new=false
	mgr_port=$(( $port*10 + 1 ))
	echo =====================start server $port=================
	if ! [ -d $port ];then
		echo $port not exist, create it
		new=true
		mkdir $port
		cp mgr.template start.sh $port	
		sed -i 's/group_replication_local_address="127.0.0.1:.*"/group_replication_local_address="127.0.0.1:'$mgr_port'"/' $port/mgr.template
	fi
	cd $port
	sh start.sh mgr.template
	cd ..
	if [ $new = "true" ];then
		create_repl 127.0.0.1 $port
	fi

	start_group_replication 127.0.0.1 $port $first

	if [ $first = "yes" ];then
		echo setting first to no
		first=no
	fi

done

