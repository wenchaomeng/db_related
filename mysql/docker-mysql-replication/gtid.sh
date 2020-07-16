MODE=on
if [ $1 == "off" ];then
	MODE=off
fi

echo =====$MODE

for file in `find . -name \*.cnf | egrep config`
do
	if egrep 'gtid_mode' $file; then
		echo gtid already exist $file
		if [ $MODE == 'off' ];then
			echo remove gtid
			sed -i '/gtid/d' $file
		fi
	else
		echo gtid not exist $file
		if [ $MODE == 'on' ];then
			echo "modify file:" $file
			sed -i '$agtid_mode=on'  $file
			sed -i '$aenforce-gtid-consistency=on'  $file
		fi
	fi
done
