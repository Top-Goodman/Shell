#!/usr/bin/env bash

#  Get-JLAPS.sh
#
#
#  Created by Goodman, Spencer on 12/27/24.
#  API Role needs Read Computers, View Local Admin Password
#  Admin Account specified in variable declaration
#  Grabs serial number off machine running command
#  Uses this to get computer ID then uses that to get Mangement ID
#  Matches Admin Account to Mangement ID and gets password
#  Copies password to clipboard
#  Shows a dialog box with the Admin Account and current Laps Password
#
# Replace these variables with your actual values
client_id="f0acf79a-37dc-44db-b7fe-63833ef5343e"
client_secret="E0wr9phFIOYbmaPgO5vAK7hViKbCLZky2lN7ZiURcUWtGQBoYL-mhKQcf-w-PU2N"
jamf_url="https://kelleydrye.jamfcloud.com"
# Can use this commented out version if you have multiple local admins managed via Jamf Laps, and want to allow selection. If so, comment out other username= below this.
#username=$(osascript -e 'display dialog "Choose an admin account:" buttons {"KDWAdmin", "KDW_Admin"} default button "KDWAdmin"' -e 'button returned of result')
# Can use this commented out version to prompt to provide text input for username. If so, comment out other username= below this.
#username=$(osascript -e 'text returned of (display dialog "Enter your username:" default answer "")')
# Can use this commented out version to prompt for seleciton of all found local accounts to use as username (excluding a few options). If so, comment out other username= below this.
#username=$(osascript <<EOF
#set userList to {"$(echo $(dscl . list /Users | grep -v '^_' | grep -v '^root$'| grep -v '^daemon$'| grep -v '^nobody$' | grep -v "^`stat -f %Su /dev/console`")| sed 's/ /", "/g')"}
#set chosenUser to (choose from list userList with prompt "Select a user:")
#if chosenUser is false then
#    return "No user selected"
#else
#    return item 1 of chosenUser
#end if
#EOF
#)
username="KDWAdmin"
log_file="/private/var/log/RetrieveLAPS.log"
loggedInUser=$(stat -f "%Su" /dev/console)

# Logging function with timestamp
log() {
    local message="$1"
    local timestamp=$(date +"%Y-%m-%dT%H:%M:%S%z")
    echo "[$timestamp] $message" >> "$log_file"
    echo "[$timestamp] $message"
}

# Log the script start
log "Script started"

# Obtain the access token
response=$(curl --silent --request POST "${jamf_url}/api/oauth/token" \
--header "Content-Type: application/x-www-form-urlencoded" \
--data-urlencode "grant_type=client_credentials" \
--data-urlencode "client_id=${client_id}" \
--data-urlencode "client_secret=${client_secret}")

access_token=$(echo $response | jq -r '.access_token')

# Print the access token for debugging
#echo "Access Token: $access_token"

# Get the list of all computers from Jamf Pro API using the access token
computers=$(curl -H "Authorization: Bearer $access_token" -H "Accept: application/json" "$jamf_url/api/v1/computers-inventory" | jq -r '.results[] | .general.name')

# Format the computer list for AppleScript
formatted_computers=$(echo "$computers" | sed 's/$/\", \"/' | tr -d '\n' | sed 's/, $//')

# Run the AppleScript using osascript with EOF
selected_computer=$(osascript <<EOF
set computerList to {"$formatted_computers"}
set chosenComputer to (choose from list computerList with prompt "Select a computer:")
if chosenComputer is false then
    return "No computer selected"
else
    return item 1 of chosenComputer
end if
EOF
)
log "Computer ID: $computer_id"
# Get the computer ID of the selected computer
computer_id=$(curl -H "Authorization: Bearer $access_token" -H "Accept: application/json" "$jamf_url/api/v1/computers-inventory" | jq -r --arg name "$selected_computer" '.results[] | select(.general.name == $name) | .id')
log "Computername: $selected_computer"

# Get the serial number of the selected computer using the computer ID
serial_number=$(curl -H "Authorization: Bearer $access_token" -H "Accept: application/json" "$jamf_url/api/v1/computers-inventory-detail/$computer_id" | jq -r '.hardware.serialNumber')
log "Serial Number: $serial_number"

# Get the management ID using the computer ID
inventory_response=$(curl --silent --request GET "${jamf_url}/api/v1/computers-inventory-detail/${computer_id}" \
--header "Authorization: Bearer ${access_token}" \
--header "Accept: application/json")

# Print the full JSON response for debugging
#echo "Inventory Response: $(echo $inventory_response | jq .)"

# Extract the management ID using jq
management_id=$(echo $inventory_response | jq -r '.general.managementId')
log "Management ID: $management_id"

# Get the LAPS password using the management ID
laps_response=$(curl --silent --request GET "${jamf_url}/api/v2/local-admin-password/${management_id}/account/${username}/password" \
--header "Authorization: Bearer ${access_token}")

# Print the response for debugging
#echo "LAPS Response: $laps_response"

laps_password=$(echo $laps_response | jq -r '.password')
log "LAPS Password: $laps_password"

# Optional: Copy the password to the clipboard (only works if script principal is logged on user
echo "${laps_password}" | pbcopy

# Get the expiration date using the audit endpoint
audit_response=$(curl --silent --request GET "${jamf_url}/api/v2/local-admin-password/${management_id}/account/${username}/audit" \
--header "Authorization: Bearer ${access_token}")

laps_expiration=$(echo $audit_response | jq -r '.results[-1].expirationTime')
log "LAPS Password Expiration (UTC): $laps_expiration"

# Display the password and expiration date in a popup dialog box
osascript -e "display dialog \"Computer Name: ${selected_computer}\nAdmin Username: ${username}\nCurrent LAPS Password: ${laps_password}\nExpiration Date (UTC): ${laps_expiration}\" buttons {\"OK\"} default button \"OK\""
