require 'ipaddr'
require 'resolv'

# Auto generate a unique IP address and hostname
def generate_unused_ip_address(ip_address)
  loop do
    # Ensure that the generated IP address doesn't use reserved values of 0 or 1 for the last octet
    while ip_address.to_s.split('.').last.to_i < 2
      ip_address = ip_address.succ
    end

    begin
      name = Resolv::Hosts.new.getname(ip_address.to_s)
    rescue
      # The address does not exist in DNS - exit the loop
      break
    end

    ip_address = ip_address.succ
  end

  ip_address
end

Vagrant.configure("2") do |config|
  vagrant_root = File.dirname(__FILE__)
  config.vm.box = "ajxb/mint-18.3"

  # The following will load host config from a .host file if it exists, if the
  # .host file does not exist a new IP address / hostname is generated
  # This ensures persistence with the hostname / IP address between up / halt operations
  hostname = 'vagmint01.home'
  ip_address = nil
  if File.file? "#{vagrant_root}/.host"
    hostconfig = YAML.load_file("#{vagrant_root}/.host")
    ip_address = IPAddr.new hostconfig[:ip_address]
  else
    ip_address = generate_unused_ip_address(IPAddr.new '10.15.0.0')
    hostconfig = {hostname: hostname, ip_address: ip_address.to_s}
    File.open("#{vagrant_root}/.host", 'w') {|file| file.write(hostconfig.to_yaml)}
  end

  config.vm.hostname = hostname
  config.vm.network 'private_network', ip: ip_address.to_s
  config.hostsupdater.remove_on_suspend = false

  config.vm.provider "virtualbox" do |vb|
    vb.gui = true
    vb.memory = "4096"
    vb.cpus = "2"
  end

  ##############################################################################
  # Vagrant specific provisioning
  ##############################################################################
  config.vm.provision 'shell', inline: '/vagrant/provisioners/script/install.sh'
  config.vm.provision :reload

  config.vm.post_up_message = "Hostname : #{config.vm.hostname}\nIP Address : #{ip_address}"

  # Remove .host file after destroy
  config.trigger.after :destroy do
    File.delete "#{vagrant_root}/.host" if File.file? "#{vagrant_root}/.host"
  end
end
