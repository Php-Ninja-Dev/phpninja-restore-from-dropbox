#!/bin/bash
# Php Ninja Website Restore from Dropbox
# developers@phpninja.es
#
# Description
# This script will download and restore the backup files from Dropbox. It will unzip the files and import the MySQL database.
# License: GPL-3

# MySQL Credentials for restoring the database
db_user="DB USER"
db_password="DB PASSW"
db_name="DB NAME"
db_host="DB HOST"
db_port="3306"

# Dropbox API Access Token
dropbox_token="YOUR DROPBOX TOKEN"

# Function to download files from Dropbox
download_from_dropbox() {
    local source_path="$1"
    local destination_file="$2"
    local dropbox_api_url="https://content.dropboxapi.com/2/files/download"
    curl -X POST "${dropbox_api_url}" \
        --header "Authorization: Bearer ${dropbox_token}" \
        --header "Dropbox-API-Arg: {\"path\":\"${source_path}\"}" \
        --output "${destination_file}"
}

echo "========================"
echo "RESTORING BACKUP OF ${hostname}"
echo "========================"

# Check if a Dropbox folder path is provided as an argument
if [ -z "$1" ]; then
    echo "Error: Please provide a Dropbox folder path as an argument."
    exit 1
fi

dropbox_folder="$1"

# Get a list of files in the Dropbox folder
echo "Fetching files from Dropbox folder..."
file_list=$(curl -X POST "https://api.dropboxapi.com/2/files/list_folder" \
    --header "Authorization: Bearer ${dropbox_token}" \
    --header "Content-Type: application/json" \
    --data "{\"path\": \"/${dropbox_folder}\",\"recursive\": false}" \
    | jq -r '.entries[].path_display'
)

# Restore MySQL Database
echo "Starting DATABASE RESTORE...."
for file_path in $file_list; do
    if [[ "$file_path" == *".zip" ]]; then
        # Download and restore the zip file
        zip_file=$(basename "$file_path")
        download_from_dropbox "$file_path" "$zip_file"
        echo "Unzipping files..."
        unzip -o "$zip_file" -d "$www_folder"
        echo "Cleaning up ZIP files..."
        rm "$zip_file"
    elif [[ "$file_path" == *".sql" ]]; then
        # Download and restore the SQL file
        sql_file=$(basename "$file_path")
        download_from_dropbox "$file_path" "$sql_file"
        echo "Importing SQL file..."
        mysql -h "${db_host}" -P "${db_port}" -u "${db_user}" -p"${db_password}" "${db_name}" < "$sql_file"
        echo "Cleaning up SQL files..."
        rm "$sql_file"
    fi
done

echo "RESTORE COMPLETE!"
