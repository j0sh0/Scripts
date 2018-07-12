#!/bin/bash
# Pre-requisites: plexmediaserver, wget, apt, grep, curl, awk, sed
# For Plex Pass downloads to work you need to specify your Plex token otherwise the current public release will be downloaded.
 
 
plexToken=""
# Place your Plex Token here if you have Plex Pass, otherwise leave it blank.
 
downURL="https://plex.tv/downloads/latest/1?channel=8&build=linux-ubuntu-x86_64&distro=ubuntu&X-Plex-Token=$plexToken"
 
scriptDir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
shortDate=$(date +'%d-%m-%Y %H:%M:%S')
 
# get current release PMS version
function getCurrent {
releaseVersion=$(curl -LsI $1 | grep "Location:" | awk -F'/' '{print $5}' | sed 's/-.*//')
}
 
# get installed PMS version
function getInstalled {
installedVersion=$(apt-cache show plexmediaserver | grep "Version:" | awk '{ printf $2; }' | sed 's/-.*//')
}
 
# update PMS
function updatePlex {
echo downloading update...
wget -O plex.deb $1
echo installing update...
dpkg -i plex.deb
echo cleaning up files...
rm plex.deb
echo done!
}
 
getCurrent $downURL
getInstalled
echo Installed Version: $installedVersion
echo Release Version: $releaseVersion
 
#compare version numbers - True outputs 0 to $?
dpkg --compare-versions $installedVersion "lt" $releaseVersion
 
if [ $? = "0" ];
  then
		echo Update Available!
		updatePlex $downURL
		echo "$shortDate - Updated PlexMediaServer from Version:$installedVersion to Version:$releaseVersion " >> "$scriptDir/plexUpdate.log"
	else
		echo "$shortDate - Current version already installed. Version:$installedVersion" >> "$scriptDir/plexUpdate.log"
		echo Server is up to date. Exiting...
 
fi
