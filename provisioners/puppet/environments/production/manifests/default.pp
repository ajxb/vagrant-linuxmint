###############################################################################
# Parameters
###############################################################################
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
package { lookup('packages', Array[String], 'unique'):
  ensure => latest,
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
# resolvconf
###############################################################################
class { 'resolv_conf':
  nameservers => $bs_nameservers,
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

###############################################################################
# Ordering
###############################################################################
