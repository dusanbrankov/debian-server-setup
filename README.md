# Configuring a Debian server from scratch

## Introduction

This is a guide to configure a bare-metal Linux/Debian server from the ground. It covers measures to secure the server, install and configure commonly used software, and automate tasks such as running security updates.

It is intended to be used as a **reference for myself**, so please be aware that it is partly incomplete and may not be suitable for all use cases. It is *not* intended to be a comprehensive guide to server configuration, but rather a good starting point for further customization.

I also want to emphasize that I am not a security expert, and while I always try to give my best to follow best practices, I cannot guarantee that your server will be secure after following this guide.

Also, to keep the guide concise and easy to follow, I will not explain the given commands. If you are not familiar with a command, I recommend looking it up in the manual, instead of running them blindly.

## Prerequisites

This guide assumes that the reader has:

- a basic understanding of the GNU/Linux command line and Bash
- an unmanaged VPS or a physical server with a fresh Debian installation
- root access to the server via SSH

All the instructions are based on a new Linux system with **Debian 12 (Bookworm)** installed. If a different Debian release is used, some commands may not be available and need to be installed or adapted.

## Approach

### 1. Update and install packages

```sh
apt update && apt dist-upgrade
apt install -y vim git sudo iptables php-intl php-mbstring php-mysqli php-xml acl nodejs npm composer locales-all shellcheck mysql-server mysql-client
```

### 2. Add users

```sh
useradd -m -G sudo,systemd-journal -s /bin/bash USERNAME
passwd USERNAME

# Add systemd user:
useradd --system --shell /bin/false SYS_USER
```

### 3. Configure SSH and firewall

First, switch to the user we just created:

```sh
su -l USERNAME
```

#### SSH

```sh
mkdir ~/.ssh && chmod 700 $_
```

Generate SSH key and add it to the SSH agent:

```sh
ssh-keygen -t ed25519 -C "your@email.com"
eval "$(ssh-agent -s)"
ssh-add .ssh/id_ed25519
ssh -T git@github.com
cat .ssh/id_ed25519.pub  # add the key to your GitHub account
```

Copy SSH public key from local computer to server:

```sh
ssh-copy-id -i .ssh/id_ed25519.pub USERNAME@IP_ADDRESS
```

Now the `sshd_config` file can be changed:

```sh
sudo vim /etc/ssh/sshd_config # check original file with diff command
sudo systemctl restart ssh
```

#### Firewall

```sh
sudo ./firewall.rules.sh
```

> [!IMPORTANT]
> Keep session alive and try to log in as USERNAME from another terminal!

### 4. Set the system time

First, see what timezones are available with the `list-timezones` command:

```sh
timedatectl list-timezones
```

This will list the timezones available on your system. When you find the one that matches the location of your server, you can set it by using the `set-timezone` option:

```sh
sudo timedatectl set-timezone zone
```

To ensure that your machine is using the correct time now, use the timedatectl command alone, or with the status option. The display will be the same:

```sh
timedatectl status
```

Example output:

```
Local time: Fri 2021-07-09 14:44:30 EDT
Universal time: Fri 2021-07-09 18:44:30 UTC
RTC time: Fri 2021-07-09 18:44:31
Time zone: America/New_York (EDT, -0400)
System clock synchronized: yes
NTP service: active
RTC in local TZ: no
```

The first line should display the correct time.

### 5. Install unattended upgrades for automatic software updates

```sh
sudo apt update
sudo apt install unattended-upgrades apt-config-auto-update

# Configure
sudo vim /etc/apt/apt.conf.d/50unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades

# Apply changes by running
sudo unattended-upgrades --dry-run --debug
sudo unattended-upgrades

# Ensure that the apt configuration stub `/etc/apt/apt.conf.d/20auto-upgrades` contains at least the following lines:
#
#    APT::Periodic::Update-Package-Lists "1";
#    APT::Periodic::Unattended-Upgrade "1";

# If not, the file can be created by running
sudo dpkg-reconfigure -plow unattended-upgrades

# For more info, see https://wiki.debian.org/UnattendedUpgrades
# Log files: /var/log/unattended-upgrades

# Note on reboot
# If reboot didn't work, check the log files at /var/log/unattended-upgrades/unattended-upgrades-shutdown.log.
# In my case, I had to install a missing dependency 'python3-gi':
# 2025-12-17 10:59:28,942 WARNING - Unable to monitor PrepareForShutdown() signal, polling instead.
# 2025-12-17 10:59:28,943 WARNING - To enable monitoring the PrepareForShutdown() signal instead of polling please install the python3-gi package
```
---

### Optional steps

The following steps are optional and depend on your use case. For example, if you want to run a web server, you can install Apache and PHP, and configure them as needed. If you want to run a Node.js application, you can install Node.js and npm, and configure them as needed.

<details>
<summary>Configure Apache and PHP</summary>

```sh
sudo vim sites-available/000-default.conf
sudo apache2ctl configtest
sudo systemctl restart apache2.service

sudo vim /etc/php/8.2/fpm/php.ini

# Enable/uncomment the follwoing extensions:
extension=curl
extension=intl

sudo a2enmod rewrite
sudo a2enmod headers
sudo a2enmod proxy
sudo a2enmod proxy_http
```
</details>

<details>
<summary>Configure npm</summary>

##### Fix [`npm` permission issue](https://docs.npmjs.com/resolving-eacces-permissions-errors-when-installing-packages-globally)

```sh
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'

echo 'export PATH="$HOME"/.npm-global/bin:$PATH' >> ~/.profile
source ~/.profile
echo $PATH | grep npm
```
</details>

<details>
<summary>MySQL</summary>

##### Add database and user

```sh
mysql -u root -p < script.mysql
```

##### Import existing databases

```sh
# ON SOURCE SERVER:
# Export database:
mysqldump -u root -p DB_NAME > DB_NAME.data

# ON DEST SERVER:
# Create empty 'DB_NAME' database first
#
# Import database
mysql -u root -p DB_NAME < DB_NAME.data
```
</details>

<details>
<summary>Add systemd services to run web apps</summary>

```sh
# add systemd service file to /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable SERVICE_NAME.service
sudo systemctl start SERVICE_NAME.service
```
</details>

<details>
<summary>Install certbot</summary>

You can find the instructions inside [certbot.md](./certbot.md).
</details>

<details>
<summary>Contabo Object-Storage configuration</summary>

```sh
# Install awscli
# https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions
# https://contabo.com/blog/how-to-back-up-mysql-to-object-storage/
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
vim awscli_verify_pk # see link above for public key
gpg --import awscli_verify_pk
curl -o awscliv2.sig https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip.sig
gpg --verify awscliv2.sig awscliv2.zip
unzip awscliv2.zip
sudo ./aws/install
aws --version
aws configure --profile eu2
aws --profile eu2 --region default --endpoint-url https://eu2.contabostorage.com s3 ls

# Create script for database backup
touch db.backup.sh
chmod 744 db.backup.sh
vim db.backup.sh

# Create MySQL script for adding a user for backups
vim add-backup-user.sql
chmod 600 add-backup-user.sql
mysql -uroot -p < add-backup-user.sql

# For credentials MySQL will look for '.my.cnf' file
vim .my.cnf
chmod 600 .my.cnf

# Test if script is running correctly
shellcheck db.backup.sh
sudo ./db.backup.sh

# Schedule script to run daily
# Help: https://chatgpt.com/c/019cf127-2615-460d-b177-54fbb6b79b9f
sudo crontab -e
# Add the following line to run the script every day at 2:00 AM
# Redirecting ensures that no email notifications get sent
    0 2 * * * /home/dusan/db.backup.sh >/dev/null 2>&1
    # OR  0 2 * * * /home/dusan/db.backup.sh >/dev/null 2>>/var/log/db.backup.log
```
</details>
