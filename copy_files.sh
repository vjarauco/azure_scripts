# Prompt the user for the subscription ID to use
read -p "Enter the subscription ID: " subscriptionId
az account set --subscription $subscriptionId

# Prompt the user for the source storage account, container, and folder
read -p "Enter the source storage account name: " source_storage_account_name
read -p "Enter the source container name: " source_container_name
read -p "Enter the source folder name: " source_folder

# Get the key for the source storage account and suppress the warning
source_key=$(az storage account keys list -n $source_storage_account_name --query "[0].value" --output tsv 2>/dev/null)

if [ -z "$source_key" ]; then
  echo "Error obtaining the key for the source storage account."
  exit 1
fi
echo "Successfully obtained the key for the source storage account."

# Destination storage account and container
read -p "Enter the destionation storage account name: " destination_storage_account_name
read -p "Enter the destination container name: " destination_container_name
read -p "Enter the destination folder name: " destination_folder

# Get the key for the destination storage account and suppress the warning
destination_key=$(az storage account keys list -n $destination_storage_account_name --query "[0].value" --output tsv 2>/dev/null)

if [ -z "$destination_key" ]; then
  echo "Error obtaining the key for the destination storage account."
  exit 1
fi
echo "Successfully obtained the key for the destination storage account."

# List the blobs in the source container
allBlobs=$(az storage blob list --container-name $source_container_name --account-name $source_storage_account_name --account-key $source_key --query "[].name" --output tsv)

# Filter the blobs to exclude folders and only include blobs in the specified source folder
filteredBlobs=$(echo "$allBlobs" 
grep "^$source_folder/"	
 grep -v '/$')

# Display the available blobs
echo "Available blobs in the source folder:"
echo "$filteredBlobs"

# Prompt the user for the blob pattern to copy
read -p "Enter the pattern of blobs to copy (e.g., *.abf): " blob_pattern

# Filter the blobs that match the specified pattern
blobs_to_copy=$(echo "$filteredBlobs" | grep -E "$blob_pattern")

# Check if there are blobs that match the pattern
if [ -z "$blobs_to_copy" ]; then
  echo "Error: No blobs found that match the specified pattern."
  exit 1
fi

# Confirm the information entered by the user
echo "Information entered:"
echo "Source storage account: $source_storage_account_name"
echo "Source container: $source_container_name"
echo "Source folder: $source_folder"
echo "Destination storage account: $destination_storage_account_name"
echo "Destination container: $destination_container_name"
echo "Destination folder: $destination_folder"
echo "Blobs to copy: $blob_pattern"

# Confirm the copy operation
read -p "Do you want to proceed with copying the blobs? (yes/no): " confirm

if [[ "$confirm" == "yes" || "$confirm" == "y" ]]; then
  while IFS= read -r blob; do
    echo "Copying blob: $blob"
    # Extract only the file name, without the path
    blob_name_only=$(basename "$blob")
    destination_blob_name="$destination_folder/$blob_name_only"
    az storage blob copy start --source-account-name $source_storage_account_name --source-account-key $source_key --source-container $source_container_name --source-blob "$blob" --account-name $destination_storage_account_name --account-key $destination_key --destination-container $destination_container_name --destination-blob "$destination_blob_name"
    echo "Blob copy completed: $blob_name_only"
  done <<< "$blobs_to_copy"
  echo "Blob copy operation completed."
else
  echo "Blob copy operation canceled."
fi
