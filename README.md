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
| SSH     | dynamic   | 22      |
| MySQL   | dynamic   | 3306    |

> All host ports are dynamically allocated. Use `qlab ports` to see the actual mappings.

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

# From the host (check MySQL port with 'qlab ports'):
mysql -h 127.0.0.1 -P <mysql_port> -u labuser -plabpass testdb

# Stop the VM
qlab stop mysql-lab
```

## Exercises

> **New to MySQL?** See the [Step-by-Step Guide](guide.md) for complete walkthroughs with full SQL examples.

| # | Exercise | What you'll do |
|---|----------|----------------|
| 1 | **MySQL Anatomy** | Explore MySQL installation, connect, and navigate databases |
| 2 | **SQL Queries** | Run SELECT, WHERE, ORDER BY, JOIN on sample data |
| 3 | **Data Manipulation** | INSERT, UPDATE, DELETE rows and manage tables |
| 4 | **Users and Privileges** | Create users, GRANT/REVOKE permissions |
| 5 | **Database Administration** | Backup with mysqldump, restore, check status |
| 6 | **Security and Configuration** | Review bind-address, authentication, and logging |

## Automated Tests

An automated test suite validates the exercises against a running VM:

```bash
# Start the lab first
qlab run mysql-lab
# Wait ~60s for cloud-init, then run all tests
qlab test mysql-lab
```

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
