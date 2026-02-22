#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

echo ""
echo "${BOLD}Exercise 4 — Users and Privileges${RESET}"
echo ""

# Create read-only user
ssh_vm "sudo mysql -e \"CREATE USER IF NOT EXISTS 'reader'@'localhost' IDENTIFIED BY 'Reader123!'; GRANT SELECT ON testdb.* TO 'reader'@'localhost'; FLUSH PRIVILEGES;\"" >/dev/null

# reader can SELECT
read_result=$(ssh_vm "mysql -u reader -p'Reader123!' testdb -N -e 'SELECT COUNT(*) FROM users;'" 2>/dev/null)
assert_contains "Read-only user can SELECT" "$read_result" "[0-9]"

# reader cannot INSERT
insert_result=$(ssh_vm "mysql -u reader -p'Reader123!' testdb -e \"INSERT INTO users (name,email) VALUES ('hack','h@h');\" 2>&1") || true
assert_contains "Read-only user cannot INSERT" "$insert_result" "denied|ERROR"

# Drop user
ssh_vm "sudo mysql -e \"DROP USER IF EXISTS 'reader'@'localhost';\"" >/dev/null

report_results "Exercise 4"
