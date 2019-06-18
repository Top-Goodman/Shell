#Unmount any Chrome.dmg volumes
hdiutil unmount "/Volumes/Google Chrome"
#delete Google dmg
rm googlechrome.dmg
#get latest stable release of Chrome web browser from google
curl -L -O "https://dl.google.com/chrome/mac/stable/GGRO/googlechrome.dmg"
#Silently mount the DMG downloaded from Google
hdiutil mount -nobrowse googlechrome.dmg
#Copy the app to Applications
cp -r "/Volumes/Google Chrome/Google Chrome.app/" "/Applications/Google Chrome.app/"
#Unmount any Chrome.dmg volumes
hdiutil unmount "/Volumes/Google Chrome"
#delete Google dmg
rm googlechrome.dmg
