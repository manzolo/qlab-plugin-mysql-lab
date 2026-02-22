# MySQL Lab — Step-by-Step Guide

This guide walks you through understanding and managing **MySQL** (MariaDB), the most popular open-source relational database. Databases are at the heart of almost every application — from websites to mobile apps to enterprise systems.

By the end of this lab you will understand SQL queries, data manipulation, user management, database administration, backups, and basic security practices.

## Prerequisites

Start the lab and wait for the VM to finish booting (~90 seconds):

```bash
qlab run mysql-lab
```

Connect to the VM:

```bash
qlab shell mysql-lab
```

Wait for cloud-init:

```bash
cloud-init status --wait
```

## Credentials

- **SSH:** `labuser` / `labpass`
- **MySQL:** `labuser` / `labpass` (full access to `testdb`)
- **MySQL root:** via `sudo mysql` (socket authentication)

## Ports

| Service | Host Port | VM Port |
|---------|-----------|---------|
| SSH     | dynamic   | 22      |
| MySQL   | dynamic   | 3306    |

---

## Exercise 01 — MySQL Anatomy

**VM:** mysql-lab
**Goal:** Understand how MySQL is structured.

MySQL organizes data in a hierarchy: the server contains databases, databases contain tables, tables contain rows and columns. Understanding this structure is the foundation for everything else.

### 1.1 Check MySQL is running

```bash
systemctl status mysql
```

### 1.2 Connect to MySQL

```bash
mysql -u labuser -plabpass
```

### 1.3 List databases

```sql
SHOW DATABASES;
```

**Expected output:**
```
+--------------------+
| Database           |
+--------------------+
| information_schema |
| testdb             |
+--------------------+
```

### 1.4 Select the test database

```sql
USE testdb;
SHOW TABLES;
```

**Expected output:**
```
+------------------+
| Tables_in_testdb |
+------------------+
| orders           |
| users            |
+------------------+
```

### 1.5 Describe table structure

```sql
DESCRIBE users;
DESCRIBE orders;
```

### 1.6 Check server status

```sql
SHOW STATUS LIKE 'Uptime';
SELECT VERSION();
```

Type `exit` to leave the MySQL prompt.

**Verification:** You can connect, see `testdb` with `users` and `orders` tables.

---

## Exercise 02 — SQL Queries

**VM:** mysql-lab
**Goal:** Write SELECT queries to retrieve and analyze data.

SQL (Structured Query Language) is the universal language for relational databases. Reading data efficiently is the most common database operation — before you can modify data, you need to find it.

### 2.1 View all users

```sql
USE testdb;
SELECT * FROM users;
```

### 2.2 Filter with WHERE

```sql
SELECT name, email FROM users WHERE id > 2;
```

### 2.3 Sort results

```sql
SELECT * FROM users ORDER BY name ASC;
SELECT * FROM users ORDER BY id DESC LIMIT 3;
```

### 2.4 Join tables

```sql
SELECT u.name, o.product, o.amount
FROM users u
JOIN orders o ON u.id = o.user_id;
```

This combines data from both tables — each order shown with the user's name.

### 2.5 Left Join (include users without orders)

```sql
SELECT u.name, COALESCE(o.product, 'No orders') AS product
FROM users u
LEFT JOIN orders o ON u.id = o.user_id;
```

### 2.6 Aggregate functions

```sql
SELECT COUNT(*) AS total_orders FROM orders;
SELECT SUM(amount) AS total_revenue FROM orders;
SELECT user_id, COUNT(*) AS order_count FROM orders GROUP BY user_id;
```

**Verification:** Queries return results from both tables, joins work, aggregates produce summaries.

---

## Exercise 03 — Data Manipulation

**VM:** mysql-lab
**Goal:** Insert, update, and delete data, and understand transactions.

Transactions ensure that a group of operations either all succeed or all fail — this is critical for data consistency. Imagine transferring money: you must debit one account AND credit another, never just one.

### 3.1 Insert a new user

```sql
USE testdb;
INSERT INTO users (name, email) VALUES ('Diana', 'diana@example.com');
SELECT * FROM users WHERE name = 'Diana';
```

### 3.2 Update a record

```sql
UPDATE users SET email = 'diana.new@example.com' WHERE name = 'Diana';
SELECT * FROM users WHERE name = 'Diana';
```

### 3.3 Delete a record

```sql
DELETE FROM users WHERE name = 'Diana';
SELECT * FROM users WHERE name = 'Diana';
```

Should return empty set.

### 3.4 Transactions — COMMIT

```sql
BEGIN;
INSERT INTO users (name, email) VALUES ('Eve', 'eve@example.com');
SELECT * FROM users WHERE name = 'Eve';  -- visible within transaction
COMMIT;
SELECT * FROM users WHERE name = 'Eve';  -- still visible after commit
```

### 3.5 Transactions — ROLLBACK

```sql
BEGIN;
INSERT INTO users (name, email) VALUES ('Frank', 'frank@example.com');
SELECT * FROM users WHERE name = 'Frank';  -- visible
ROLLBACK;
SELECT * FROM users WHERE name = 'Frank';  -- gone!
```

### 3.6 Clean up

```sql
DELETE FROM users WHERE name IN ('Eve', 'Frank', 'Diana');
```

**Verification:** INSERT adds rows, ROLLBACK undoes changes, COMMIT makes them permanent.

---

## Exercise 04 — Users and Privileges

**VM:** mysql-lab
**Goal:** Manage MySQL users and the principle of least privilege.

Every application should connect to the database with its own user that has only the permissions it needs. This limits the damage if the application is compromised.

### 4.1 Check current user

```sql
SELECT CURRENT_USER();
SHOW GRANTS;
```

### 4.2 Create a read-only user (as root)

```bash
sudo mysql
```

```sql
CREATE USER 'reader'@'localhost' IDENTIFIED BY 'Reader123!';
GRANT SELECT ON testdb.* TO 'reader'@'localhost';
FLUSH PRIVILEGES;
exit
```

### 4.3 Test the read-only user

```bash
mysql -u reader -p'Reader123!'
```

```sql
USE testdb;
SELECT * FROM users;  -- works
INSERT INTO users (name, email) VALUES ('Hacker', 'hack@evil.com');  -- ERROR!
exit
```

**Expected error:**
```
ERROR 1142 (42000): INSERT command denied to user 'reader'@'localhost'
```

### 4.4 Revoke and drop the user

```bash
sudo mysql
```

```sql
REVOKE ALL PRIVILEGES ON testdb.* FROM 'reader'@'localhost';
DROP USER 'reader'@'localhost';
exit
```

**Verification:** Read-only user can SELECT but not INSERT/UPDATE/DELETE.

---

## Exercise 05 — Database Administration

**VM:** mysql-lab
**Goal:** Create databases, modify tables, and perform backups.

### 5.1 Create a new database

```bash
mysql -u labuser -plabpass
```

```sql
CREATE DATABASE testlab;
USE testlab;
CREATE TABLE students (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    grade INT
);
INSERT INTO students (name, grade) VALUES ('Alice', 90), ('Bob', 85);
SELECT * FROM students;
```

### 5.2 Alter a table

```sql
ALTER TABLE students ADD COLUMN email VARCHAR(255);
DESCRIBE students;
```

### 5.3 Create an index

```sql
CREATE INDEX idx_name ON students(name);
SHOW INDEX FROM students;
```

### 5.4 Backup with mysqldump

```bash
# Exit MySQL first, then:
mysqldump -u labuser -plabpass testdb > /tmp/testdb_backup.sql
ls -la /tmp/testdb_backup.sql
head -20 /tmp/testdb_backup.sql
```

### 5.5 Restore from backup

```bash
mysql -u labuser -plabpass testlab < /tmp/testdb_backup.sql
```

### 5.6 Clean up

```bash
mysql -u labuser -plabpass -e "DROP DATABASE testlab;"
rm -f /tmp/testdb_backup.sql
```

**Verification:** Database creation, ALTER TABLE, indexes, and mysqldump all work.

---

## Exercise 06 — Security and Configuration

**VM:** mysql-lab
**Goal:** Understand MySQL configuration and security settings.

### 6.1 Find configuration files

```bash
ls /etc/mysql/
cat /etc/mysql/mysql.conf.d/mysqld.cnf | grep -v '^#' | grep -v '^$'
```

### 6.2 Check bind-address

```bash
grep bind-address /etc/mysql/mysql.conf.d/mysqld.cnf
```

**Expected output:**
```
bind-address = 0.0.0.0
```

This means MySQL accepts connections from any IP (needed for host access via port forwarding).

### 6.3 Check server variables

```bash
mysql -u labuser -plabpass -e "SHOW VARIABLES LIKE 'max_connections';"
mysql -u labuser -plabpass -e "SHOW VARIABLES LIKE 'version';"
```

### 6.4 Check process list

```bash
mysql -u labuser -plabpass -e "SHOW PROCESSLIST;"
```

### 6.5 Check error log location

```bash
mysql -u labuser -plabpass -e "SHOW VARIABLES LIKE 'log_error';"
```

**Verification:** Configuration files exist, bind-address is set, server variables are queryable.

---

## Troubleshooting

### Can't connect to MySQL
```bash
systemctl status mysql
sudo journalctl -u mysql --no-pager -n 20
```

### Access denied
```bash
# Try as root via socket
sudo mysql
# Check grants
SHOW GRANTS FOR 'labuser'@'localhost';
```

### Table doesn't exist
```sql
USE testdb;
SHOW TABLES;
```

### Packages not installed
```bash
cloud-init status --wait
```
