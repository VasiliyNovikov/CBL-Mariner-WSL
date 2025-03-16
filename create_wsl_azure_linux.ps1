# Variables
$dockerImage = 'mcr.microsoft.com/azurelinux/base/core:3.0'
$containerName = 'azurelinux_temp'
$exportedTar = 'azurelinux.tar'
$wslDistroName = 'Azure-Linux'
$wslDistroPath = 'C:\WSL\Azure-Linux'

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
wsl -d $wslDistroName -e bash -c "echo 'Azure-Linux is now installed and configured in WSL!'"
