#!/bin/bash
# This script Install Ruby and Rails 

# ATTENTION: 
#   * This script is run as the ubuntu USER because installing RVM as root would cause all sorts of problems. 
#   * DO NOT prefix with "sudo" any commands related to RVM, Ruby or gem installation. Only use sudo for 
#     apt-get and other "root only" commands.

# This script receives the following environment variables from the Vagrantfile
RUBY_VERSION=$RUBY_VERSION
RAILS_VERSION=$RAILS_VERSION
# -----------------------------------------------------------------------------

RUBY_VERSION_WITHOUT_TEENY=${RUBY_VERSION:0:-2} # Ruby version without the last part (e.g., 2.3)

echo "Installing curl"
# Install CURL (required to install RVM)
sudo apt-get install -yq curl >/dev/null

# RVM and Ruby installation commands from https://rvm.io/
cd ~
gpg --quiet --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 >/dev/null
echo "Downloading RVM"
curl -ssSL https://get.rvm.io > ~/rvm-install.sh
echo "Installing RVM"
bash ~/rvm-install.sh stable --quiet-curl
# Enable RVM (this is required, or else we could only use the Ruby installation after logging out and in
# again and most commands below this line would fail)
source ~/.rvm/scripts/rvm
echo "Installing Ruby"
rvm install ${RUBY_VERSION} --quiet-curl

# There is no need to add [[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" to /home/ubuntu/.profile
# as RVM will automatically do that for us.

# Create gemset to separate the gems installed below from all other gems
GEMSET_NAME=rails_${RAILS_VERSION}_gemset
rvm gemset create ${GEMSET_NAME}
rvm gemset use ${GEMSET_NAME}
echo -e "\nrvm gemset use ${GEMSET_NAME}" >> ~/.profile

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

# Install the awesome_print gem (used to pretty print JSON and other data formats)
gem install awesome_print

RED='\e[1;31m%-6s\e[m\n'
printf ${RED} "ATTENTION: When installing gems, using RVM and performing other Ruby related tasks, ALWAYS use the `whoami` user, never use root."
