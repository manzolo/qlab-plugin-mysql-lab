# mysql-lab — MySQL Database Lab

[![QLab Plugin](https://img.shields.io/badge/QLab-Plugin-blue)](https://github.com/manzolo/qlab)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Linux-lightgrey)](https://github.com/manzolo/qlab)

A [QLab](https://github.com/manzolo/qlab) plugin that boots a virtual machine with MySQL pre-installed, a sample database with test data, and port forwarding for host access.

## Objectives

- Learn how to connect to MySQL and explore databases
- Create databases, tables, and run SQL queries
- Manage users and permissions
- Perform backups and restores with mysqldump
- Access MySQL from the host via port forwarding

## How It Works

1. **Cloud image**: Downloads a minimal Ubuntu 22.04 cloud image (~250MB)
2. **Cloud-init**: Creates `user-data` with MySQL installation and sample data setup
3. **ISO generation**: Packs cloud-init files into a small ISO (cidata)
4. **Overlay disk**: Creates a COW disk on top of the base image (original stays untouched)
5. **QEMU boot**: Starts the VM in background with SSH and MySQL port forwarding

## Credentials

- **SSH Username:** `labuser`
- **SSH Password:** `labpass`
- **MySQL root:** `sudo mysql` (socket auth, no password)
- **MySQL labuser:** `labuser` / `labpass` (has privileges on `testdb`)

## Ports

| Service | Host Port | VM Port |
|---------|-----------|---------|
| SSH     | 2233      | 22      |
| MySQL   | 3307      | 3306    |

## Usage

```bash
# Install the plugin
qlab install mysql-lab

# Run the lab
qlab run mysql-lab

# Wait ~60s for boot and package installation, then:

# Connect via SSH
qlab shell mysql-lab

# Inside the VM:
sudo mysql                                 # connect as root
mysql -u labuser -plabpass testdb          # connect as labuser
SELECT * FROM users;                       # query sample data

# From the host (if mysql-client is installed):
mysql -h 127.0.0.1 -P 3307 -u labuser -plabpass testdb

# Stop the VM
qlab stop mysql-lab
```

## Exercises

1. **Explore the sample database**: Connect to MySQL and run `USE testdb; SHOW TABLES; SELECT * FROM users;`
2. **Create a new database**: Run `CREATE DATABASE mydb;` and create tables with different column types
3. **Manage users**: Create a new user with `CREATE USER`, grant specific privileges, and test access
4. **JOIN queries**: Write queries that join the `users` and `orders` tables
5. **Backup and restore**: Use `mysqldump testdb > backup.sql` to backup, drop a table, then restore with `mysql testdb < backup.sql`

## Resetting

To start fresh, stop and re-run:

```bash
qlab stop mysql-lab
qlab run mysql-lab
```

Or reset the entire workspace:

```bash
qlab reset
```
