#!/usr/bin/env bash
# mysql-lab run script — boots a VM with MySQL/MariaDB for database practice

set -euo pipefail

PLUGIN_NAME="mysql-lab"

echo "============================================="
echo "  mysql-lab: MySQL Database Lab"
echo "============================================="
echo ""
echo "  This lab demonstrates:"
echo "    1. Provisioning MySQL via cloud-init"
echo "    2. Creating databases, tables, and queries"
echo "    3. Managing users and permissions"
echo "    4. Performing backups and restores with mysqldump"
echo "    5. Managing databases visually with phpMyAdmin"
echo ""

# Source QLab core libraries
if [[ -z "${QLAB_ROOT:-}" ]]; then
    echo "ERROR: QLAB_ROOT not set. Run this plugin via 'qlab run ${PLUGIN_NAME}'."
    exit 1
fi

for lib_file in "$QLAB_ROOT"/lib/*.bash; do
    # shellcheck source=/dev/null
    [[ -f "$lib_file" ]] && source "$lib_file"
done

# Configuration
WORKSPACE_DIR="${WORKSPACE_DIR:-.qlab}"
LAB_DIR="lab"
IMAGE_DIR="$WORKSPACE_DIR/images"
CLOUD_IMAGE_URL=$(get_config CLOUD_IMAGE_URL "https://cloud-images.ubuntu.com/minimal/releases/jammy/release/ubuntu-22.04-minimal-cloudimg-amd64.img")
CLOUD_IMAGE_FILE="$IMAGE_DIR/ubuntu-22.04-minimal-cloudimg-amd64.img"
MEMORY="${QLAB_MEMORY:-$(get_config DEFAULT_MEMORY 2048)}"

# Ensure directories exist
mkdir -p "$LAB_DIR" "$IMAGE_DIR"

# Step 1: Download cloud image if not present
# Cloud images are pre-built OS images designed for cloud environments.
# They are minimal and expect cloud-init to configure them on first boot.
info "Step 1: Cloud image"
if [[ -f "$CLOUD_IMAGE_FILE" ]]; then
    success "Cloud image already downloaded: $CLOUD_IMAGE_FILE"
else
    echo ""
    echo "  Cloud images are pre-built OS images designed for cloud environments."
    echo "  They are minimal and expect cloud-init to configure them on first boot."
    echo ""
    info "Downloading Ubuntu cloud image..."
    echo "  URL: $CLOUD_IMAGE_URL"
    echo "  This may take a few minutes depending on your connection."
    echo ""
    check_dependency curl || exit 1
    curl -L -o "$CLOUD_IMAGE_FILE" "$CLOUD_IMAGE_URL" || {
        error "Failed to download cloud image."
        echo "  Check your internet connection and try again."
        exit 1
    }
    success "Cloud image downloaded: $CLOUD_IMAGE_FILE"
fi
echo ""

# Step 2: Create cloud-init configuration
# cloud-init reads user-data to configure the VM on first boot:
#   - creates users, installs packages, writes config files, runs commands
info "Step 2: Cloud-init configuration"
echo ""
echo "  cloud-init will:"
echo "    - Create a user 'labuser' with SSH access"
echo "    - Install mysql-server, mysql-client, and phpMyAdmin"
echo "    - Create a sample database with test data"
echo "    - Create a MySQL 'labuser' with privileges on the test DB"
echo "    - Configure phpMyAdmin for web-based database management"
echo ""

cat > "$LAB_DIR/user-data" <<'USERDATA'
#cloud-config
hostname: mysql-lab
package_update: true
users:
  - name: labuser
    plain_text_passwd: labpass
    lock_passwd: false
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - "__QLAB_SSH_PUB_KEY__"
ssh_pwauth: true
debconf_selections: |
  phpmyadmin phpmyadmin/dbconfig-install boolean true
  phpmyadmin phpmyadmin/mysql/admin-pass password
  phpmyadmin phpmyadmin/mysql/app-pass password labpass
  phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2
packages:
  - mysql-server
  - mysql-client
  - apache2
  - php
  - php-mysql
  - php-mbstring
  - php-zip
  - php-gd
  - php-curl
  - phpmyadmin
  - curl
write_files:
  - path: /etc/profile.d/cloud-init-status.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      if command -v cloud-init >/dev/null 2>&1; then
        status=$(cloud-init status 2>/dev/null)
        if echo "$status" | grep -q "running"; then
          printf '\033[1;33m'
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "  Cloud-init is still running..."
          echo "  Some packages and services may not be ready yet."
          echo "  Run 'cloud-init status --wait' to wait for completion."
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          printf '\033[0m\n'
        fi
      fi
  - path: /etc/motd.raw
    content: |
      \033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m
        \033[1;32mmysql-lab\033[0m — \033[1mMySQL Database Lab\033[0m
      \033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m

        \033[1;33mObjectives:\033[0m
          • connect to MySQL and explore databases
          • create databases, tables, and run queries
          • manage users and permissions
          • perform backups and restores
          • use phpMyAdmin for visual database management

        \033[1;33mMySQL Commands:\033[0m
          \033[0;32msudo mysql\033[0m                        connect as root
          \033[0;32mmysql -u labuser -plabpass testdb\033[0m connect as labuser
          \033[0;32msudo systemctl status mysql\033[0m       service status

        \033[1;33mSample Database:\033[0m
          \033[0;32mUSE testdb;\033[0m
          \033[0;32mSHOW TABLES;\033[0m
          \033[0;32mSELECT * FROM users;\033[0m

        \033[1;33mBackup & Restore:\033[0m
          \033[0;32msudo mysqldump testdb > backup.sql\033[0m
          \033[0;32msudo mysql testdb < backup.sql\033[0m

        \033[1;33mphpMyAdmin (web interface):\033[0m
          Inside VM:  \033[0;32mhttp://localhost/phpmyadmin\033[0m
          From host:  \033[0;32mhttp://localhost:<HTTP_PORT>/phpmyadmin\033[0m
          Login:      \033[1;36mlabuser\033[0m / \033[1;36mlabpass\033[0m

        \033[1;33mFrom the host:\033[0m  run \033[0;32mqlab ports\033[0m to see port numbers
          MySQL:      \033[0;32mmysql -h 127.0.0.1 -P <MYSQL_PORT> -u labuser -plabpass testdb\033[0m
          phpMyAdmin: \033[0;32mhttp://localhost:<HTTP_PORT>/phpmyadmin\033[0m

        \033[1;33mCredentials:\033[0m  \033[1;36mlabuser\033[0m / \033[1;36mlabpass\033[0m
        \033[1;33mExit:\033[0m         type '\033[1;31mexit\033[0m'

      \033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m


  - path: /home/labuser/sample_data.sql
    permissions: '0644'
    content: |
      CREATE TABLE IF NOT EXISTS users (
          id INT AUTO_INCREMENT PRIMARY KEY,
          name VARCHAR(50) NOT NULL,
          email VARCHAR(100),
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
      INSERT INTO users (name, email) VALUES
          ('Alice', 'alice@example.com'),
          ('Bob', 'bob@example.com'),
          ('Charlie', 'charlie@example.com');

      CREATE TABLE IF NOT EXISTS orders (
          id INT AUTO_INCREMENT PRIMARY KEY,
          user_id INT NOT NULL,
          product VARCHAR(100) NOT NULL,
          amount DECIMAL(10,2),
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users(id)
      );
      INSERT INTO orders (user_id, product, amount) VALUES
          (1, 'Laptop', 999.99),
          (2, 'Mouse', 29.99),
          (1, 'Keyboard', 79.99),
          (3, 'Monitor', 349.99);
runcmd:
  - chmod -x /etc/update-motd.d/*
  - sed -i 's/^#\?PrintMotd.*/PrintMotd yes/' /etc/ssh/sshd_config
  - sed -i 's/^session.*pam_motd.*/# &/' /etc/pam.d/sshd
  - printf '%b\n' "$(cat /etc/motd.raw)" > /etc/motd
  - rm -f /etc/motd.raw
  - systemctl restart sshd
  - sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
  - systemctl restart mysql
  - mysql -u root -e "CREATE DATABASE IF NOT EXISTS testdb;"
  - mysql -u root -e "CREATE USER IF NOT EXISTS 'labuser'@'localhost' IDENTIFIED BY 'labpass';"
  - mysql -u root -e "CREATE USER IF NOT EXISTS 'labuser'@'%' IDENTIFIED BY 'labpass';"
  - mysql -u root -e "GRANT ALL PRIVILEGES ON testdb.* TO 'labuser'@'localhost';"
  - mysql -u root -e "GRANT ALL PRIVILEGES ON testdb.* TO 'labuser'@'%';"
  - mysql -u root -e "FLUSH PRIVILEGES;"
  - mysql -u root testdb < /home/labuser/sample_data.sql
  - mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'labuser'@'localhost' WITH GRANT OPTION;"
  - mysql -u root -e "FLUSH PRIVILEGES;"
  - ln -sf /usr/share/phpmyadmin /var/www/html/phpmyadmin
  - phpenmod mbstring
  - systemctl restart apache2
  - chown -R labuser:labuser /home/labuser
  - echo "=== mysql-lab VM is ready! ==="
USERDATA

# Inject the SSH public key into user-data
sed -i "s|__QLAB_SSH_PUB_KEY__|${QLAB_SSH_PUB_KEY:-}|g" "$LAB_DIR/user-data"

cat > "$LAB_DIR/meta-data" <<METADATA
instance-id: ${PLUGIN_NAME}-001
local-hostname: ${PLUGIN_NAME}
METADATA

success "Created cloud-init files in $LAB_DIR/"
echo ""

# Step 3: Generate cloud-init ISO
# QEMU reads cloud-init data from a small ISO image (CD-ROM).
# We use genisoimage to create it with the 'cidata' volume label.
info "Step 3: Cloud-init ISO"
echo ""
echo "  QEMU reads cloud-init data from a small ISO image (CD-ROM)."
echo "  We use genisoimage to create it with the 'cidata' volume label."
echo ""

CIDATA_ISO="$LAB_DIR/cidata.iso"
check_dependency genisoimage || {
    warn "genisoimage not found. Install it with: sudo apt install genisoimage"
    exit 1
}
genisoimage -output "$CIDATA_ISO" -volid cidata -joliet -rock \
    "$LAB_DIR/user-data" "$LAB_DIR/meta-data" 2>/dev/null
success "Created cloud-init ISO: $CIDATA_ISO"
echo ""

# Step 4: Create overlay disk
# An overlay disk uses copy-on-write (COW) on top of the base image.
# The original cloud image stays untouched; all writes go to the overlay.
info "Step 4: Overlay disk"
echo ""
echo "  An overlay disk uses copy-on-write (COW) on top of the base image."
echo "  This means:"
echo "    - The original cloud image stays untouched"
echo "    - All writes go to the overlay file"
echo "    - You can reset the lab by deleting the overlay"
echo ""

OVERLAY_DISK="$LAB_DIR/${PLUGIN_NAME}-disk.qcow2"
if [[ -f "$OVERLAY_DISK" ]]; then
    info "Removing previous overlay disk..."
    rm -f "$OVERLAY_DISK"
fi
create_overlay "$CLOUD_IMAGE_FILE" "$OVERLAY_DISK" "${QLAB_DISK_SIZE:-6G}" || {
    error "Failed to create overlay disk."
    exit 1
}
echo ""

# Step 5: Boot the VM in background with MySQL port forwarding
info "Step 5: Starting VM in background"
echo ""
echo "  The VM will run in background with:"
echo "    - Serial output logged to .qlab/logs/$PLUGIN_NAME.log"
echo "    - SSH access on a dynamically allocated port"
echo "    - MySQL access on a dynamically allocated port (forwarded to VM port 3306)"
echo "    - phpMyAdmin (HTTP) on a dynamically allocated port (forwarded to VM port 80)"
echo ""

start_vm "$OVERLAY_DISK" "$CIDATA_ISO" "$MEMORY" "$PLUGIN_NAME" auto \
    "hostfwd=tcp::0-:3306" \
    "hostfwd=tcp::0-:80"

# Read the dynamically allocated ports from .ports file
MYSQL_PORT=""
PMA_PORT=""
if [[ -f "$STATE_DIR/${PLUGIN_NAME}.ports" ]]; then
    MYSQL_PORT=$(grep ':3306$' "$STATE_DIR/${PLUGIN_NAME}.ports" | head -1 | cut -d: -f2)
    PMA_PORT=$(grep ':80$' "$STATE_DIR/${PLUGIN_NAME}.ports" | head -1 | cut -d: -f2)
fi

echo ""
echo "============================================="
echo "  mysql-lab: VM is booting"
echo "============================================="
echo ""
echo "  Credentials: labuser / labpass"
echo ""
echo "  SSH (wait ~60s for boot + package install):"
echo "    qlab shell ${PLUGIN_NAME}"
echo ""
echo "  MySQL (after boot completes):"
echo "    Inside VM:  sudo mysql"
if [[ -n "$MYSQL_PORT" ]]; then
echo "    From host:  mysql -h 127.0.0.1 -P ${MYSQL_PORT} -u labuser -plabpass testdb"
else
echo "    From host:  mysql -h 127.0.0.1 -P <port> -u labuser -plabpass testdb"
fi
echo ""
echo "  ---------------------------------------------"
echo "  phpMyAdmin (web interface):"
if [[ -n "$PMA_PORT" ]]; then
echo "    URL:   http://localhost:${PMA_PORT}/phpmyadmin"
else
echo "    URL:   http://localhost:<port>/phpmyadmin"
fi
echo "    Login: labuser / labpass"
echo "  ---------------------------------------------"
echo ""
echo "  Active ports:  qlab ports"
echo "  View boot log: qlab log ${PLUGIN_NAME}"
echo "  Stop VM:       qlab stop ${PLUGIN_NAME}"
echo ""
echo "  Tip: QLAB_MEMORY=4096 QLAB_DISK_SIZE=30G qlab run ${PLUGIN_NAME}"
echo "============================================="
