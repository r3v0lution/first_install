#!/bin/bash


# Source the .env file which contains the user defined variables
source ./config.env

clear

# Define marker file
MARKER_FILE="/tmp/installer_marker"

# Print the variables
echo "--------------------------------------"
echo "--------------------------------------"
echo "Setting up system for user: $USERNAME"
echo "--------------------------------------"
echo "Configuring hostname as: $HOSTNAME"
echo "--------------------------------------"
echo "--------------------------------------"

# Check if script has already run some parts
if [[ -f "$MARKER_FILE" ]]; then
    echo "Resuming from marker file..."
else
    # Prompt for confirmation before proceeding
    read -p "Do you want to continue with the setup? (yes/no): " CONFIRMATION

    # Check the user's response
    if [[ "$CONFIRMATION" != "yes" ]]; then
        echo "Setup aborted by the user."
        exit 1
    fi

    # Check if user already exists
    if id "$USERNAME" &>/dev/null; then
        echo "User '$USERNAME' already exists."
    else
        # Create the user and add to sudo group
        echo "Creating user '$USERNAME' and adding to sudo group..."
        sudo adduser $USERNAME
        sudo usermod -aG sudo $USERNAME
        echo "User '$USERNAME' created and added to the sudo group."
    fi

    # Switch to the user and set the hostname
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
# Copy git clone from original user to new user and delete old directory.
sudo cp -r /home/$ORIGINALUSER/first_install ~/first_install
sudo rm -r /home/$ORIGINALUSER/first_install

    # Create marker file
    touch "$MARKER_FILE"
fi

# Proceed with the remaining setup
echo "Updating and upgrading system..."
sudo apt update -y
sudo apt upgrade -y

# Check if zsh is installed
if ! command -v zsh &>/dev/null; then
    echo "Installing zsh..."
    sudo apt install -y zsh
else
    echo "zsh is already installed."
fi

# Change shell to zsh for the user
echo "Changing default shell to zsh for user '$USERNAME'..."
sudo chsh -s /usr/bin/zsh $USERNAME

# Optional: Set zsh as the default shell for the current user
if [[ "$USER" == "$USERNAME" ]]; then
    chsh -s /usr/bin/zsh
fi

# Clean up marker file (optional)
rm -f "$MARKER_FILE"

echo "Step 1 of the setup is complete. Please log out and run install.sh again for changes to take effect and to finish install"
