#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

echo ""
echo "${BOLD}Exercise 3 — Data Manipulation${RESET}"
echo ""

# INSERT
mysql_query_db testdb "INSERT INTO users (name, email) VALUES ('TestUser', 'test@test.com');" >/dev/null
inserted=$(mysql_query_db testdb "SELECT name FROM users WHERE name='TestUser';")
assert_contains "INSERT adds a row" "$inserted" "TestUser"

# UPDATE
mysql_query_db testdb "UPDATE users SET email='updated@test.com' WHERE name='TestUser';" >/dev/null
updated=$(mysql_query_db testdb "SELECT email FROM users WHERE name='TestUser';")
assert_contains "UPDATE modifies data" "$updated" "updated@test.com"

# DELETE
mysql_query_db testdb "DELETE FROM users WHERE name='TestUser';" >/dev/null
deleted=$(mysql_query_db testdb "SELECT COUNT(*) FROM users WHERE name='TestUser';")
assert_contains "DELETE removes the row" "$deleted" "^0$"

# ROLLBACK
mysql_query_db testdb "BEGIN; INSERT INTO users (name, email) VALUES ('RollbackUser', 'rb@test.com'); ROLLBACK;" >/dev/null
rollback=$(mysql_query_db testdb "SELECT COUNT(*) FROM users WHERE name='RollbackUser';")
assert_contains "ROLLBACK undoes INSERT" "$rollback" "^0$"

# COMMIT
mysql_query_db testdb "BEGIN; INSERT INTO users (name, email) VALUES ('CommitUser', 'cm@test.com'); COMMIT;" >/dev/null
committed=$(mysql_query_db testdb "SELECT COUNT(*) FROM users WHERE name='CommitUser';")
assert_contains "COMMIT persists INSERT" "$committed" "^1$"

# Cleanup
mysql_query_db testdb "DELETE FROM users WHERE name IN ('TestUser','RollbackUser','CommitUser');" >/dev/null 2>&1

report_results "Exercise 3"
