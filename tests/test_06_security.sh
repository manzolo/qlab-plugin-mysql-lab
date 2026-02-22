#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

echo ""
echo "${BOLD}Exercise 6 — Security and Configuration${RESET}"
echo ""

# Config files exist
assert "MySQL config directory exists" ssh_vm "test -d /etc/mysql"
assert "mysqld.cnf exists" ssh_vm "test -f /etc/mysql/mysql.conf.d/mysqld.cnf"

# Bind address
bind=$(ssh_vm "grep bind-address /etc/mysql/mysql.conf.d/mysqld.cnf | grep -v '^#'")
assert_contains "bind-address is configured" "$bind" "bind-address"

# Server variables
version=$(mysql_query "SELECT VERSION();")
assert_contains "Server version is queryable" "$version" "[0-9]"

max_conn=$(mysql_query "SHOW VARIABLES LIKE 'max_connections';" 2>/dev/null)
assert_contains "max_connections is queryable" "$max_conn" "max_connections"

# Process list
procs=$(mysql_query "SHOW PROCESSLIST;")
assert_contains "SHOW PROCESSLIST works" "$procs" "."

# Port 3306 is listening
ports=$(ssh_vm "sudo ss -tlnp | grep ':3306'")
assert_contains "MySQL port 3306 is listening" "$ports" ":3306"

report_results "Exercise 6"
