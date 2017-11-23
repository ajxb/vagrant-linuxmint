#!/bin/bash

###############################################################################
# Install git
# Globals:
#   None
# Arguments:
#   $@
# Returns:
#   None
###############################################################################
install_git() {
  apt_update

  # Install a copy of software-properties-common if it's not installed
  dpkg --get-selections | grep -q -e '^software-properties-common[[:space:]]' > /dev/null 2>&1
  if [[ $? -ne 0 ]]; then
    echo 'Installing software-properties-common'
    apt-get -qq -y install software-properties-common
    if [[ $? -ne 0 ]]; then
      abort 'Failed to install software-properties-common'
    fi
  fi

  # Add git repo if it's not installed
  grep -q 'git-core' /etc/apt/sources.list.d/*.list > /dev/null 2>&1
  if [[ $? -ne 0 ]]; then
    echo 'Adding PPA for git-core'
    add-apt-repository -y ppa:git-core/ppa
    if [[ $? -ne 0 ]]; then
      abort 'Failed to add PPA for git-core'
    fi

    apt-get -qq -y update
    if [[ $? -ne 0 ]]; then
      abort 'Failed to update apt cache'
    fi
  fi

  # Install a copy of git if it's not installed
  dpkg --get-selections | grep -q -e '^git[[:space:]]' > /dev/null 2>&1
  if [[ $? -ne 0 ]]; then
    echo 'Installing git'
    apt-get -qq -y install git
    if [[ $? -ne 0 ]]; then
      abort 'Failed to install git'
    fi
  fi
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
  echo 'Install git'
  echo
  echo 'OPTIONS:'
  echo "  -h show help information about ${script_name}"

  exit 1
}

main() {
  pushd "${MY_PATH}" > /dev/null 2>&1

  setup_vars "$@"
  check_user
  install_git

  popd > /dev/null 2>&1
}

echo '**** install_git ****'

MY_PATH="$(dirname "$0")"
MY_PATH="$(cd "${MY_PATH}" && pwd)"
readonly MY_PATH

source "${MY_PATH}/common_properties.sh"
source "${MY_PATH}/common_functions.sh"

main "$@"

echo '**** install_git - done ****'

exit 0
