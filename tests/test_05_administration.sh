#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

echo ""
echo "${BOLD}Exercise 5 — Database Administration${RESET}"
echo ""

# Create database and table (use sudo mysql for admin operations)
ssh_vm "sudo mysql -e 'CREATE DATABASE IF NOT EXISTS testlab;'" >/dev/null
ssh_vm "sudo mysql -e 'GRANT ALL ON testlab.* TO \"labuser\"@\"localhost\";'" >/dev/null
mysql_query_db testlab "CREATE TABLE IF NOT EXISTS students (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(100), grade INT);" >/dev/null
mysql_query_db testlab "INSERT INTO students (name, grade) VALUES ('Alice', 90);" >/dev/null

created=$(mysql_query "SHOW DATABASES LIKE 'testlab';")
assert_contains "Database testlab created" "$created" "testlab"

data=$(mysql_query_db testlab "SELECT name FROM students;")
assert_contains "Table has data" "$data" "Alice"

# ALTER TABLE
mysql_query_db testlab "ALTER TABLE students ADD COLUMN email VARCHAR(255);" >/dev/null
columns=$(mysql_query_db testlab "DESCRIBE students;")
assert_contains "ALTER TABLE added email column" "$columns" "email"

# INDEX
mysql_query_db testlab "CREATE INDEX idx_name ON students(name);" >/dev/null 2>&1 || true
indexes=$(mysql_query_db testlab "SHOW INDEX FROM students;")
assert_contains "Index created" "$indexes" "idx_name"

# mysqldump
assert "mysqldump works" ssh_vm "mysqldump -u labuser -plabpass testdb > /tmp/testdb_backup.sql"
assert "Backup file exists" ssh_vm "test -s /tmp/testdb_backup.sql"

# Cleanup
ssh_vm "sudo mysql -e 'DROP DATABASE IF EXISTS testlab;'" >/dev/null
ssh_vm "rm -f /tmp/testdb_backup.sql" >/dev/null

report_results "Exercise 5"
