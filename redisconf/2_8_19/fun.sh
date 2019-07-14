function makedir(){

    if [ ! -d $1 ]; then
        echo "log dir not exist, create it"
        mkdir $1
    fi
}

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



function getPort(){
    path=$1
    match=`echo $path | perl -ne "/_[0-9]{3,5}|redis.*[0-9]{3,5}/ and print \"ok\""`
    if [ "$match" == "ok" ]; then
	    port=`echo $path | perl -pe "s/.*?([0-9]{3,5}).*/\1/"`
    fi
    echo $port
}

function redis(){
	ip=$1
	port=$2
	cmd=$3
	redis-cli -h $ip -p $port << EOF
	$cmd	
EOF
	
}

function redisVersion(){
	ip=$1
	port=$2
	version=`redis-cli -h $ip -p $port << EOF | grep redis_version | grep -v xredis
	info server
EOF`
	version=`echo $version | awk -F":" '{print $2}'`
	echo $version
}

function setProtectedMode(){
	ip=$1
	port=$2
	version=`redisVersion $ip $port`

        if [[ $version =~ ^4.* ]] ;then
                echo set protected mode no
		redis-cli -h $ip -p $port << EOF
		config set protected-mode no
		config rewrite
EOF
fi
}

function test(){
	echo `getPort _6379`
	echo `getPort xredis/conf6379`
	echo `getPort a_6379b`
	echo `getPort a_6379b/.`
	echo `getPort _63791`
	echo `getPort a_63791b`
	echo `getPort a_63791b/.`
	echo `getPort /a/b/.`
	echo `getCurrentRealPath`
}
