#!/bin/bash

#This script executes Cisco IOS commands on one or multiple target devices defined in your hosts file.
#version 2.1 - Written by Alfredo Jo ® - 2024

# Function to get a valid target
get_target() {
  local attempts=0
  while [ $attempts -lt 2 ]; do
    echo "Choose where to run the Cisco command:"
    echo "1) hq_nyc_idf_stacks"
    echo "2) eur_bcn_idf_stacks"
    echo "3) Enter FQDN manually"
    read -p "Enter your choice [1-3]: " LOCATION_CHOICE

    case $LOCATION_CHOICE in
      1)
        TARGET="hq_nyc_idf_stacks"
        return 0
        ;;
      2)
        TARGET="eur_bcn_idf_stacks"
        return 0
        ;;
      3)
        read -p "Enter the FQDN or IP address of the switch: " TARGET
        if [[ -n "$TARGET" ]]; then
          return 0
        fi
        ;;
    esac

    echo "❌ Invalid input. Try again."
    attempts=$((attempts + 1))
  done

  echo "❌ Too many invalid attempts. Exiting."
  exit 1
}

# Function to get a valid Cisco command
get_command() {
  local attempts=0
  while [ $attempts -lt 2 ]; do
    read -p "Enter the Cisco command you want to run: " USER_CMD
    if [[ -n "$USER_CMD" ]]; then
      return 0
    fi
    echo "❌ Command cannot be empty. Try again."
    attempts=$((attempts + 1))
  done

  echo "❌ Too many invalid attempts. Exiting."
  exit 1
}

# Main execution
get_target
get_command

# Run the Ansible command with USER_CMD as a string
ansible "$TARGET" \
  -i /home/ansible/hosts \
  -m ios_command \
  -a "commands='$USER_CMD'" \
  -c network_cli \
  --vault-password-file ~/.vault_pass.txt
