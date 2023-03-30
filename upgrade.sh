#!/bin/bash


DATE=$(date +"%d-%m-%Y");
hostip=`ip addr show |grep "inet " |grep -v 127.0.0. |cut -d" " -f6|cut -d/ -f1  | xargs`
hostname=`hostname`
lvm=`pvs && vgs && lvs`
kernel=`uname -a`
netstat=`netstat -rn`
df=`df -h`
ifconfig=`ifconfig -a`
ipa=`ip a`






create_file(){
path="/root/sonda/upgrade"
mkdir -p $path
local name=$1
if [[ -e $path/$name || -L $path/$name ]] ; then
    i=0
    while [[ -e $path/$name-$i || -L $path/$name-$i ]] ; do
        let i++
    done
    name=$name-$i
fi
touch  "$path/$name"
echo "$path/$name"

}


upgrade_rpm(){
yum makecache > /dev/null
yum list -q installed > $pre_packages
count_pre=$(cat $pre_packages | egrep '(.i386|.x86_64|.noarch|.src|.all)' | wc -l)
script -q -c "stty cols 150; yum check-update --security" /dev/null > $check 2>&1
count_check=$(cat $check | egrep '(.i386|.x86_64|.noarch|.src|.all)' | wc -l)
echo "Iniciando Actualizacion"
yum clean all
script -q -c "stty cols 150; yum upgrade --security  -y " /dev/null > $report 2>&1
echo "Actualizacion Terminada"
yum list -q installed > $pos_packages
count_post=$(cat $pos_packages | egrep '(.i386|.x86_64|.noarch|.src)' | wc -l)
}
upgrade_deb(){
dpkg --list > $pre_packages
count_pre=$(cat $pre_packages | egrep '(.i386|.x86_64|.noarch|.src)' | wc -l)
script -q -c "stty cols 150; apt-get update" /dev/null > $pkg_update 2>&1
script -q -c "stty cols 150; apt-get -s upgrade --only-upgrade | grep -i security" /dev/null > $check 2>&1
count_check=$(cat $check | egrep '(.i386|.x86_64|.noarch|.src)' | wc -l)
echo "Iniciando Actualizacion"
apt-get clean
script -q -c "stty cols 150; apt-get upgrade --only-upgrade -y " /dev/null > $report 2>&1
echo "Actualizacion Terminada"
dpkg --list  > $pos_packages
count_post=$(cat $pos_packages | egrep '(.i386|.x86_64|.noarch|.src|.all)' | wc -l)
}
upgrade_os(){
pre_packages="$(create_file "packages-pre-upgrade")"
pos_packages="$(create_file "packages-post-upgrade")"
pkg_update="$(create_file "pkg-update")"
check="$(create_file "check-pre-upgrade")"
report="$(create_file "report-upgrade")"
echo "Generando reporte pre-actualizacion"


if dpkg -S /bin/ls >/dev/null 2>&1
then

upgrade_deb
 
elif rpm -q -f /bin/ls >/dev/null 2>&1
then

#PID=$( lsof /var/run/yum.pid | awk '{print $2}')

#if [ -n "$PID" ]; then
#    echo "Cerrando proceso de yum (PID: $PID)..."
#    sudo kill -9 $PID
#fi

upgrade_rpm

else
  result="NO DATA"
fi






}


boot_system="$(create_file "boot-system")"
info_system="$(create_file "info-system")"

if ! command -v lsb_release -a &> /dev/null ;
then
    cat /etc/os-release >> $info_system
else
    lsb_release -ar >> $info_system
fi

echo "$lvm" >> $info_system
echo "$kernel" >> $info_system
echo "$netstat" >> $info_system
echo "$df" >> $info_system
echo "$ifconfig" >> $info_system
echo "$ipa" >> $info_system
if [ -f /var/log/boot.log ];then
cat /var/log/boot.log >> $boot_system
fi

upgrade_os

exclude=""
final_report="$(create_file "final-report")"
echo "$hostname,$hostip,$DATE,$count_pre,$count_check,$count_post,$exclude" > $final_report 



