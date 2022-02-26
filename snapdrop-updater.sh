#!/bin/bash

error() {
  echo -e "\e[91m$1\e[39m"
  exit 1
}

if ! command -v node >/dev/null;then
  error "node command not found"
fi

if ! command -v nativefier >/dev/null ;then
  echo "installing nativefier"
  sudo npm install -g nativefier || error "command failed: 'npm install -g nativefier'"
fi

cd /tmp

urls='https://github.com/ryanfortner/snapdrop-rpi/raw/master/snapdrop_20220226_arm64.deb
https://github.com/ryanfortner/snapdrop-rpi/raw/master/snapdrop_20220226_armv7l.deb'

IFS=$'\n'
for url in $urls ;do
  #download the deb
  wget -O "$(pwd)/package.deb" "$url" || error "failed to download $url"
  
  #extract the deb.
  echo "extracting..."
  rm -rf "$(pwd)/package"
  nice dpkg-deb -R "$(pwd)/package.deb" "$(pwd)/package" || error "failed to extract package.deb"
  
  #rebuild the nativefier folder.
  originalfolder="$(echo "$(pwd)/package/opt"/*)"
  nativefier --upgrade "$originalfolder" || error "nativefier failed to upgrade version of $originalfolder"
  
  #update the version number to today's date
  date="$(date +%Y%m%d)" || error "failed to determine today's date"
  sed -i "s/Version: .*/Version: $date/g" "$(pwd)/package/DEBIAN/control" || error "sed failed to update the date"
  
  #package back into deb
  nice dpkg-deb -b "$(pwd)/package" "$(pwd)/package.deb" || error "Failed to turn the folder back into a deb"
  
  #remove the extracted folder
  rm -rf "$(pwd)/package"
  
  #rename the deb, based on original url but update the date
  newfile="$(pwd)/$(basename "$url" | sed "s/20....../$date/g")"
  mv -f "$(pwd)/package.deb" "$newfile" || error "failed to rename package.deb to $newfile"
  
  echo -e "\nFinished deb: $newfile\n"
  
  finished="$finished
$newfile"
  
done

echo "Deb creation complete. These files have been generated:$finished"
