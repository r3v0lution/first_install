#!/bin/bash


# Source the .env file which contains the user defined variables
source ./config.env

clear

# Define the log file
LOG_FILE="/var/log/setup_script.log"

# Print the variables
echo "--------------------------------------"
echo "--------------------------------------"
echo "Setting up system for user: $USERNAME"
echo "--------------------------------------"
echo "Configuring hostname as: $HOSTNAME"
echo "--------------------------------------"
echo "--------------------------------------"

# Prompt for confirmation before proceeding
read -p "Do you want to continue with the setup? (yes/no): " CONFIRMATION

# Check the user's response
if [[ "$CONFIRMATION" != "yes" ]]; then
    echo "Setup aborted by the user."
    exit 1
fi

# Create the log file if it does not exist
if [ ! -f $LOG_FILE ]; then
    touch $LOG_FILE
fi

# Function to log progress
log_progress() {
    echo "$1" >> $LOG_FILE
}

# Function to check if a step is complete
is_step_complete() {
    grep -q "$1" $LOG_FILE
}

# Check and create user
if ! is_step_complete "User creation completed"; then
    # Check if user already exists
    if id "$USERNAME" &>/dev/null; then
        echo "User '$USERNAME' already exists."
    else
        # Create the user and add to sudo group
        echo "Creating user '$USERNAME' and adding to sudo group..."
        sudo adduser $USERNAME
        sudo usermod -aG sudo $USERNAME
        echo "User '$USERNAME' created and added to the sudo group."
        log_progress "User creation completed"
    fi
fi

# Pause for one second
if ! is_step_complete "Update and upgrade completed"; then
    echo "Pausing for 1 second before update and upgrade..."
    sleep 1
fi

# Switch to the user and set the hostname
if ! is_step_complete "Hostname set"; then
    echo "Switching to user '$USERNAME' to set the hostname..."
    sudo -u $USERNAME bash <<EOF
        # Check and set hostname if necessary
        CURRENT_HOSTNAME=\$(hostname)
        if [[ "\$CURRENT_HOSTNAME" != "$HOSTNAME" ]]; then
            echo "Current hostname ('\$CURRENT_HOSTNAME') does not match desired hostname ('$HOSTNAME')."
            echo "Setting hostname to '$HOSTNAME'..."
            sudo hostnamectl set-hostname $HOSTNAME
        else
            echo "Hostname is already set to '$HOSTNAME'."
        fi
EOF
    log_progress "Hostname set"
fi

# Update and upgrade system
if ! is_step_complete "Update and upgrade completed"; then
    echo "Updating and upgrading system..."
    sudo apt update -y
    sudo apt upgrade -y
    log_progress "Update and upgrade completed"
fi

# Check if zsh is installed and install if necessary
if ! is_step_complete "zsh installation completed"; then
    if ! command -v zsh &>/dev/null; then
        echo "Installing zsh..."
        sudo apt install -y zsh
    else
        echo "zsh is already installed."
    fi
    log_progress "zsh installation completed"
fi

# Change shell to zsh for the user
if ! is_step_complete "Shell change completed"; then
    echo "Changing default shell to zsh for user '$USERNAME'..."
    sudo chsh -s /usr/bin/zsh $USERNAME

    # Optional: Set zsh as the default shell for the current user
    if [[ "$USER" == "$USERNAME" ]]; then
        chsh -s /usr/bin/zsh
    fi
    log_progress "Shell change completed"
fi

echo "Step 1 of the setup is complete. Please log out and run install.sh again for changes to take effect and to finish install"
