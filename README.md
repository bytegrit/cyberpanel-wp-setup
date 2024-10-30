# WordPress Auto Restore Tool

This tool automates the process of:

1. Creating a website using CyberPanel.
2. Creating a database and storing credentials securely.
3. Installing WordPress using `wp-cli`.
4. Installing required plugins, including All-in-One WP Migration and a custom plugin from a ZIP file.
5. Restoring a WordPress site from a `.wpress` backup file.
6. Removing the backup file after a successful restore.

## Prerequisites

Before using this tool, ensure the following:

1. **CyberPanel CLI** is installed and available.
2. **wp-cli** is installed and included in your system’s PATH.
3. You have a valid `.wpress` backup file to restore.
4. The custom plugin ZIP file is placed in `/home/`.
5. You have appropriate permissions to execute the script.

## Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd <repository-folder>
## Usage
Create a domains.txt file listing the domains to set up:


example1.com
example2.com

## Run the script:

bash
./wordpress_restore.sh
When prompted, enter the backup file name (e.g., your-backup-file.wpress).

