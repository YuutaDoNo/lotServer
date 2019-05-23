#!/bin/bash
#
# Original Author: MoeClub.org
#
# Modified by Aniverse
# 2019.04.25, v4

usage_guide() {
bash <(wget --no-check-certificate -qO- https://github.com/YuutaDoNo/lotServer/raw/master/lotServer.sh) I b
}

[[ $EUID -ne 0 ]] && { echo "ERROR: This script must be run as root!" ; exit 1 ; }

function pause() { echo ; read -p "Press Enter to Continue ..." INP ; }

mkdir -p /tmp
cd /tmp

function dep_check()
{
  apt-get >/dev/null 2>&1
  [ $? -le '1' ] && apt-get -y -qq install sed grep gawk ethtool ca-certificates >/dev/null 2>&1
  yum >/dev/null 2>&1
  [ $? -le '1' ] && yum -y -q install sed grep gawk ethtool >/dev/null 2>&1
}

function acce_check()
{
  local IFS='.'
  read ver01 ver02 ver03 ver04 <<<"$1"
  sum01=$[$ver01*2**32]
  sum02=$[$ver02*2**16]
  sum03=$[$ver03*2**8]
  sum04=$[$ver04*2**0]
  sum=$[$sum01+$sum02+$sum03+$sum04]
  [ "$sum" -gt '12885627914' ] && echo "1" || echo "0"
}

function generate_lic() {
acce_ver=$(acce_check ${KNV})

# [[ $(which php) ]] && Lic=local
[[ -z $Lic ]] && Lic=b
[[ $Lic == a ]] && LicURL="https://api.moeclub.org/lotServer?ver=${acce_ver}&mac=${Mac}" # https://moeclub.azurewebsites.net?ver=${acce_ver}&mac=${Mac}
# https://github.com/MoeClub/lotServer/compare/master...wxlost:master
[[ $Lic == b ]] && LicURL="https://118868.xyz/keygen.php?ver=${acce_ver}&mac=${Mac}"
# https://github.com/MoeClub/lotServer/compare/master...Jack8Li:master
[[ $Lic == c ]] && LicURL="https://backup.rr5rr.com/LotServer/keygen.php?ver=${acce_ver}&mac=${Mac}"
# https://github.com/MoeClub/lotServer/compare/master...ouyangmland:master
[[ $Lic == d ]] && LicURL="https://www.speedsvip.com/keygen.php?mac=${Mac}"
[[ $Lic =~ (a|b|c|d) ]] && wget -O "${AcceTmp}/etc/apx.lic" "$LicURL"

[[ $Lic == local ]] && {
which php > /dev/null || Uninstall "Error! No php found"
apt-get install -y php
which php > /dev/null || Uninstall "Error! No php found"
git clone https://github.com/Tai7sy/LotServer_KeyGen
cd LotServer_KeyGen
git checkout b9f13eb
php keygen.php $Mac
mv out.lic ${AcceTmp}/etc/apx.lic
cd ..
rm -rf LotServer_KeyGen ; }

[ "$(du -b ${AcceTmp}/etc/apx.lic |cut -f1)" -lt '152' ] && Uninstall "Error! I can not generate the Lic for you, Please try again later. "
echo "Lic generate success! " ; }

function Install()
{
  echo 'Preparatory work...'
  Uninstall;
  dep_check;
  [ -f /etc/redhat-release ] && KNA=$(awk '{print $1}' /etc/redhat-release)
  [ -f /etc/os-release ] && KNA=$(awk -F'[= "]' '/PRETTY_NAME/{print $3}' /etc/os-release)
  [ -f /etc/lsb-release ] && KNA=$(awk -F'[="]+' '/DISTRIB_ID/{print $2}' /etc/lsb-release)
  KNB=$(getconf LONG_BIT)
  [ ! -f /proc/net/dev ] && echo -ne "I can not find network device! \n\n" && exit 1;
  Eth_List=`cat /proc/net/dev |awk -F: 'function trim(str){sub(/^[ \t]*/,"",str); sub(/[ \t]*$/,"",str); return str } NR>2 {print trim($1)}'  |grep -Ev '^lo|^sit|^stf|^gif|^dummy|^vmnet|^vir|^gre|^ipip|^ppp|^bond|^tun|^tap|^ip6gre|^ip6tnl|^teql|^venet' |awk 'NR==1 {print $0}'`
  [ -z "$Eth_List" ] && echo "I can not find the server pubilc Ethernet! " && exit 1
# Eth=$(echo "$Eth_List" |head -n1)
  Eth=$(ip route get 8.8.8.8 | awk '{print $5}')
  [ -z "$Eth" ] && Uninstall "Error! Not found a valid ether. "
  Mac=$(cat /sys/class/net/${Eth}/address)
  [ -z "$Mac" ] && Uninstall "Error! Not found mac code. "
  URLKernel='https://github.com/YuutaDoNo/lotServer/raw/master/lotServer.log'
  AcceData=$(wget --no-check-certificate -qO- "$URLKernel")
  AcceVer=$(echo "$AcceData" |grep "$KNA/" |grep "/x$KNB/" |grep "/$KNK/" |awk -F'/' '{print $NF}' |sort -nk 2 -t '_' |tail -n1)
  MyKernel=$(echo "$AcceData" |grep "$KNA/" |grep "/x$KNB/" |grep "/$KNK/" |grep "$AcceVer" |tail -n1)
  [ -z "$MyKernel" ] && echo -ne "Kernel not be matched! \nYou should change kernel manually, and try again! \n\nView the link to get details: \n"$URLKernel" \n\n\n" && exit 1
  KNN=$(echo "$MyKernel" |awk -F '/' '{ print $2 }') && [ -z "$KNN" ] && Uninstall "Error! Not Matched. "
  KNV=$(echo "$MyKernel" |awk -F '/' '{ print $5 }') && [ -z "$KNV" ] && Uninstall "Error! Not Matched. "
  AcceRoot="/tmp/lotServer"
  AcceTmp="${AcceRoot}/apxfiles"
  AcceBin="acce-"$KNV"-["$KNA"_"$KNN"_"$KNK"]"
  mkdir -p "${AcceTmp}/bin/"
  mkdir -p "${AcceTmp}/etc/"
  wget --no-check-certificate -qO "${AcceTmp}/bin/${AcceBin}" "https://github.com/YuutaDoNo/lotServer/raw/master/${MyKernel}"
  [ ! -f "${AcceTmp}/bin/${AcceBin}" ] && Uninstall "Download Error! Not Found ${AcceBin}. "
  wget --no-check-certificate -qO "/tmp/lotServer.tar" "https://github.com/YuutaDoNo/lotServer/raw/master/lotServer.tar"
  tar -xvf "/tmp/lotServer.tar" -C /tmp
  generate_lic
  sed -i "s/^accif\=.*/accif\=\"$Eth\"/" "${AcceTmp}/etc/config"
  sed -i "s/^apxexe\=.*/apxexe\=\"\/appex\/bin\/$AcceBin\"/" "${AcceTmp}/etc/config"
  bash "${AcceRoot}/install.sh" -in 1000000 -out 1000000 -t 0 -r -b -i ${Eth}
  rm -rf /tmp/*lotServer* >/dev/null 2>&1
  if [ -f /appex/bin/serverSpeeder.sh ]; then
    bash /appex/bin/serverSpeeder.sh status
  elif [ -f /appex/bin/lotServer.sh ]; then
    bash /appex/bin/lotServer.sh status
  fi
  exit 0
}

function Uninstall()
{
  AppexName="lotServer"
  [ -e /appex ] && chattr -R -i /appex >/dev/null 2>&1
  if [ -d /etc/rc.d ]; then
    rm -rf /etc/rc.d/init.d/serverSpeeder >/dev/null 2>&1
    rm -rf /etc/rc.d/rc*.d/*serverSpeeder >/dev/null 2>&1
    rm -rf /etc/rc.d/init.d/lotServer >/dev/null 2>&1
    rm -rf /etc/rc.d/rc*.d/*lotServer >/dev/null 2>&1
  fi
  if [ -d /etc/init.d ]; then
    rm -rf /etc/init.d/*serverSpeeder* >/dev/null 2>&1
    rm -rf /etc/rc*.d/*serverSpeeder* >/dev/null 2>&1
    rm -rf /etc/init.d/*lotServer* >/dev/null 2>&1
    rm -rf /etc/rc*.d/*lotServer* >/dev/null 2>&1
  fi
  rm -rf /etc/lotServer.conf >/dev/null 2>&1
  rm -rf /etc/serverSpeeder.conf >/dev/null 2>&1
  [ -f /appex/bin/lotServer.sh ] && AppexName="lotServer" && bash /appex/bin/lotServer.sh uninstall -f >/dev/null 2>&1
  [ -f /appex/bin/serverSpeeder.sh ] && AppexName="serverSpeeder" && bash /appex/bin/serverSpeeder.sh uninstall -f >/dev/null 2>&1
  rm -rf /appex >/dev/null 2>&1
  rm -rf /tmp/*${AppexName}* >/dev/null 2>&1
  [ -n "$1" ] && echo -ne "$AppexName has been removed! \n" && echo "$1" && echo -ne "\n\n\n" && exit 0
}

if [ $# == '1' ]; then
  [ "$1" == 'install' ] && KNK="$(uname -r)" && Install;
  [ "$1" == 'uninstall' ] && Uninstall "Done.";
elif [ $# == '2' ]; then
  [ "$1" == 'install' ] && KNK="$2" && Install;
  [ "$1" == 'I' ] && KNK="$(uname -r)" && Lic=$2 && Install;
elif [ $# == '3' ]; then
  [ "$1" == 'I' ] && KNK="$2" && Lic=$3 && Install;
else
  echo -ne "Usage:\n     bash $0 [install |uninstall |install '{Kernel Version}']\n"
fi
