#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

echo ""
echo "${BOLD}Exercise 1 — MySQL Anatomy${RESET}"
echo ""

status=$(ssh_vm "systemctl is-active mysql")
assert_contains "MySQL service is active" "$status" "^active$"

dbs=$(mysql_query "SHOW DATABASES;")
assert_contains "testdb database exists" "$dbs" "testdb"

tables=$(mysql_query_db testdb "SHOW TABLES;")
assert_contains "users table exists" "$tables" "users"
assert_contains "orders table exists" "$tables" "orders"

version=$(mysql_query "SELECT VERSION();")
assert_contains "MySQL version is available" "$version" "[0-9]+\."

users_data=$(mysql_query_db testdb "SELECT COUNT(*) FROM users;")
assert_contains "users table has data" "$users_data" "[1-9]"

report_results "Exercise 1"
