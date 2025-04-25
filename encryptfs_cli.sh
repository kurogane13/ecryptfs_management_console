#!/bin/bash

pause() {
	echo
    read -p "Press ENTER to continue..." dummy
}

confirm_action() {
    read -p "⚠️  Are you sure? (yes/no): " confirm
    [[ "$confirm" != "yes" ]] && echo "❌ Action cancelled." && return 1
    return 0
}

# ========= Functions =========

create_folder() {
    read -p "📂 Enter the full path of the new folder to create: " folder
    [[ -d "$folder" ]] && echo "✅ Folder already exists: $folder" && return
    mkdir -p "$folder"
    if [[ $? -eq 0 ]]; then
        echo "✅ Folder created: $folder"
    else
        echo "❌ Failed to create folder: $folder"
    fi
}

copy_data() {
    read -p "📁 Enter the source folder (unencrypted): " src
    [[ ! -d "$src" ]] && echo "❌ Source does not exist." && return
    read -p "🔐 Enter the destination folder (encrypted target): " dest
    [[ ! -d "$dest" ]] && echo "❌ Destination does not exist." && return
    confirm_action || return
    echo
    echo -e "Copying data from source path: $src"
    echo
    echo -e "To destination path: $dest"
    echo
    echo "Please wait..."
    cp -rp "$src"/* "$dest"
    echo "✅ Data copied to encrypted folder."
}

encrypt_folder() {
    read -p "🔐 Enter the full path of the folder to encrypt: " enc_folder
    [[ ! -d "$enc_folder" ]] && echo "❌ Folder not found." && return
    confirm_action || return

    echo
    echo "🔐 Encrypting folder: $enc_folder. Please wait..."
    echo
    sudo mount -t ecryptfs "$enc_folder" "$enc_folder" -o ecryptfs_key_bytes=32,ecryptfs_cipher=aes,ecryptfs_passthrough=y,ecryptfs_filename_encryption=n,ecryptfs_fnek_sig="$fnek_sig",ecryptfs_sig="$sig"

    bash nautilus_restart.sh
}

mount_folder() {
    read -p "🔐 Enter the full path of the folder to decrypt: " enc_folder
    [[ ! -d "$enc_folder" ]] && echo "❌ Folder not found." && return

    confirm_action || return
    echo
    echo "🔓 Decrypting folder: $enc_folder. Please wait..."
    echo

	sudo mount -t ecryptfs "$enc_folder" "$enc_folder" -o ecryptfs_key_bytes=32,ecryptfs_cipher=aes,ecryptfs_passthrough=y,ecryptfs_filename_encryption=n,ecryptfs_fnek_sig="$fnek_sig",ecryptfs_sig="$sig"

    bash nautilus_restart.sh
}

umount_folder() {
    read -p "🔓 Enter the full path of the folder to unmount: " dec_folder
    [[ ! -d "$dec_folder" ]] && echo "❌ Folder not found." && return
    confirm_action || return
    
    # Try to unmount the folder and capture output to a file
    umount_output=$(sudo umount "$dec_folder" 2>&1)
    
    # Check if unmounting failed due to the target being busy
    if echo "$umount_output" | grep -q "target is busy"; then
        echo "❌ Folder is busy. You may need to stop processes using the folder."
        read -p "Would you like to run 'sudo fuser -km $dec_folder' to kill processes using the folder? (y/n): " response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            sudo fuser -km "$dec_folder"
            # Attempt to unmount again after killing processes
            sudo umount "$dec_folder"
            echo "✅ Folder unmounted after killing processes."
        else
            echo "❌ Aborted. Folder not unmounted."
        fi
        return
    fi
    
    # If unmount is successful
    echo "✅ Folder unmounted."
    bash nautilus_restart.sh
}

encrypt_created_folder() {
    read -p "🔓 Enter the full path of the folder to unmount and encrypt: " dec_folder
    [[ ! -d "$dec_folder" ]] && echo "❌ Folder not found." && return
    confirm_action || return
    sudo umount "$dec_folder"
    bash nautilus_restart.sh
    echo "✅ Folder unmounted."
}

check_mounted() {
    read -p "📂 Enter the folder to check if mounted: " folder
    mountpoint -q "$folder" && echo "✅ Folder is mounted." || echo "❌ Folder is not mounted."
}

check_encrypted() {
    read -p "📂 Enter the folder to check if encrypted: " folder
    if grep -q "$folder" /proc/mounts | grep -q ecryptfs; then
        echo "✅ Folder is encrypted with ecryptfs."
    else
        echo "❌ Folder is not encrypted (or not mounted)."
    fi
}

list_mounts() {
    echo "🔐 Encrypted ecryptfs mounts:" 
    echo
    mount | grep ecryptfs | awk '
{
    split($1, src, " ");
    split($3, dst, " ");
    match($0, /type ecryptfs \(([^)]+)\)/, opts);
    split(opts[1], optlist, ",");
    printf "🔐 Source:     %-50s\n", $1
    printf "📂 Mounted On: %-50s\n", $3
    for (i in optlist) {
        if (optlist[i] ~ /ecryptfs_(cipher|key_bytes|sig|fnek_sig)/)
            printf "   - %-15s: %s\n", gensub(/.*_/, "", "g", optlist[i]), gensub(/.*=/, "", "g", optlist[i])
    }
    print "------------------------------------------------------------"
}' || echo "❌ No encrypted mounts found."

}

list_encrypted_folders() {
    echo "🔍 Searching for encrypted folders (may take time)..."
    echo
    mount | grep ecryptfs | awk -v home="$HOME" '$0 ~ home {print $1}' | sort -u
    

}

list_encrypted_contents() {
    read -p "📂 Enter the encrypted folder path to list contents: " folder
    [[ ! -d "$folder" ]] && echo "❌ Folder not found." && return
    echo "📄 Encrypted contents in $folder:"
    ls -lha "$folder"
}


# ========= Menu =========

main_menu() {
    while true; do
		# ========= Banner =========

		echo -e "\n\e[1;33mWelcome to the ECRYPTFS FOLDER ENCRYPTION MANAGER!\e[0m"
		echo -e "\n\e[1;32m📌 Instructions:\n"
		echo -e "======================================================================="
		echo -e "To create, encrypt, and store encrypted data to a new folder, follow these steps"
		echo -e "=======================================================================\n"
		echo -e "1 - Go to option 1: Create a new folder that will store encrypted data."
		echo -e "2 - Go to option 3: Mount that folder using ecryptfs."
		echo -e "3 - Go to option 2: Copy your sensitive data into the mounted folder."
		echo -e "4 - Go to option 5: Unmount to encrypt and hide the data."
		echo -e "5 - Go to option 12: Validate that the data in the folder is encrypted."
		echo -e "6 - Go to option 4: Remount to make data readable again.\e[0m\n"
		echo -e "======================================================================="
		echo -e "If you already have an encrypted folder, operate freely with the menu"
		echo -e "======================================================================="

        echo -e "\n\e[1;34m========== MAIN MENU ==========\e[0m\n"
        echo "1) 📂 Create New Folder"
        echo "2) 📁 Copy Data to Encrypted Folder"
        echo "3) 🔐 Encrypt Folder at first creation"
        echo "---------------------------------------------------"
        echo "4) 🔓 Decrypt Folder | Mounts folder to visualize data"
        echo "5) 📁 Encrypt already created folder | Umounts folder to encrypt"
        echo "---------------------------------------------------"
        echo "6) 📁 Mount a folder (ecryptfs)"
        echo "7) 📁 Unmount a folder"
        echo "---------------------------------------------------"
        echo "8) 📌 Check if Folder is Mounted"
        echo "9) 🔍 Check if Folder is Encrypted"
        echo "10) 📜 List Encrypted Mounts"
        echo "11) 📁 List Encrypted Folders"
        echo "12) 📄 List Contents of Encrypted Folder"
        echo "0) ❌ Exit"
        echo -e "\n👉 Choose an option: "
        read option
        case "$option" in
            1) create_folder ;;
            2) copy_data ;;
            3) encrypt_folder ;;
            4) mount_folder ;;
            5) encrypt_created_folder ;;
            6) mount_folder ;;
            7) umount_folder ;;
            8) check_mounted ;;
            9) check_encrypted ;;
            10) list_mounts ;;
            11) list_encrypted_folders ;;
            12) list_encrypted_contents ;;
            0) echo "👋 Exiting..."; exit 0 ;;
            *) echo "❌ Invalid option!" ;;
        esac
        pause
    done
}

main_menu
