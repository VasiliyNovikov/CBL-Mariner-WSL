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

# Pull Docker Image
docker pull $dockerImage

# Create a Docker Container
docker create --name $containerName -t -i $dockerImage bash
docker start $containerName

# Install missing packages
docker exec -it $containerName tdnf update -y
docker exec -it $containerName tdnf upgrade -y
docker exec -it $containerName tdnf install -y util-linux tzdata sudo lsb-release jq nano iputils iproute net-tools bind-utils procps-ng git

# Export Container Filesystem
docker stop $containerName
docker export --output=$exportedTar $containerName

# Prepare WSL Directory
New-Item -Path $wslDistroPath -ItemType Directory -Force

# Import Filesystem to WSL
wsl --import $wslDistroName $wslDistroPath $exportedTar

# Cleanup
Remove-Item $exportedTar
docker rm $containerName

# Verify Installation
wsl -d $wslDistroName -e bash -c "echo 'CBL-Mariner is now installed and configured in WSL!'"
