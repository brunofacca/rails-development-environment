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

## Usage
1. Install the latest version of Vagrant and VirtualBox on the host machine.
2. Create a SSH key pair, name the files `id_rsa` (private key), `id_rsa.pub` (public key),
 and place them in the `vm_provisioning` directory.
3. Customize the values of the variables in the "User Configurations" section, at the 
beginning of the `Vagrantfile`.
4. If you require any custom environment variables to be avaliable at the guest
VM, create a file named `environment_variables.sh` within the `vm_provisioning` directory
and set your environment vars using the standard bash syntax: one
`export VAR_NAME='var value'` declaration per line. Those vars will be loaded automatically every time the VM 
boots. That is a good place to store your API keys and other secrets.

## Release History

- 0.1.0 - Initial release

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