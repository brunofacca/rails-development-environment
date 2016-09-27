# Bruno's Rails Development Environment

## Summary
Development environment for Ruby on Rails based on Vagrant, 
VirtualBox and Ubuntu 16.04 LTS (Xenial Xerus). 

The Vagrant provisioning scripts do the following:
- Set the VM locale and time zone.
- Configure the VM for SSH access with a custom SSH key.
- Use RVM to install any version of Ruby and Rails in the VM.
- Install PostgreSQL, configure it to listen on 0.0.0.0, create a new user and grant it 
CREATEDB permissions. 
- Install and configure Git at the VM.
- Install Elastic Beanstalk CLI at the VM.

Other scripts run at shell startup to set environment variables and Bash shortcuts 
(aliases and functions).

## Installation
1. Install the latest version of Vagrant and VirtualBox on the host machine.
2. Choose a directory for your VirtualBox shared folder (in the host machine).
[Download this repository][1] and unzip it inside the chosen directory.
3. Create an SSH key pair, name the files `id_rsa` (private key), `id_rsa.pub` (public key),
 and place them in the `vm_provisioning` directory.
4. Edit the `Vagrantfile` in order to customize the values of the variables located in the
 "User Configurations" section.
5. Optional: If you require any custom environment variables to be available at the guest
VM, create a file named `environment_variables.sh` within the `vm_provisioning` directory
and set your environment vars using the standard bash syntax: one
`export VAR_NAME='var value'` declaration per line. Those vars will be loaded automatically 
every time the VM boots. That is a good place to store your API keys and other secrets.
6. Optional: If you wish to use any custom bash aliases or functions, add them to 
`bash_shortcuts.sh`

[1]: https://github.com/brunofacca/rails-development-environment/archive/master.zip

## Files and their purposes

| File                     | Contents and/or purpose                                                                                                                                                                         | Executed at             | Called by                 |
|--------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------|---------------------------|
| bash_shortcuts.sh        | Custom bash aliases and function definitions.                                                                                                                                                   | "Login" (shell startup) | Symlink at /etc/profile.d |
| environment_variables.sh | Custom environment variable definitions. You may store your  API keys and other secrets here, as long as you keep this file  outside any Git repositories.                                      | "Login" (shell startup) | Symlink at /etc/profile.d |
| boot.sh                  | Custom startup commands. These commands were not inserted  in rc.local because: a) we prefer Bash over Bourne Shell; b) the  -e flag used in rc.local's shebang line causes undesired behavior. | VM boot                 | /etc/rc.local             |
| provision.sh             | Installs and configures everything in the VM, except Ruby and Rails.                                                                                                                            | VM provisioning         | Vagrantfile               |
| install_ruby.sh          | Installs Ruby and Rails in the VM at the end of provisioning.                                                                                                                                   | VM provisioning         | Vagrantfile               |
| Vagrantfile              | General configurations. Set up the VirtualBox VM and the provisioning process.                                                                                                                  | vagrant up, halt, etc   | the user                  |

## Usage

To start the VM, cd to the directory where the Vagrantfile is (in the host machine) and run `vagrant up`  
To turn off the VM, run `vagrant halt`

**Shortcuts**

All shortcuts except `jcurl` only work when executed within a Rails app directory.

`rs` rails s -b 0.0.0.0  
`rc` rails console

`tdl` tail -f development log  
`ttl` tail -f test log  
`ctl` clear test log  
`cdl` clear development log  

`jcurl` runs curl -s and pretty prints JSON output with the awesome_print gem. Takes a URL
 as an argument. 

`bi` Run bundle install in multiple parallel threads (faster).

`gpl` git pull  
`ga` git add . --all  
`gc` git commit. Takes a commit message as an argument.  
`gs` git status  
`gp` git push. Takes a remote name and a branch name as optional arguments (e.g., 
origin master)       






## Release History

- 0.1.0 - Initial release
- 0.2.0 - Add Bash shortcuts, refactor provision.sh, call environment_variables.sh from 
a symlink in /etc/profile.d instead of /etc/rc.local, update README.

## Contributing

**Bug reports**

Please use the issue tracker to report any bugs.

**Developing**

1. Create an issue and describe your idea
2. Fork it
3. Create your feature branch (git checkout -b my-new-feature)
4. Commit your changes (git commit -m 'Add some feature')
5. Publish the branch (git push origin my-new-feature)
6. Create a Pull Request

## License

Released under the [MIT License](https://opensource.org/licenses/MIT).