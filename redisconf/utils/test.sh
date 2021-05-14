#!/usr/bin/expect -f

spawn telnet 127.0.0.1 6379
expect "Login: "
send "don\r"
expect "Password: " send "swordfish\r"
