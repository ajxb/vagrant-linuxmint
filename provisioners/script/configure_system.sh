#!/bin/bash

###############################################################################
# Configure apt to prevent automatic updates and use IPv4 for requests
# Globals:
#   $0
# Arguments:
#   None
# Returns:
#   None
###############################################################################
configure_apt() {
  echo 'Updating apt configuration'

  # Use IPv4 for requests
  echo 'Acquire::ForceIPv4 "true";' | tee /etc/apt/apt.conf.d/99force-ipv4
}

###############################################################################
# Configure dhclient to use fixed nameservers
# Globals:
#   $0
# Arguments:
#   None
# Returns:
#   None
###############################################################################
configure_dhclient() {
  # Update dhclient configuration to include correct DHCP
  echo 'Updating dhclient configuration'
  sed -i 's/#prepend domain-name-servers 127.0.0.1;/prepend domain-name-servers 8.8.8.8,8.8.4.4;/g' /etc/dhcp/dhclient.conf
  if [[ $? -ne 0 ]]; then
    abort 'Failed to update dhclient configuration'
  fi
}

###############################################################################
# Configure gnome-terminal to always use a login shell
# Globals:
#   $0
# Arguments:
#   None
# Returns:
#   None
###############################################################################
configure_gnome_terminal() {
  # Update the gnome-terminal.desktop file to spawn a login shell
  echo 'Configuring gnome-terminal'
  sed -i -E 's/^Exec=gnome-terminal.*/Exec=gnome-terminal --command "bash --login"/g' /usr/share/applications/gnome-terminal.desktop
  if [[ $? -ne 0 ]]; then
    abort 'Failed to update dhclient configuration'
  fi
}

###############################################################################
# Configure the keyboard
# Globals:
#   $0
# Arguments:
#   None
# Returns:
#   None
###############################################################################
configure_keyboard() {
  # Set the keyboard configuration
  echo 'Updating keyboard configuration'
  sed -i -E 's/XKBMODEL=".*"/XKBMODEL="pc105"/g' /etc/default/keyboard
  if [[ $? -ne 0 ]]; then
    abort 'Failed to update keyboard model configuration'
  fi
  sed -i -E 's/XKBLAYOUT=".*"/XKBLAYOUT="gb"/g' /etc/default/keyboard
  if [[ $? -ne 0 ]]; then
    abort 'Failed to update keyboard layout configuration'
  fi
  sed -i -E 's/XKBVARIANT=".*"/XKBVARIANT="extd"/g' /etc/default/keyboard
  if [[ $? -ne 0 ]]; then
    abort 'Failed to update keyboard variant configuration'
  fi
}

###############################################################################
# Configure locale to be en_GB
# Globals:
#   $0
# Arguments:
#   None
# Returns:
#   None
###############################################################################
configure_locale() {
  echo 'Updating locale'
  update-locale LANG='en_GB.UTF8' LANGUAGE='en_GB:en'
  if [[ $? -ne 0 ]]; then
    abort 'Failed to update locale'
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
  echo 'Configure core system setup'
  echo
  echo 'OPTIONS:'
  echo "  -h show help information about ${script_name}"

  exit 1
}

main() {
  pushd "${MY_PATH}" > /dev/null 2>&1

  setup_vars "$@"
  check_user
  configure_apt
  configure_dhclient
  configure_keyboard
  configure_locale
  configure_gnome_terminal

  popd > /dev/null 2>&1
}

echo '**** configure_system ****'

MY_PATH="$(dirname "$0")"
MY_PATH="$(cd "${MY_PATH}" && pwd)"
readonly MY_PATH

source "${MY_PATH}/common_properties.sh"
source "${MY_PATH}/common_functions.sh"

main "$@"

echo '**** configure_system - done ****'

exit 0
