#!/bin/bash

###############################################################################
# Common functions
###############################################################################

###############################################################################
# Abort the execution of the script outputting an appropriate error message
# Globals:
#   None
# Arguments:
#   error_message
# Returns:
#   None
###############################################################################
abort() {
  local error_message
  error_message="$1"

  echo "[FATAL] ${error_message}" >&2
  exit 1
}

###############################################################################
# Update the apt package index
# Globals:
#   $0
# Arguments:
#   None
# Returns:
#   None
###############################################################################
apt_update() {
  echo 'Updating apt package index'
  apt-get -qq -y update
  if [[ $? -ne 0 ]]; then
    abort 'Failed to update the package index'
  fi
}

###############################################################################
# Check the script is running under the required user group, abort if this is
# not the case
# Globals:
#   BS_REQUIRED_GROUP
#   BS_GROUPS
# Arguments:
#   None
# Returns:
#   None
###############################################################################
check_group() {
  if [[ ! ${BS_GROUPS} =~ ${BS_REQUIRED_GROUP} ]]; then
    abort "This script has to be run as ${BS_REQUIRED_GROUP} group"
  fi
}

###############################################################################
# Check the script is running under the required user, abort if this is not the
# case
# Globals:
#   BS_REQUIRED_USER
#   BS_USER
# Arguments:
#   None
# Returns:
#   None
###############################################################################
check_user() {
  if [[ ${BS_USER} != ${BS_REQUIRED_USER} ]]; then
    abort "This script has to be run as ${BS_REQUIRED_USER} user"
  fi
}

###############################################################################
# Check to see if rvm exists and if it does, set the system ruby to be default
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
###############################################################################
use_system_ruby() {
  if [[ -s "${HOME}/.rvm/scripts/rvm" ]] ; then
    source "${HOME}/.rvm/scripts/rvm"
    rvm use system
  elif [[ -s "/usr/local/rvm/scripts/rvm" ]] ; then
    source "/usr/local/rvm/scripts/rvm"
    rvm use system
  fi
}
