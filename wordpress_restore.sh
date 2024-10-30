#!/bin/bash

# Read input backup file name from the user.
read -p "Enter the backup file name (e.g., your-backup-file.wpress): " BACKUP_FILE

DOMAIN_FILE="domains.txt"
PLUGIN_ZIP_PATH="/home/all-in-one-wp-migration-unlimited-extension-v2.61.zip"

# Check if required files exist
if [ ! -f "$DOMAIN_FILE" ]; then
    echo "Domain list file not found: $DOMAIN_FILE"
    exit 1
fi

if [ ! -f "$PLUGIN_ZIP_PATH" ]; then
    echo "Custom plugin ZIP file not found: $PLUGIN_ZIP_PATH"
    exit 1
fi

while IFS= read -r domain; do
    if [ -n "$domain" ]; then
        echo "Creating website for: $domain"

        # Step 1: Create Website
        cyberpanel createWebsite --package Default --owner admin --domainName "$domain" --email "admin@$domain" --php 8.1
        if [ $? -ne 0 ]; then
            echo "Failed to create website: $domain"
            continue
        fi

        # Step 2: Create Database and Store Credentials
        db_name="${domain//./_}_db"
        db_user="${domain//./_}_user"
        db_pass=$(openssl rand -base64 12)

        cyberpanel createDatabase --databaseWebsite "$domain" --dbName "$db_name" --dbUsername "$db_user" --dbPassword "$db_pass"
        if [ $? -ne 0 ]; then
            echo "Failed to create database for: $domain"
            continue
        fi

        echo "Database created for $domain - Name: $db_name, User: $db_user, Password: $db_pass"

        # Step 3: Identify User and Set Paths
        user=$(ls -ld /home/"$domain" | awk '{print $3}')
        WP_PATH="/home/$domain/public_html"

        # Step 4: Install WordPress Using wp-cli
        echo "Installing WordPress for: $domain"
        sudo -u "$user" -i -- wp core download --path="$WP_PATH"
        sudo -u "$user" -i -- wp config create --path="$WP_PATH" --dbname="$db_name" --dbuser="$db_user" --dbpass="$db_pass" --dbhost=localhost
        sudo -u "$user" -i -- wp core install --path="$WP_PATH" --url="http://$domain" --title="$domain" --admin_user="admin" --admin_password="SecurePassword123!" --admin_email="admin@$domain"

        # Step 5: Install Plugins Using wp-cli
        echo "Installing All-in-One WP Migration plugin for: $domain"
        sudo -u "$user" -i -- wp plugin install all-in-one-wp-migration --activate --path="$WP_PATH"
        echo "Installing custom plugin from: $PLUGIN_ZIP_PATH"
        sudo -u "$user" -i -- wp plugin install "$PLUGIN_ZIP_PATH" --activate --path="$WP_PATH"

        # Step 6: Copy Backup File to ai1wm-backups Directory
        echo "Copying backup file to ai1wm-backups for: $domain"
        sudo mkdir -p "$WP_PATH/wp-content/ai1wm-backups"
        sudo cp "/home/$BACKUP_FILE" "$WP_PATH/wp-content/ai1wm-backups/"
        sudo chown -R "$user:$user" "$WP_PATH/wp-content/ai1wm-backups"

        # Step 7: Restore Site from Backup (Automating the 'y' Prompt)
        echo "Restoring backup for: $domain"
        echo "y" | sudo -u "$user" -i -- wp ai1wm restore "$BACKUP_FILE" --path="$WP_PATH"

        if [ $? -eq 0 ]; then
            echo "Backup successfully restored for: $domain"
            # Step 8: Remove Backup File After Successful Restore
            echo "Removing backup file for: $domain"
            sudo rm -f "$WP_PATH/wp-content/ai1wm-backups/$BACKUP_FILE"
        else
            echo "Backup restore failed for: $domain"
        fi
    fi
done < "$DOMAIN_FILE"
