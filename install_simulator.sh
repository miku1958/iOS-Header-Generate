#!/bin/sh
# 这个脚本安装需要解包镜像, 解包 pkg, 解压 Payload, 所以不如直接从 Xcode 里安装快

set -eo pipefail
shopt -s nullglob

expand_dmg() {
    declare dmg="$2" target="/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS $1.simruntime"
    echo "写入目标: $target"
    sudo rm -rf "$target"
    sudo mkdir -p "$target"

    echo "Expanding $dmg..."
    TMPMOUNT=`/usr/bin/mktemp -d /tmp/dmg.XXXX`
    TMPTARGET=`/usr/bin/mktemp -d /tmp/target.XXXX`
    hdiutil attach "$dmg" -mountpoint "$TMPMOUNT"
    find "$TMPMOUNT" -name '*.pkg' -exec pkgutil --expand "{}" "$TMPTARGET/data" \;
    sudo tar zxf "$TMPTARGET/data/Payload" -C "$target"
    hdiutil detach "$TMPMOUNT"
    rm -rf "$TMPMOUNT"
    rm -rf "$TMPTARGET"
    rm -f "$dmg"
}

# Accept Xcode license
sudo xcodebuild -license accept

# Install Simulators
install_simulator() {
  dmglist=`ls`
  for dmg in $dmglist
  do 
    if [[ $dmg =~ ".dmg" ]]
    then
      version=${dmg#*-}
      version=${version%.*}
      version=${version%.*}
      version=${version%.*}
      echo "处理中镜像: $dmg"
      echo "获取版本: $version"
      expand_dmg $version $dmg
    fi
  done
}

install_simulator
