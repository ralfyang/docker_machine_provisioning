#!/bin/bash
hname=$1

Cpu="1"
Mem="2048"
Disk="30000"
default_pw="1q2w3e"

  if [[ $hname = "" ]];then
    hname="default"
  fi

sshkey_check(){
	if [[ ! -f $HOME/.ssh/id_rsa ]];then
		ssh-keygen -f $HOME/.ssh/id_rsa -t rsa -N ''
	fi
	return 0
}

Base_cmd="/usr/local/bin/docker-machine"

$Base_cmd 2> /tmp/chk_perm
	if [[ $(grep Permission /tmp/chk_perm) != "" ]];then
		eacho " Please run with 'sudo' as below"
		eacho " 'sudo mgmt.sh'"
		rm -f /tmp/chk_perm
		exit 1
	fi



Create(){
	sshkey_check
	# User set
	Host_name="$hname"
	Driver="virtualbox"
	
	$Base_cmd create -d $Driver --virtualbox-disk-size "$Disk" --virtualbox-cpu-count $Cpu --virtualbox-memory $Mem $Host_name
	$Base_cmd ssh $Host_name "tce-load -wi bash; curl -sL bit.ly/startdockertool |bash"
	$Base_cmd ssh $Host_name "echo -e '$default_pw\n$default_pw' | sudo passwd docker"
	
	## Sysctl for the ElasticSearch
	$Base_cmd ssh $Host_name "cat /etc/sysctl.conf > /tmp/sysctl.conf && echo 'vm.max_map_count=262144' >> /tmp/sysctl.conf  && sudo mv /tmp/sysctl.conf /etc/sysctl.conf"
}

List(){
	$Base_cmd ls
}


stop(){
	$Base_cmd  stop $hname
}

connection(){
	$Base_cmd ssh $hname
}

start(){
	$Base_cmd start $hname
}

reboot(){
	$Base_cmd stop $hname
	$Base_cmd start $hname
}

remove(){
	echo " Are sure that remove the Virtual machine ? [ y ]"
	read sure
	if [[ $sure = "y" ]];then
		$Base_cmd rm  $hname -y
	fi
}

application_install(){
	mkdir -p ~/tmp
        cd ~/tmp
  	arch=`uname -s`-`uname -m`
	os=`uname -s`

  	case $os in
    	Linux)
      		## VirtualBox install
      		sudo apt-add-repository "deb http://download.virtualbox.org/virtualbox/debian $(lsb_release -sc) contrib"
      		#wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -
		curl -sL https://www.virtualbox.org/download/oracle_vbox_2016.asc -o oracle_vbox.asc && sudo apt-key add oracle_vbox.asc
      		sudo apt-get update
      		sudo apt-get install virtualbox-5.2  -y
   		;;

    	Darwin)
            	## VirtualBox Download & Install
            	VirtualBox_installer="http://download.virtualbox.org/virtualbox/5.2.2/VirtualBox-5.2.2-119230-OSX.dmg"
            	VirtualBox_file=$(echo "$VirtualBox_installer" | awk -F'/' '{print $NF}')
            	curl -sL $VirtualBox_installer -o $VirtualBox_file
            	sudo hdiutil attach $VirtualBox_file
            	sudo installer -pkg /Volumes/VirtualBox/VirtualBox.pkg -target /
            	hdiutil unmount /Volumes/VirtualBox/
            	rm -f ./$VirtualBox_file
	    	;;
    	esac
  
	## Install Referece by http://www.sauru.so/blog/provision-docker-node-with-docker-machine
	gh="https://github.com"
	gh_raw="https://raw.githubusercontent.com"
	repo="docker/machine"
	version="v0.14.0"
	
	# now it is standard exec path for users.
	mkdir -p $HOME/.local/bin $HOME/.bash_completion.d/
	
	curl -fsSL -o $HOME/.local/bin/docker-machine \
	        $gh/$repo/releases/download/$version/docker-machine-$arch
	chmod +x $HOME/.local/bin/docker-machine
	sudo cp -f $HOME/.local/bin/docker-machine /usr/local/bin/docker-machine
}

clear
BARR="=============================================================="
echo "$BARR"
echo " What do you want with docker-machine ?"
echo "$BARR"
echo "[0] Install the Virtualbox & docker-machine"
echo "[1] Create VM & login"
echo "[2] Login to VM"
echo "[3] Stop VM"
echo "[4] Start VM"
echo "[5] Reboot VM"
echo "[RM] Remove VM"
echo "$BARR"
echo -n " Please insert a key as you need = "
read choice
echo "$BARR"

	case $choice in
		0)
			application_install;;
		1)
			Create;;
		2)
			connection;;
		3)
			stop;;
		4)
			start;;
		5)
			reboot;;
		RM|rm)
			remove;;
	esac
echo ""
echo "$BARR"
List 
echo "$BARR"
