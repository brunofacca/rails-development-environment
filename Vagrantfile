# Get Vagrantfile directory (full path)
HOST_VAGRANT_DIR = File.dirname(__FILE__)

# -------------------- Begin User Configurations ---------------------------

# Virtual Box command line tool path on the guest O.S.
VBOXMANAGE_PATH = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"

# Define a name for the VM
VM_NAME = "rails_dev"

# Amount of memory allocated to the VM in megabytes
VM_RAM_MB = 1024

# Nameservers which will be used by the guest VM
VM_NAMESERVER1 = "8.8.8.8"
VM_NAMESERVER2 = "8.8.4.4"

# Desired path for the VirtualBox shared folder within the host and VM
HOST_SHARED_FOLDER = HOST_VAGRANT_DIR 
VM_SHARED_FOLDER = "/projects"

# SSH keys used to access the VM and your GitHub account.
# The paths should be relative to the VirtualBox shared folder, so they work on
# the host and on the guest VM. Remember to keep your SSH keys outside of Git.
SSH_PRIVATE_KEY = "vm_provisioning/id_rsa"
SSH_PUBLIC_KEY = "vm_provisioning/id_rsa.pub"

ROOT_PROVISIONING_OPTIONS = {
  # Desired path for the VirtualBox shared folder within the VM
  "VM_SHARED_FOLDER" => VM_SHARED_FOLDER,

  # Git credentials and paths
  "GIT_HOST" => "github.com",
  "GIT_USER_FULL_NAME" => "Bruno Facca",
  "GIT_USER_EMAIL" => "bruno@facca.info",

  # Should be a subdirectory of VM_SHARED_FOLDER
  "GIT_LOCAL_DIR" => "#{VM_SHARED_FOLDER}/awake",
  "GIT_REPOSITORY_SSH_URL" => "git@github.com:ivanlm/awake.git",
  "SSH_PRIVATE_KEY" => SSH_PRIVATE_KEY,
  "SSH_PUBLIC_KEY" => SSH_PUBLIC_KEY,

  # Linux user for which Ruby and Rails will be installed in the VM
  "LINUX_USER" => "ubuntu",

  # PostgreSQL username and password which will be created on provisioning
  "LOCAL_POSTGRES_USERNAME" => "LINUX_USER",
  "LOCAL_POSTGRES_PASSWORD" => "testdbpass",

  # Desired locale and TZ for the guest VM
  "LOCALE" => "en_US.UTF-8",
  "TIME_ZONE" => "America/Sao_Paulo",

  # Download URLs for the Selenium server and ChromeDriver
  "CHROMEDRIVER_DOWNLOAD_URL" => "https://chromedriver.storage.googleapis.com/2.30/chromedriver_linux64.zip",
  "SELENIUM_SERVER_DOWNLOAD_URL" => "https://selenium-release.storage.googleapis.com/3.4/selenium-server-standalone-3.4.0.jar",
}

# Versions of Ruby and Rails to be installed on the guest VM
USER_PROVISIONING_OPTIONS = {
  "RUBY_VERSION" => "2.3.1",
  "RAILS_VERSION" => "4.2.7"
}

# -------------------- End Of User Configurations ---------------------------
# WARNING: Don't change anything below this point unless you know what you're
# doing

def check_vagrant_version
  # Vagrant versions up to 1.8.4 generate a "host not found" error in Ubuntu
  # Xenial
  Vagrant.require_version ">= 1.8.5"
end

# Check if all needed Vagrant plugins are installed.
def check_plugins
  required_plugins = %w(vagrant-vbguest vagrant-triggers vagrant-reload)

  missing_plugins = required_plugins.reject do |plugin|
    Vagrant.has_plugin? plugin
  end.join(" ")

  unless missing_plugins.empty?
    puts "The following required plugins are not installed on the HOST " \
         "machine#{missing_plugins} "
    puts "On the host machine command prompt, type: vagrant plugin install " +
         missing_plugins
    # Halt the provisioning process
    abort
  end
end

def enable_symlinks(vboxmanage)
  # Enable symlinks on VirtualBox shared folder. The shell command is
  # executed on the HOST machine.
  system("#{vboxmanage} setextradata development " \
         "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant 1")
end

def check_ssh_keys(ssh_private_key, ssh_public_key)
  # Check if the SSH keys exist
  if File.exist?(ssh_private_key) && File.exist?(ssh_public_key)
    puts "\nThe private key used to access the guest VM and Git is: " +
         ssh_private_key
    puts "\nThe public key installed in the guest VM (which you should also " \
         "upload to Git) is: #{ssh_public_key}"
  else
    puts "Could not find the private and/or public SSH keys used to access " \
         "the VM (via SSH) and your Git account."
    # Halt the provisioning process
    abort
  end
end

def print_shared_folder_paths(host_shared_folder, vm_shared_folder)
  puts "\nThe shared folder at the host machine is: #{host_shared_folder}"
  puts "\nThe shared folder at the guest VM is: #{vm_shared_folder}\n\n"
end

# Execute specific actions when "vagrant up" or "vagrant provision" are run.
if (ARGV[0] == "up") || (ARGV[0] == "provision")
  check_vagrant_version
  check_plugins
  enable_symlinks(VBOXMANAGE_PATH)
  check_ssh_keys("#{HOST_SHARED_FOLDER}/#{SSH_PRIVATE_KEY}",
                 "#{HOST_SHARED_FOLDER}/#{SSH_PUBLIC_KEY}")
  print_shared_folder_paths(HOST_SHARED_FOLDER, VM_SHARED_FOLDER)
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
  config.vm.synced_folder ".", VM_SHARED_FOLDER, create: true

  # Do NOT try to upgrade guest additions automatically on boot
  config.vbguest.auto_update = false

  # VirtualBox provider config
  config.vm.provider "virtualbox" do |vbox|
    # VM name
    vbox.name = VM_NAME

    # Fix internet issue on guest VM
    vbox.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]

    # RAM allocated for guest VM
    vbox.memory = VM_RAM_MB
  end

  # Use the "vagrant-triggers" plugin, which allows running command on the host,
  # while Vagrant's standard shell provisioner only allows running commands on
  # the guest VM.
  # Usage:
  #   run "command"             executes command on the HOST
  #   run_remote "command"      executes command on the guest VM
  config.vm.provision "trigger", :stdout => true, :stderr => true do |trigger|
    trigger.fire do
      # Fix DNS issue that prevents the apt-get called by vagrant-vbguest
      # (before the provisioning script is run) from downloading packages from
      # archive.ubuntu.com
      run_remote "echo -e \"nameserver #{VM_NAMESERVER1}\nnameserver " \
                 "#{VM_NAMESERVER2}\" >> /etc/resolv.conf"
      # Update guest addons after fixing DNS issue
      run "vagrant vbguest"
      # Insert the VM shared folder path in rc.local. We are using "|" as a
      # separator instead of "/" so any slashes in the shared folder path are
      # not interpreted as separators.
      run_remote "sed -i \"s|^.*VM_SHARED_FOLDER_PLACEHOLDER.*$|export " \
                 "VM_SHARED_FOLDER=#{VM_SHARED_FOLDER}|\" /etc/rc.local"
    end
  end

  # A reboot is required for the new guest additions to work
  config.vm.provision :reload

  # Run Shell provisioning script. "privileged: true" indicates it should be run
  # AS ROOT
  config.vm.provision "shell",
                      path: "#{HOST_SHARED_FOLDER}/vm_provisioning/provision.sh",
                      privileged: true,
                      env: ROOT_PROVISIONING_OPTIONS

  # Run script to install RVM, Bundle, Ruby and Rails. This is run as the ubuntu
  # USER because installing RVM as root causes all sorts of problems.
  config.vm.provision "shell",
                      path:
                        "#{HOST_SHARED_FOLDER}/vm_provisioning/" \
                        "install_ruby.sh",
                      privileged: false,
                      env: USER_PROVISIONING_OPTIONS

  config.vm.provision "shell",
                      inline: "echo -e '\e[1;32mProvisioning finished, your " \
                              "VM is ready. Happy coding!\e[m\n'"

end
