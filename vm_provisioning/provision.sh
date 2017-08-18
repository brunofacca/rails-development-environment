#!/bin/bash
# Bash provisioning script for Vagrant

# ATTENTION: This script is run as root, there is no need to use "sudo" before any commands

# This script receives the following environment variables from the Vagrantfile
VM_SHARED_FOLDER=$VM_SHARED_FOLDER

SSH_PRIVATE_KEY=$SSH_PRIVATE_KEY
SSH_PUBLIC_KEY=$SSH_PUBLIC_KEY

GIT_HOST=$GIT_HOST
GIT_USER_FULL_NAME=$GIT_USER_FULL_NAME
GIT_USER_EMAIL=$GIT_USER_EMAIL

LINUX_USER=$LINUX_USER

LOCAL_POSTGRES_USERNAME=$LOCAL_POSTGRES_USERNAME
LOCAL_POSTGRES_PASSWORD=$LOCAL_POSTGRES_PASSWORD

LOCAL_MYSQL_PASSWORD=$LOCAL_MYSQL_PASSWORD

LOCALE=$LOCALE
TIME_ZONE=$TIME_ZONE

SELENIUM_SERVER_DOWNLOAD_URL=$SELENIUM_SERVER_DOWNLOAD_URL
CHROMEDRIVER_DOWNLOAD_URL=$CHROMEDRIVER_DOWNLOAD_URL

# -----------------------------------------------------------------------------

echo "Fixing 'sudo: unable to resolve host ubuntu-xenial' error"
if ! grep -q $(cat /etc/hostname) /etc/hosts; then
  echo >> /etc/hosts
  echo 127.0.0.1 $(cat /etc/hostname) >> /etc/hosts
fi

echo "Fixing 'stdin: is not a tty' error"
/bin/sed -i '/tty/!s/mesg n/tty -s \\&\\& mesg n/' /root/.profile
/bin/sed -i '/tty/!s/mesg n/tty -s \\&\\& mesg n/' /home/${LINUX_USER}/.profile

# Wait for the Vagrant shared folder to be mounted before executing the next commands
until [ -f ${VM_SHARED_FOLDER}/Vagrantfile ]; do
  echo "`date "+%Y-%m-%d %H:%M:%S"` - Waiting for VirtualBox shared folder (${VM_SHARED_FOLDER}) to be mounted..."
  sleep 1
done
echo "VirtualBox shared folder is mounted!"

echo "Updating O.S. packages. This may take several minutes depending on the speed of your internet connection."
# Update apt-get cache
sudo sudo apt-get update -q
# Upgrade distro packages
sudo apt-get upgrade -yq

# ------------------------ Configure Git for passwordless access -----------------------------

echo "Configuring SSH *client* (private key) for Git access without password"
cp ${VM_SHARED_FOLDER}/${SSH_PRIVATE_KEY} /home/${LINUX_USER}/.ssh/id_rsa
chown ${LINUX_USER}:${LINUX_USER} /home/${LINUX_USER}/.ssh/id_rsa
chmod 600 /home/${LINUX_USER}/.ssh/id_rsa
echo "IdentityFile /home/${LINUX_USER}/.ssh/id_rsa" >> /etc/ssh/ssh_config
# Disable RSA key checking that stops Git from being executed without user confirmation
echo -e "Host ${GIT_HOST}\n\tStrictHostKeyChecking no\n" >> /etc/ssh/ssh_config

# Install and configure Git
echo "Installing Git"
apt-get install -yq git

# Git user config
git config --global user.name ${GIT_USER_FULL_NAME}
git config --global user.email ${GIT_USER_EMAIL}

echo "Configuring SSH *server* (public key) for passwordless access to the guest VM".
cat ${VM_SHARED_FOLDER}/${SSH_PUBLIC_KEY} >> /home/${LINUX_USER}/.ssh/authorized_keys

# ------------------------ Install and configure MySQL  -----------------------------

# Keep in mind that MySQL comes with insecure default configurations, which
# should not be a problem in the development environment but are unsuited for
# production. It comes with a script called mysql_secure_installation (which
# we will not use here) to remove the insecure defaults.

# Unlike Postgres that does not come with any users, MySQL comes with a
# root user which we can use in the development environment
export DEBIAN_FRONTEND=noninteractive
debconf-set-selections <<< "mysql-server-5.7 mysql-server/root_password password ${LOCAL_MYSQL_PASSWORD}"
debconf-set-selections <<< "mysql-server-5.7 mysql-server/root_password_again password ${LOCAL_MYSQL_PASSWORD}"

apt-get install -y mysql-server-5.7 mysql-client libmysqlclient-dev

# Change bind-address from 127.0.0.1 to 0.0.0.0 so we can use desktop SQL
# clients for debugging purposes.
sed -i 's/127\.0\.0\.1/0\.0\.0\.0/g' /etc/mysql/mysql.conf.d/mysqld.cnf

# The socket file is created in the wrong place. Fix by creating a link.
ln -s /var/lib/mysql/mysql.sock /tmp/mysql.sock

systemctl restart mysql.service

# Allow the root user to connect remotely, so we can use an SQL client at our
# desktop to access the DB.
mysql -u root -plocaldbpass -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '${LOCAL_MYSQL_PASSWORD}';"

# ------------------------ Install and configure PostgresSQL -----------------------------

echo "Installing PostgreSQL"
apt-get install -y postgresql postgresql-contrib postgresql-server-dev-all

echo "Configuring PostgreSQL"
postgres_config_dir=/etc/postgresql/`ls /etc/postgresql`/main
# Allow local and remote connextions to the DB. Note that the host machine is
# considered "remote" by the vagrant VM.
# See https://www.postgresql.org/docs/current/static/auth-pg-hba-conf.html
# Note that we're overwriting the entire pg_hba.conf file
echo -e "\n# Added by provision.sh to allow the developer to use a desktop SQL client (e.g., pgAdmin) for debug purposes
# TYPE  DATABASE        USER            ADDRESS                 METHOD
host    all             all             0.0.0.0/0               md5
local   all             all                                     trust" > ${postgres_config_dir}/pg_hba.conf

echo "Creating project user and password in PostgreSQL"
sudo -u postgres psql -c "CREATE USER ${LOCAL_POSTGRES_USERNAME} WITH LOGIN PASSWORD '${LOCAL_POSTGRES_PASSWORD}';"
if [ $? -eq 0 ]; then
  echo "Sucessfully created PostgreSQL user called ${LOCAL_POSTGRES_USERNAME} with password ${LOCAL_POSTGRES_PASSWORD}"
fi

echo "Giving the DB user permission to create new databases (required for the rake db:create command to work)"
sudo -u postgres psql -c "ALTER USER ${LOCAL_POSTGRES_USERNAME} CREATEDB;"
if [ $? -eq 0 ]; then
  echo "Sucessfully given CREATEDB permission to PostgreSQL user called ${LOCAL_POSTGRES_USERNAME}"
fi

# Listen on all interfaces
sed -i "s/^.*listen_addresses.*$/listen_addresses = '*' # Listen on all NICs. Line changed by provision.sh/" ${postgres_config_dir}/postgresql.conf

# Restart postgres
service postgresql restart

# ---------------------- Install Elastic Beanstalk CLI -------------------------

echo "Installing Elastic Beanstalk CLI"

# Install Python and pip (required to install the EB CLI)
apt-get install -y python3 python3-dev python3-pip
# Upgrade pip
pip3 install --upgrade pip
# Instal EB CLI
pip3 install awsebcli

# ---------------------------- Install Heroku CLI -------------------------

sudo add-apt-repository "deb https://cli-assets.heroku.com/branches/stable/apt ./"
curl -L https://cli-assets.heroku.com/apt/release.key | sudo apt-key add -
sudo apt-get update
sudo apt-get install heroku

# -------------- Install Xvfb, Selenium, ChromeDriver and Chrome ---------------

echo "Installing Xvfb, Selenium, ChromeDriver and Google Chrome"

# Add Google public key to apt
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -

# Add Google to the apt-get source list
sudo sh -c 'echo deb http://dl.google.com/linux/chrome/deb/ stable main > /etc/apt/sources.list.d/google.list'
sudo apt-get update

# Install a JDK, Xvfb, Google Chrome and additional requirements
sudo apt-get install -y xvfb dbus-x11 google-chrome-stable default-jdk unzip

# Download Selenium Standalone Server
sudo wget --progress=bar:force "https://selenium-release.storage.googleapis.com/3.4/selenium-server-standalone-3.4.0.jar" -P /usr/local/bin/

# Download ChromeDriver
sudo wget --progress=bar:force "https://chromedriver.storage.googleapis.com/2.30/chromedriver_linux64.zip" -P /tmp/
sudo unzip /tmp/chromedriver_linux64.zip -d /usr/local/bin/

# Let all programs know in whuch display the Xvfb server is
echo "DISPLAY=\":1\"" >> /etc/environment

# Install the Xvfb init script
cp ${VM_SHARED_FOLDER}/vm_provisioning/xvfb_init_script.sh /etc/init.d/xvfb
chmod 755 /etc/init.d/xvfb
update-rc.d xvfb defaults
service xvfb start

# Install the Selenium init script
mkdir /var/run/selenium
chown $LINUX_USER:$LINUX_USER /var/run/selenium
cp ${VM_SHARED_FOLDER}/vm_provisioning/selenium_init_script.sh /etc/init.d/selenium
chmod 755 /etc/init.d/selenium
update-rc.d selenium defaults
service selenium start


# -------------------------------- Misc ----------------------------------------

echo "Setting locale"
locale-gen ${LOCALE}
update-locale LANG=${LOCALE}

echo "Setting time zone"
timedatectl set-timezone ${TIME_ZONE}

echo "Setting boot script (boot.sh) permissions."
chmod 755 ${VM_SHARED_FOLDER}/vm_provisioning/boot.sh

echo "Set up custom rc.local"
mv /etc/rc.local /etc/rc.local.OLD
# Copy this file (DO NOT link it), as the shared folder is not yet mounted when rc.local is executed
cp ${VM_SHARED_FOLDER}/vm_provisioning/custom_rc_local.sh /etc/rc.local

echo "Set up custom files in /etc/profile.d"
if [ -f ${VM_SHARED_FOLDER}/vm_provisioning/environment_variables.sh ]; then
  ln -s ${VM_SHARED_FOLDER}/vm_provisioning/environment_variables.sh /etc/profile.d/
fi
ln -s ${VM_SHARED_FOLDER}/vm_provisioning/bash_shortcuts.sh /etc/profile.d/
