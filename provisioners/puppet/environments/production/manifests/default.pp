###############################################################################
# Parameters
###############################################################################
$bs_packer_version   = lookup('bs_packer_version')
$bs_ruby_version     = lookup('bs_ruby_version')
$bs_rubygems_version = lookup('bs_rubygems_version')
$bs_vagrant_version  = lookup('bs_vagrant_version')

$bs_primary_user_group    = lookup('bs_primary_user_group')
$bs_primary_user_name     = lookup('bs_primary_user_name')
$bs_nameservers           = lookup('bs_nameservers')

###############################################################################
# Basic class includes coming from Hiera
###############################################################################
lookup('classes', Array[String], 'unique').include

###############################################################################
# Basic package installations coming from Hiera
###############################################################################
include apt

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

###############################################################################
# RVM, Ruby and Gems
###############################################################################
package { 'curl':
  ensure => 'latest',
}

exec { 'import_gpg_key':
  command => 'curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -',
  path    => '/usr/bin:/bin',
  require => Package['curl'],
}

class { 'rvm':
  gnupg_key_id => false,
  require      => Exec['import_gpg_key'],
}

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
