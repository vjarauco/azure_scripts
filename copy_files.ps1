# Prompt the user for the subscription ID to use
$subscriptionId = Read-Host -Prompt "Enter the subscription ID"
az account set --subscription $subscriptionId

# Prompt the user for the source storage account, container, and folder
$source_storage_account_name = Read-Host -Prompt "Enter the source storage account name"
$source_container_name = Read-Host -Prompt "Enter the source container name"
$source_folder = Read-Host -Prompt "Enter the source folder name"

# Get the key for the source storage account and suppress the warning
try {
    $source_key = $(az storage account keys list -n $source_storage_account_name --query "[0].{value:value}" --output tsv 2>$null)
    Write-Host "Successfully obtained the key for the source storage account."
} catch {
    Write-Host "Error obtaining the key for the source storage account: $_"
    exit
}

# Prompt the user for the destination storage account, container, and folder
$destination_storage_account_name = Read-Host -Prompt "Enter the destination storage account name"
$destination_container_name = Read-Host -Prompt "Enter the destination container name"
$destination_folder = Read-Host -Prompt "Enter the destination folder name"

# Get the key for the destination storage account and suppress the warning
try {
    $destination_key = $(az storage account keys list -n $destination_storage_account_name --query "[0].{value:value}" --output tsv 2>$null)
    Write-Host "Successfully obtained the key for the destination storage account."
} catch {
    Write-Host "Error obtaining the key for the destination storage account: $_"
    exit
}

# List the blobs in the source container and store them in a PowerShell variable
$allBlobs = az storage blob list --container-name $source_container_name --account-name $source_storage_account_name --account-key $source_key --query "[].{name:name}" --output tsv

# Filter the blobs to exclude folders and only include blobs in the specified source folder
$filteredBlobs = $allBlobs | Where-Object { $_ -like "$source_folder/*" -and $_ -notlike '*/' }

# Display the available blobs
Write-Host "Available blobs in the source folder:"
$filteredBlobs | ForEach-Object { Write-Host $_ }

# Prompt the user for the pattern of blobs to copy
$blob_pattern = Read-Host -Prompt "Enter the pattern of blobs to copy (e.g., *.abf)"

# Filter the blobs that match the specified pattern
$blobs_to_copy = $filteredBlobs | Where-Object { $_ -like $blob_pattern }

# Check if there are blobs that match the pattern
if ($blobs_to_copy.Count -eq 0) {
    Write-Host "Error: No blobs found that match the specified pattern."
    exit
}

# Confirm the information entered by the user
Write-Host "Information entered:"
Write-Host "Source storage account: $source_storage_account_name"
Write-Host "Source container: $source_container_name"
Write-Host "Source folder: $source_folder"
Write-Host "Destination storage account: $destination_storage_account_name"
Write-Host "Destination container: $destination_container_name"
Write-Host "Destination folder: $destination_folder"
Write-Host "Blobs to copy: $blob_pattern"

# Confirm the copy operation
$confirm = Read-Host -Prompt "Do you want to proceed with copying the blobs? (yes/no)"

if ($confirm -eq "yes" -or $confirm -eq "y") {
    foreach ($blob in $blobs_to_copy) {
        Write-Host "Copying blob: $blob"
        # Extract only the file name, without the path
        $blob_name_only = [System.IO.Path]::GetFileName($blob)
        $destination_blob_name = "$destination_folder/$blob_name_only"
        try {
            az storage blob copy start --source-account-name $source_storage_account_name --source-account-key $source_key --source-container $source_container_name --source-blob $blob --account-name $destination_storage_account_name --account-key $destination_key --destination-container $destination_container_name --destination-blob $destination_blob_name
            Write-Host "Blob copy completed: $blob_name_only"
        } catch {
            Write-Host "Error copying the blob: $_"
        }
    }
    Write-Host "Blob copy operation completed."
} else {
    Write-Host "Blob copy operation canceled."
}
