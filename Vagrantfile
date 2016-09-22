vagrant_dir = File.dirname(__FILE__) # Get Vagrantfile directory (full path)

# -------------------- Begin User Configurations ---------------------------

# Virtual Box command line tool path on the guest O.S.
vboxmanage = 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe'

# Define a name for the VM
vm_name = 'aws_eb_dev'

# Ammount of memory allocated to the VM in megabytes
vm_ram_mb = 1024

# Desired locale and TZ for the guest VM
locale="en_US.UTF-8"
time_zone="America/Sao_Paulo"

# Versions of Ruby and Rails to be installed on the guest VM
ruby_version="2.3.1"
rails_version="4.2.7"

# Nameservers which will be used by the guest VM
vm_nameserver1='8.8.8.8'
vm_nameserver2='8.8.4.4'

# Desired path for the VirtualBox shared folder within the host and the guest VM.
host_shared_folder = vagrant_dir
vm_shared_folder = '/projects'

# Linux user for which Ruby and Rails will be installed in the VM
linux_user="ubuntu"

# Git credentials and paths
git_host="github.com"
git_user_full_name="Bruno Facca"
git_user_email="bruno@facca.info"
git_local_dir="#{vm_shared_folder}/awake" # Should be a subdirectory of vm_shared_folder
git_repository_ssh_url="git@github.com:ivanlm/awake.git"

# PostgreSQL username and password which will be created on provisioning
local_postgres_username=linux_user  # Avoid 'FATAL: role "ubuntu" does not exist' error
local_postgres_password="testdbpass"

# SSH keys used to access the VM and your GitHub account.
# The paths should be relative to the VirtualBox shared folder, so they work on the
# host and on the guest VM. Remember to keep your SSH keys outside of Git.
ssh_private_key = "vm_provisioning/id_rsa"
ssh_public_key = "vm_provisioning/id_rsa.pub"

# -------------------- End User Configurations ---------------------------
# WARNING: Don't change anything below this point unless you know what you're doing
# Provisioning scripts path

# ------------------- Preliminary tests -------------------------

def check_vagrant_version
  # Vagrant versions up to 1.8.4 generate a "host not found" error in Ubuntu Xenial
  Vagrant.require_version ">= 1.8.5"
end

def check_plugins
  # Check if all needed Vagrant plugins are installed.

  # Vagrant plugins used in this Vagrantfile, separated by whitespace
  required_plugins = %w(vagrant-vbguest vagrant-triggers vagrant-reload)

  # Used plugins list (space as separator)
  missing_plugins = required_plugins.select { |plugin| not Vagrant.has_plugin? plugin }
  unless missing_plugins.empty?
    puts "Required plugins are not installed on the HOST machine #{missing_plugins.join(' ')} "
    puts "On the host machine command prompt, type: vagrant plugin install #{missing_plugins.join(' ')}"
    abort # Halt the provisioning process
  end
end

def enable_symlinks(vboxmanage)
	# Enable symlinks on VirtualBox shared folder (shell command ran on the HOST machine)
  system("#{vboxmanage} setextradata development VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant 1")
end

def check_ssh_keys(ssh_private_key, ssh_public_key)
	# Check if the SSH keys exist
	if File.exist?(ssh_private_key) && File.exist?(ssh_public_key)
		puts "\nThe private key used to access the guest VM and Git is: #{ssh_private_key}"
		puts "\nThe public key installed in the guest VM (which you should also upload to Git) is: #{ssh_public_key}"
	else
		puts 'Could not find the private and/or public SSH keys used to access the VM (via SSH) and your Git account.'
		abort # Halt the provisioning process
  end
end

def print_shared_folder_paths(host_shared_folder, vm_shared_folder)
	puts "\nThe shared folder at the host machine is: #{host_shared_folder}"
	puts "\nThe shared folder at the guest VM is: #{vm_shared_folder}\n\n"
end

# Execute specific actions when "vagrant up" or "vagrant provision" are run.
if (ARGV[0] == 'up') || (ARGV[0] == 'provision')
  check_vagrant_version
  check_plugins
  enable_symlinks(vboxmanage)
  check_ssh_keys("#{host_shared_folder}/#{ssh_private_key}", "#{host_shared_folder}/#{ssh_public_key}")
  print_shared_folder_paths(host_shared_folder, vm_shared_folder)
end

# ------------------- VM config and provisioning -------------------------
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/xenial64"
	
  # IMPORTANT: Rails binds to the 127.0.0.1 interface by default. 
  # To access it via forwarded port, run "rails s -b 0.0.0.0"
	config.vm.network "forwarded_port", guest: 3000, host: 3000 # HTTP
  config.vm.network "forwarded_port", guest: 5432, host: 5432 # PostgreSQL
	
	# VBox shared folder
  config.vm.synced_folder '.', vm_shared_folder, create: true

  # Do NOT try to upgrade guest additions automatically on boot
  config.vbguest.auto_update = false
	
	# VirtualBox provider config
  config.vm.provider "virtualbox" do |vbox|
    # VM name
    vbox.name = vm_name

    # Fix internet issue on guest VM
    vbox.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]

    # RAM allocated for guest VM
    vbox.memory = vm_ram_mb
  end

  # Use the "vagrant-triggers" plugin, which allows running command on the host, while
  # Vagrant's standard shell provisioner only allows running commands on the guest VM.
  # Usage:
  #   run "command"             executes command on the HOST
  #   run_remote "command"      executes command on the guest VM
  config.vm.provision "trigger", :stdout => true, :stderr => true do |trigger|
    trigger.fire do
      # Fix DNS issue that prevents the apt-get called by vagrant-vbguest (before the
      # provisioning script is run) from downloading stuff from archive.ubuntu.com
      run_remote "echo -e \"nameserver #{vm_nameserver1}\nnameserver #{vm_nameserver2}\" >> /etc/resolv.conf"
      # Update guest addons after fixing DNS issue
      run "vagrant vbguest"
      # Insert the VM shared folder path in rc.local. We are using "|" as a separator
      # instead of "/" so any slashes in the shared folder path are not interpreted as
      # separators.
      run_remote "sed -i \"s|^.*VM_SHARED_FOLDER_PLACEHOLDER.*$|export VM_SHARED_FOLDER=#{vm_shared_folder}|\" /etc/rc.local"
    end
  end

  # A reboot is required for the new guest additions to work
  config.vm.provision :reload

	# Run Shell provisioning script. "privileged: true" indicates it should be run AS ROOT
	config.vm.provision "shell",
    path: "#{host_shared_folder}/vm_provisioning/provision.sh",
    privileged: true,
    env: {
      'VM_SHARED_FOLDER' => vm_shared_folder,
      'GIT_HOST' => git_host,
      'GIT_USER_FULL_NAME' => git_user_full_name,
      'GIT_USER_EMAIL' => git_user_email,
      'GIT_LOCAL_DIR' => git_local_dir,
      'GIT_REPOSITORY_SSH_URL' => git_repository_ssh_url,
      'SSH_PRIVATE_KEY' => ssh_private_key,
      'SSH_PUBLIC_KEY' => ssh_public_key,
      'LINUX_USER' => linux_user,
      'LOCAL_POSTGRES_USERNAME' => local_postgres_username,
      'LOCAL_POSTGRES_PASSWORD' => local_postgres_password,
      'LOCALE' => locale,
      'TIME_ZONE' => time_zone
    }
	
	# Run script to install RVM, Bundle, Ruby and Rails. This is run as the ubuntu USER because 
	# installing RVM as root would cause all sorts of problems. 
	config.vm.provision "shell",
    path: "#{host_shared_folder}/vm_provisioning/install_ruby.sh",
    privileged: false,
    env: {
      'RUBY_VERSION' => ruby_version,
      'RAILS_VERSION' => rails_version
    }

	config.vm.provision "shell",
    inline: "echo -e '\e[1;32mProvisioning finished, your VM is ready. Happy coding!\e[m\n'"
	
end
