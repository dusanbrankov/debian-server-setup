# Linux Server Setup

## Introduction

This is a guide to configure a server (unmanaged VPS) on Debian systems from scratch. It was originally intended to be used as a **reference for myself**, so please be aware that it is incomplete in places and may not be suitable for all use cases.

All the instructions are based on a new Linux system with **Debian 12 (Bookworm)** installed. If a different Debian release or distribution is used, some commands may be unavailable and will need to be installed or adapted.

## Setup

### Package Management

In addition to the networking and system administration packages, I also install extra packages for web development, such as PHP and MySQL. You can skip installing these if you don't need them.

```sh
apt update && apt dist-upgrade
apt install -y vim git sudo openssh-client openssh-server iptables fail2ban acl locales-all php-intl php-mbstring php-mysqli php-xml composer nodejs npm shellcheck mysql-server mysql-client
```

### User management

Add a user with low privileges for daily use and administration purposes. Later, we will be hardening shell access, so this user will be the only one with access to the server. The user will also be added to the 'systemd-journal' group, which will give them access to system logs without requiring root privileges.

```sh
useradd -m -G sudo,systemd-journal -s /bin/bash USERNAME
passwd USERNAME

# Add systemd user if needed (e.g. for running web apps as a service):
useradd --system --shell /bin/false SYS_USER
```

### System security

Firstly, let's switch to the user that we have just created:

```sh
su -l USERNAME
```

#### Configure SSH

```sh
mkdir ~/.ssh && chmod 700 $_
```

Generate an SSH key pair and add the public key to the server. This will allow us to log in to the server using public-key authentication.

```sh
ssh-keygen -t ed25519 -C "your@email.com"
```

Optionally, add the SSH key to the SSH agent to avoid having to enter the passphrase each time you connect to the GitHub server.

```sh
eval "$(ssh-agent -s)"
ssh-add .ssh/id_ed25519
ssh -T git@github.com
cat .ssh/id_ed25519.pub
```

Add the public key to your GitHub account.

You can follow the instructions in the [GitHub documentation](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account).


Copy SSH public key from local computer to server:

```sh
# Run this command on your local machine:
ssh-copy-id -i .ssh/id_ed25519.pub USERNAME@IP_ADDRESS
```

Now, let's restrict shell access by editing the `sshd_config` file. I prefer to back up the original file before making any changes, so that I can easily compare it with the modified file using the `diff` command.

```sh
sudo cp /etc/ssh/sshd_config{,.bak}
sudo vim /etc/ssh/sshd_config
sudo systemctl restart ssh
```

Here are the changes, I usually make to the `sshd_config` file:

```
Port 832 
PasswordAuthentication no
PermitEmptyPasswords no
UsePAM no
PermitRootLogin no
AllowUsers YOUR_USERNAME
```

Changing the default port is optional and does not necessarily make your server more secure, but it significantly reduces the number of automated login attempts, since bots are programmed to access the default SSH port 22.

#### Configure firewall

```sh
sudo ./firewall.rules.sh
```

> [!IMPORTANT]
> After running the script, keep your current session on the server alive and try logging in via SSH as USERNAME from your local machine!

### System settings

#### Set timezone

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

#### Set locale

Select the locale(s) you want to generate. At the end, you'll be asked which one should be the default. If you have users who access the system through ssh, it is recommended that you choose "None" as your default locale.

```sh
sudo dpkg-reconfigure locales
```

This changes `/etc/default/locale` and `/etc/locale.gen`.

Run `locale -a` to get a list of the locale names suitable for use in environment
variables. Note that the spellings are different from the ones presented in the
dpkg-reconfigure list.

Add a line like this to your `/etc/profile` file:

```sh
: "${LANG:=en_US.utf8}"; export LANG
```

References:

- https://wiki.debian.org/Locale
- https://wiki.archlinux.org/title/Locale

### Task automation

#### Automatic security updates

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

### Additional configuration

The following steps are optional and depend on your use case. For example, if you want to run a web server, you can install Apache and PHP, and configure them as needed.

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

This is an example of how to set up a daily backup of a MySQL database to Contabo Object Storage using the AWS CLI. I chose Contabo as my hosting provider, and the list of commands is very specific to their Object Storage service, but the general idea can be applied to any other cloud storage provider that supports S3-compatible APIs.

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
