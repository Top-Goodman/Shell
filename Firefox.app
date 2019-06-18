#Unmount any Firefox dmg
hdiutil unmount "/Volumes/Firefox"
#delete any Firefox dmg
rm Firefox.dmg
#Download latest firefox directly from Mozilla 
curl -L -o Firefox.dmg "http://download.mozilla.org/?product=firefox-latest&os=osx&lang=en-US" && wait%1
#Mount downloaded dmg
hdiutil mount -nobrowse Firefox.dmg -mountpoint "/Volumes/Firefox" && wait%1
cp was causing wierd graphical bugs with app so I used rsync instead. Copies "syncs" Firefox.app to Appliucations folder
rsync -r "/Volumes/Firefox/Firefox.app/" /Applications/Firefox.app/ && wait%1
#Unmount any Firefox dmg
hdiutil unmount "/Volumes/Firefox"
#Delete any Firefox dmg
rm Firefox.dmg 
