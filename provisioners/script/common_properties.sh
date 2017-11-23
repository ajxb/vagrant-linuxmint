#!/bin/bash

###############################################################################
# Common global properties used for scripts
#
# Globals:
#   BS_GROUPS - The groups that the user belongs to
#   BS_REQUIRED_USER - The user the scripts should be run as
#   BS_USER   - User who invoked the script
###############################################################################
readonly BS_REQUIRED_USER='root'

BS_USER="$(id -un)"
readonly BS_USER

BS_GROUPS="$(id -Gn "${BS_USER}")"
readonly BS_GROUPS
