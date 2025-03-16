# Variables
$dockerImage = 'mcr.microsoft.com/cbl-mariner/base/core:2.0'
$containerName = 'cblmariner_temp'
$exportedTar = 'cblmariner.tar'
$wslDistroName = 'CBL-Mariner'
$wslDistroPath = 'C:\WSL\CBL-Mariner'

# Remove existing WSL distro if it exists
if ((wsl -l -q | ForEach-Object { $_.Trim() }) -contains $wslDistroName) {
    wsl --unregister $wslDistroName
}

# Remove existing WSL distro directory if it exists
if (Test-Path $wslDistroPath) {
    Start-Sleep -Seconds 3
    Remove-Item $wslDistroPath -Recurse -Force
}

# Step 1: Pull Docker Image
docker pull $dockerImage

# Step 2: Create a Docker Container
docker create --name $containerName -t -i $dockerImage bash

# Step 3: Install missing packages and configure container before exporting
docker start $containerName
docker exec -it $containerName tdnf update -y
docker exec -it $containerName tdnf upgrade -y
docker exec -it $containerName tdnf install -y util-linux tzdata sudo lsb-release gnupg jq nano iputils iproute net-tools bind-utils procps-ng git
docker exec -it $containerName bash -c "mkdir -p /mnt/{c,d,e,f,m}"
docker exec -it $containerName bash -c "echo -e '[interop]\nappendWindowsPath = false\n[automount]\nroot = /mnt\noptions = metadata' > /etc/wsl.conf"
docker stop $containerName

# Step 4: Export Container Filesystem
docker export --output=$exportedTar $containerName

# Step 5: Prepare WSL Directory
New-Item -Path $wslDistroPath -ItemType Directory -Force

# Step 6: Import Filesystem to WSL
wsl --import $wslDistroName $wslDistroPath $exportedTar

# Cleanup
Remove-Item $exportedTar
docker rm $containerName

# Verify Installation
wsl -d $wslDistroName -e bash -c "echo 'CBL-Mariner is now installed and configured in WSL!'"
