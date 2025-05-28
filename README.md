# EcryptFS Folder Encryption Manager

## Program developed by Gustavo Wydler Azuaga - 2025-04-25


## Overview

The **EcryptFS Folder Encryption Manager**

- Simple and interactive Bash-based script
- Allows users to manage encrypted folders using `ecryptfs`. 
- Create, mount, decrypt, and manage encrypted folders on your Linux system. 
- Ideal for protecting sensitive data by encrypting folders.

## Features

- **Folder Creation**: Allows users to create new folders that will later store encrypted data.
- **Encrypt Folders**: Enables the encryption of folders using `ecryptfs` to protect sensitive data.
- **Copy Data**: Facilitates copying sensitive data into encrypted folders.
- **Mount and Decrypt**: Provides easy mounting and decryption of encrypted folders to make their data accessible.
- **Unmount and Encrypt**: Unmounts and encrypts folders to hide sensitive data securely.
- **Folder Validation**: Validates whether a folder is encrypted and mounted.
- **List Encrypted Folders**: Lists all currently encrypted and mounted folders.
- **Check Encryption**: Checks if a folder is encrypted with `ecryptfs`.

### Requirements

- Install ecryptfs

  ```bash
  # Debian/Ubuntu
  
  sudo apt-get update
  sudo apt-get install ecryptfs-utils

  # Centos/RHEL

  sudo yum install epel-release
  sudo yum install ecryptfs-utils
  ```

- Clone and run the program

  ```bash
  git clone https://github.com/kurogane13/ecryptfs_management_console.git

  sudo chmod +rx ecryptfs_management_console/encryptfs_cli.sh

  sudo bash ecryptfs_management_console/encryptfs_cli.sh
  ```
