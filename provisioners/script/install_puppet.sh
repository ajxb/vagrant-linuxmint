#!/bin/bash

###############################################################################
# Install librarian_puppet and dependency ruby
# Globals:
#   None
# Arguments:
#   $@
# Returns:
#   None
###############################################################################
install_librarian_puppet() {
  echo 'Installing ruby'
  apt-get -qq -y install ruby
  if [[ $? -ne 0 ]]; then
    abort 'Failed to install ruby'
  fi

  echo 'Installing librarian-puppet'
  gem install librarian-puppet
  if [[ $? -ne 0 ]]; then
    abort 'Failed to install librarian-puppet'
  fi
}

###############################################################################
# Install puppet
# Globals:
#   None
# Arguments:
#   $@
# Returns:
#   None
###############################################################################
install_puppet() {
  # Get release information
  # shellcheck disable=SC1091
  . /etc/os-release

  # Configure the Puppet apt repository (UBUNTU_CODENAME is defined in os-release)
  PUPPET_RELEASE="puppet5-release-${UBUNTU_CODENAME}.deb"

  echo "Downloading ${PUPPET_RELEASE}"
  local COUNTER=10
  until [[ ${COUNTER} -eq 0 ]]; do
    if wget "http://apt.puppetlabs.com/${PUPPET_RELEASE}"; then
      break
    fi
    (( COUNTER-- ))
  done

  if [[ $COUNTER -eq 0 ]]; then
    abort 'Failed to fetch puppet release package'
  fi

  echo "Installing ${PUPPET_RELEASE}"
  dpkg -i "${PUPPET_RELEASE}"
  if [[ $? -ne 0 ]]; then
    abort "Failed to install ${PUPPET_RELEASE}"
  fi

  echo 'Updating apt database'
  apt-get -qq -y update
  if [[ $? -ne 0 ]]; then
    abort 'Failed to update apt database'
  fi

  # Install Puppet
  echo 'Installing Puppet'
  apt-get -qq -y install puppet-agent
  if [[ $? -ne 0 ]]; then
    abort 'Failed to install Puppet'
  fi

  # Clean up
  echo 'Cleaning up'
  rm -f "${PUPPET_RELEASE}"
}

###############################################################################
# Parse script input for validity and configure global variables for use
# throughout the script
# Globals:
#   None
# Arguments:
#   $@
# Returns:
#   None
###############################################################################
setup_vars() {
  # Process script options
  while getopts ':h' option; do
    case "${option}" in
      h) usage ;;
      :)
        echo "Option -${OPTARG} requires an argument"
        usage
        ;;
      ?)
        echo "Option -${OPTARG} is invalid"
        usage
        ;;
    esac
  done
}

###############################################################################
# Output usage information for the script to the terminal
# Globals:
#   $0
# Arguments:
#   None
# Returns:
#   None
###############################################################################
usage() {
  local script_name
  script_name="$(basename "$0")"

  echo "usage: ${script_name} options"
  echo
  echo 'Install puppet and dependencies'
  echo
  echo 'OPTIONS:'
  echo "  -h show help information about ${script_name}"

  exit 1
}

main() {
  # Ensure we are working in the correct folder
  pushd "${MY_PATH}" > /dev/null 2>&1

  setup_vars "$@"
  check_user
  use_system_ruby
  install_puppet
  install_librarian_puppet

  popd > /dev/null 2>&1
}

echo '**** install_puppet ****'

MY_PATH="$(dirname "$0")"
MY_PATH="$(cd "${MY_PATH}" && pwd)"
readonly MY_PATH

source "${MY_PATH}/common_properties.sh"
source "${MY_PATH}/common_functions.sh"

main "$@"

echo '**** install_puppet - done ****'

exit 0
