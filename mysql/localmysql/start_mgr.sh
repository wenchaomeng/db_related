
mysql -uroot -proot --host 127.0.0.1 --port 4306  -An << EOF
	CREATE USER 'repl'@'%' IDENTIFIED BY 'repl';
	GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';
	FLUSH PRIVILEGES;
EOF


