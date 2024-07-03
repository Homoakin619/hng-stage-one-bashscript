#!/bin/bash

# Define input file and log file
INPUT_FILE=$1
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.txt"

# Ensure the /var/secure directory exists and set permissions
mkdir -p /var/secure
chmod 700 /var/secure

# Create or clear the log and password files
> "$LOG_FILE"
> "$PASSWORD_FILE"

# Function to generate a random password
generate_password() {
    # Use openssl to generate a random password
    openssl rand -base64 12
}

# Read the input file line by line
while IFS=';' read -r username groups; do
    # Trim whitespace from username and groups
    username=$(echo "$username" | xargs)
    groups=$(echo "$groups" | xargs)

    # Log the creation process
    echo "Creating user: $username" >> "$LOG_FILE"

    # Check if the user already exists
    if id "$username" &>/dev/null; then
        echo "User $username already exists. Skipping." >> "$LOG_FILE"
        continue
    fi

    # Create the user with a home directory and personal group
    if getent group "$username" &>/dev/null; then
        echo "User personal group already exist" >> "$LOGFILE"
    else
        groupadd "$username"
    fi

    useradd -m -g "$username" "$username"
    echo "User $username created with home directory and personal group." >> "$LOG_FILE"

    # Set the home directory permissions
    chmod 700 "/home/$username"
    chown "$username:$username" "/home/$username"

    # Generate a random password and set it for the user
    password=$(generate_password)
    echo "$username:$password" | chpasswd
    echo "Password for user $username set." >> "$LOG_FILE"

    # Store the password in password file
    echo "$username,$password" >> "$PASSWORD_FILE"

    # Add the user to additional groups
    IFS=',' read -ra group_array <<< "$groups"
    for group in "${group_array[@]}"; do
        group=$(echo "$group" | xargs)  # Trim whitespace
        if getent group "$group" &>/dev/null; then
            usermod -aG "$group" "$username"
            echo "Added user $username to group $group." >> "$LOG_FILE"
        else
            echo "Group $group does not exist. Creating group $group." >> "$LOG_FILE"
            groupadd "$group"
            usermod -aG "$group" "$username"
            echo "Group $group created and user $username added to group $group." >> "$LOG_FILE"
        fi
    done
done < "$INPUT_FILE"

echo "User creation process completed." >> "$LOG_FILE"
