#!/usr/bin/expect -f

set ip [lindex $argv 0];
set username [lindex $argv 1];
set passwd [lindex $argv 2];
set cmd  [lindex $argv 3];
set log_file [lindex $argv 4];


if { $log_file == "" } {
	set log_file "/tmp/log"
} 

set file [ open $log_file w ]

proc log {msg} {
    global file
    puts $file $msg
    flush $file
}

#log "--------------------------------$ip----------------------------------------"

log_file $log_file

spawn ssh $username@$ip

set timeout 1
expect {
	"continue" { send "yes\r" }
}
set timeout 5
expect {
	"assword:" { send "$passwd\r" }
}

expect {
	"~]\\$" { sleep 0.1; send "$cmd\r" }
}
set timeout 60
expect {
	"~]\\$" { send "exit\r" }
}

