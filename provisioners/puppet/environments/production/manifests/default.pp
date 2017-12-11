###############################################################################
# Parameters
###############################################################################
$bs_packer_version   = lookup('bs_packer_version')
$bs_ruby_version     = lookup('bs_ruby_version')
$bs_rubygems_version = lookup('bs_rubygems_version')
$bs_vagrant_version  = lookup('bs_vagrant_version')

$bs_primary_user_group = lookup('bs_primary_user_group')
$bs_primary_user_name  = lookup('bs_primary_user_name')
$bs_nameservers        = lookup('bs_nameservers')

###############################################################################
# Basic class includes coming from Hiera
###############################################################################
lookup('classes', Array[String], 'unique').include

###############################################################################
# Basic package installations coming from Hiera
###############################################################################
include apt
apt::ppa { lookup('ppas', Array[String], 'unique'):
  notify => Class['apt::update'],
}

package { lookup('packages', Array[String], 'unique'):
  ensure  => latest,
  require => Class['apt::update'],
}

###############################################################################
# Linux Mint customizations
###############################################################################
class { 'linuxmint':
  user  => $bs_primary_user_name,
  group => $bs_primary_user_group,
}

###############################################################################
# Faba Icon Theme
###############################################################################
class { 'faba_icon_theme':
  user  => $bs_primary_user_name,
}

###############################################################################
# Numix GTK Theme
###############################################################################
class { 'numix_gtk_theme':
  user  => $bs_primary_user_name,
  group => $bs_primary_user_group,
}

###############################################################################
# resolvconf
###############################################################################
class { 'resolv_conf':
  nameservers => $bs_nameservers,
}

###############################################################################
# packer
###############################################################################
class { 'packer':
  version => $bs_packer_version,
}

###############################################################################
# vagrant
###############################################################################
class { 'vagrant':
  version => $bs_vagrant_version,
}

vagrant::plugin { 'vagrant-hostsupdater':
  user => $bs_primary_user_name,
}

vagrant::plugin { 'vagrant-reload':
  user => $bs_primary_user_name,
}

vagrant::plugin { 'vagrant-triggers':
  user => $bs_primary_user_name,
}

###############################################################################
# dpkg packages
# Create a folder to store dpkg files
###############################################################################
$packages_root = '/opt/packages'
file { $packages_root:
  ensure => 'directory',
  group  => 'root',
  mode   => '0755',
  owner  => 'root',
}

###############################################################################
# VirtualBox
###############################################################################
$vbox_release          = '5.1.30'
$vbox_package          = 'virtualbox-5.1_5.1.30-118389~Ubuntu~xenial_amd64.deb'
$vbox_extpack_package  = 'Oracle_VM_VirtualBox_Extension_Pack-5.1.30.vbox-extpack'
$vbox_extpack_checksum = '2da095e32f85fe5a1fe943158e079bd5aecb2724691c4038bd619ddee967b288'
$vbox_extpack_folder   = '/usr/lib/virtualbox/ExtensionPacks/Oracle_VM_VirtualBox_Extension_Pack'
$vbox_url              = "http://download.virtualbox.org/virtualbox/${vbox_release}"

file { 'virtualbox-installer':
  path    => "${packages_root}/${vbox_package}",
  ensure  => 'present',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  source  => "${vbox_url}/${vbox_package}",
  require => File["${packages_root}"],
}

package { 'virtualbox':
  provider             => 'dpkg',
  ensure               => 'installed',
  reinstall_on_refresh => true,
  source               => "${packages_root}/${vbox_package}",
  subscribe            => File['virtualbox-installer'],
  require              => Package['libcurl3'],
}

$vbox_extpack_folders = [
  '/usr/lib/virtualbox',
  '/usr/lib/virtualbox/ExtensionPacks',
  '/usr/lib/virtualbox/ExtensionPacks/Oracle_VM_VirtualBox_Extension_Pack',
]
file { $vbox_extpack_folders:
  ensure  => 'directory',
  group   => 'root',
  mode    => '0755',
  owner   => 'root',
  require => Package['virtualbox'],
}

archive { 'virtualbox-extpack':
  ensure        => 'present',
  path          => "${packages_root}/${vbox_extpack_package}.tgz",
  source        => "${vbox_url}/${vbox_extpack_package}",
  checksum_type => 'sha256',
  checksum      => "${vbox_extpack_checksum}",
  extract       => true,
  extract_path  => "${vbox_extpack_folder}",
  cleanup       => 'false',
  creates       => "${packages_root}/${vbox_extpack_package}.tgz",
  subscribe     => Package['virtualbox'],
  require       => File["${vbox_extpack_folder}"],
}

exec { 'virtualbox-extpack permissions':
  command   => "chown -R root:root ${vbox_extpack_folder}",
  path      => $facts['path'],
  subscribe => Archive['virtualbox-extpack'],
}

###############################################################################
# RVM, Ruby and Gems
###############################################################################
class { 'rvm': }

rvm_system_ruby { "ruby-${bs_ruby_version}":
  ensure      => 'present',
  default_use => true,
}

exec { 'update_rubygems':
  command => "/bin/bash --login -c \"gem update --system ${bs_rubygems_version}\"",
  require => Rvm_system_ruby["ruby-${bs_ruby_version}"],
}

rvm_gem { 'bundler':
  name         => 'bundler',
  ruby_version => "ruby-${bs_ruby_version}",
  ensure       => latest,
  require      => Rvm_system_ruby["ruby-${bs_ruby_version}"],
}

rvm_gem { 'librarian-puppet':
  name         => 'librarian-puppet',
  ruby_version => "ruby-${bs_ruby_version}",
  ensure       => latest,
  require      => Rvm_system_ruby["ruby-${bs_ruby_version}"],
}

###############################################################################
# GitKraken
###############################################################################
file { 'gitkraken-installer':
  path    => "${packages_root}/gitkraken-amd64.deb",
  ensure  => 'present',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  source  => 'https://release.gitkraken.com/linux/gitkraken-amd64.deb',
  require => File["${packages_root}"],
}

package { 'gitkraken':
  provider             => 'dpkg',
  ensure               => 'installed',
  reinstall_on_refresh => true,
  source               => "${packages_root}/gitkraken-amd64.deb",
  subscribe            => File['gitkraken-installer'],
}

###############################################################################
# Users
###############################################################################
user { $bs_primary_user_name:
  ensure  => present,
  require => Group[$bs_primary_user_group],
}

group { $bs_primary_user_group:
  ensure => present,
}

$user_dirs = [
  "/home/${bs_primary_user_name}",
]

file { $user_dirs:
  ensure => 'directory',
  owner  => $bs_primary_user_name,
  group  => $bs_primary_user_group,
  mode   => '0700',
  require => [
    User[$bs_primary_user_name],
    Group[$bs_primary_user_group],
  ],
}

rvm::system_user { $bs_primary_user_name:
  create  => false,
  require => User[$bs_primary_user_name],
}

###############################################################################
# Ordering
###############################################################################
