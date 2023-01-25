#!/bin/sh
#len.pgh@gmail.com
#Simple way to list, add, and remove ip's from iptables

stage1() {

 while true;do
    read -p "Block an ip? (yes/no/show/lines/remove_line/exit) " yno
    case $yno in
        [Yy]*) stage2;;
        [Nn]*) stage3;;
        [Ee]*) exit 0;;
        [Ss]*) stage0;;
        [Ll]*) stage4;;
        [Rr]*) stage5;;
            *) echo "Done";;
    esac
done

}


stage2() {

#ip address to block
read -p "Enter IP Address to block: " badips

# blocked ip summary
echo "-----------------------------";
echo "";
echo "-----------------------------";
echo "Blocking this IP Address: $badips";
echo "";

#iptables block command
for badip in $badips; do
        iptables -I INPUT -s ${badip} -j DROP
done
while true;do
    read -p "Block another IP? " yesno
    case $yesno in
        [Yy]* ) stage2;;
        [Nn]* ) stage3;;
        * ) echo "Try Again ";;
    esac
done

}

stage3() {

##
#apt-get remove iptables-persistent -y --force-yes
#echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
#echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
#apt-get install -y --force-yes iptables-persistent
echo "cleaning up a bit, one moment please";
echo "";

##less noise with remove/install of iptables

apt-get remove -qq -o=Dpkg::Use-Pty=0 iptables-persistent
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
apt-get install -qq -o=Dpkg::Use-Pty=0 iptables-persistent

echo "-----------------------------";
echo "saving iptables";
echo "";
echo "have a great day!";
echo "-----------------------------";
echo ""


exit 0
}
#stage1

stage0() {

show () {
command iptables -L -v
}
show


}


stage4() {

show_lines () {
command iptables -L -v --line-numbers
}
show_lines

}

stage5() {


#iptables -D INPUT

read -p  "Which iptables chain name " chain_name
read -p  "Remove which iptables line number " remove_numbers
#for remove_number in $remove_numbers; do
echo    'iptables -D INPUT' $remove_numbers;
command iptables -D $chain_name $remove_numbers;
#done

}


stage1
exit 0
