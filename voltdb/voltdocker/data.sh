 docker exec -i node1 bash << EOF
sqlcmd < /data/table.sql
sqlcmd < /data/data.sql
EOF
