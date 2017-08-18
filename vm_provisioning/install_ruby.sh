#!/bin/bash
# This script Install Ruby and Rails

# ATTENTION:
#   * This script is run as the ubuntu USER because installing RVM as root would
#   cause all sorts of problems.
#   * DO NOT prefix with "sudo" any commands related to RVM, Ruby or gem
#   installation. Only use sudo for apt-get and other "root only" commands.

# This script receives the following environment variables from the Vagrantfile
RAILS_VERSION=$RAILS_VERSION
# -----------------------------------------------------------------------------

echo "Installing curl"
# Install CURL (required to install RVM)
sudo apt-get install -yq curl >/dev/null

# USe RVM package for Ubuntu as it takes care of Ubuntu-specific details
# See https://github.com/rvm/ubuntu_rvm
sudo apt-get install -yq software-properties-common
sudo apt-add-repository -y ppa:rael-gc/rvm
sudo apt-get update
sudo apt-get install -yq rvm
rvm reload
rvm install ruby --quiet-curl

# Use the following if the RVM package for Ubuntu does not work
# RVM and Ruby installation commands from https://rvm.io/
#cd ~
#gpg --quiet --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 >/dev/null
#echo "Downloading RVM"
#curl -ssSL https://get.rvm.io > ~/rvm-install.sh
#echo "Installing RVM"
#bash ~/rvm-install.sh stable --quiet-curl
## Enable RVM (this is required, or else we could only use the Ruby installation
## after logging out and in again and most commands below this line would fail)
#source ~/.rvm/scripts/rvm
#echo "Installing the latest stable version of Ruby"
#rvm install ruby --quiet-curl
# There is no need to add [[ -s "$HOME/.rvm/scripts/rvm" ]] && source
# "$HOME/.rvm/scripts/rvm" to /home/ubuntu/.profile as RVM will automatically do
# that for us.

# Install Bundler (Ruby gem manager)
echo "Installing Bundler"
gem install bundler >/dev/null

# Require gems for remote debugging (via SSH) with RubyMine
gem install ruby-debug-ide debase

# Install Rails (without the docs)
echo "Installing Rails (this may take a few minutes)"
gem install rails -v ${RAILS_VERSION} --no-rdoc --no-ri

# Install Node.js (required by the uglifier gem, which is required by Rails)
echo "Installing Node.js (required by the uglifier gem, which is required by Rails)"
sudo apt-get install -y nodejs

RED='\e[1;31m%-6s\e[m\n'
printf ${RED} "ATTENTION: When installing gems, using RVM and performing other Ruby related tasks, ALWAYS use the `whoami` user, never use root."
