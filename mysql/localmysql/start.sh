function getCurrentRealPath(){
    source="${BASH_SOURCE[0]}"
    while [ -h "$source" ]; do # resolve $source until the file is no longer a symlink
      dir="$( cd -P "$( dirname "$source" )" && pwd )"
      source="$(readlink "$source")"
      [[ $source != /* ]] && source="$dir/$source" # if $source was a relative symlink, we need to resolve it relative to the path where the symlink file was located
    done
    dir="$( cd -P "$( dirname "$source" )" && pwd )"
    echo $dir
}
function getPortFromPath(){
    path=$1
    match=`echo $path | perl -ne "/[0-9]{3,5}/ and print \"ok\""`
    if [ "$match" == "ok" ]; then
        port=`echo $path | perl -pe "s/.*?([0-9]{3,5}).*/\1/"`
    fi
    echo $port
}
function getPortFromPathOrDefault(){
    path=$1
    def=$2
    result=`getPortFromPath $path`
    if [ -z $result ];then
        result=$def
    fi
    echo $result
}


#VARS

MYSQL_PATH=`which mysql | xargs dirname | xargs dirname`
BASE=`getCurrentRealPath`
PORT=`getPortFromPathOrDefault $BASE 3308`
ROOT_PASS=root
TEMPLATE=$1
CONFIG=my.cnf

if [ -z $TEMPLATE ];then
	TEMPLATE=my.template
fi

echo "base dir:$BASE, port: $PORT, template: $TEMPLATE, mysql_path: $MYSQL_PATH"

cd $BASE
if ! [ -d data ];then
	echo not exist, create and initialize
	mkdir data
	mkdir basedir
	mkdir log
	mysqld --initialize --basedir=$BASE/basedir --datadir=$BASE/data > init.log 2>&1
	ROOT_PASS=`egrep -m 1 "temporary password"  init.log | awk '{print $NF}'`
	echo root password $ROOT_PASS
else 
	echo data dir already exists
fi

if [ -f $CONFIG ]; then
	echo my.cnf already exist
elif [ -f $TEMPLATE ];then
	echo $TEMPLATE exist
	sed 's#BASE#'$BASE'#g'  $TEMPLATE > $CONFIG
	sed -i 's#MYSQL_DIR#'$MYSQL_PATH'#g' $CONFIG 
else
	echo no my.cnf or $TEMPLATE exist, exit
	exit
fi

for pid in `ps -ef | egrep "mysql[d].*$PORT" | awk '{print $2}'`
do
	echo "killing pid $pid"
	kill -TERM $pid
	sleep 1
done

echo sleeping 2 seconds
sleep 2
mysqld --defaults-file="$BASE/$CONFIG" --port=$PORT > $BASE/startup.log 2>&1 &
sleep 3
echo all process list:
ps -ef | egrep "mysql[d].*$PORT" 

if [ $ROOT_PASS != "root" ];then
	echo --------change password to root
	mysql --socket mysql.sock --connect-expired-password  --host localhost -P$PORT -uroot -p''$ROOT_PASS'' << EOF
	SET PASSWORD FOR 'root'@'localhost' = PASSWORD('root');
	GRANT ALL ON *.* to root@'%' IDENTIFIED BY 'root';
	grant grant option on *.* to root@'%';
 	FLUSH PRIVILEGES;
EOF
fi
