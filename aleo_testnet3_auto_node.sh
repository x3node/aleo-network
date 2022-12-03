#!/bin/bash
# aleo testnet3 
# Follow twitter: https://twitter.com/gaszlla
#
# -------- Run the following command-------------
# sudo su
# cd ~ && wget -O /root/aleo_testnet3_auto_node.sh https://raw.githubusercontent.com/x3node/aleo-network/main/aleo_testnet3_auto_node.sh && chmod +x aleo_testnet3_auto_node.sh
# 
# Run node:
# cd ~
# bash aleo_testnet3_auto_node.sh
#------------------------------------------------

Workspace=/root/aleo-prover
ScreenName=aleo
KeyFile="/root/my_aleo_key.txt"

is_root() {
	[[ $EUID != 0 ]] && echo -e "Current user is root user, please run `sudo su`" && exit 1
}

# Check if Screen exists
# 0 = Yes   1 = No
has_screen(){
	Name=`screen -ls | grep ${ScreenName}`
	if [ -z "${Name}" ]
	then
		return 1
	else
		echo "Screen is running: ${Name}"
		return 0
	fi
}

# Check private_key
# 0 = Yes  1 = No
has_private_key(){
	PrivateKey=$(cat ${KeyFile} | grep "Private key" | awk '{print $3}')	
	if [ -z "${PrivateKey}" ]
	then
		echo "Private key doesn't exist."
		return 1
	else
		echo "Private key has been read correctly."
		return 0
	fi
}

## Generate private key
generate_key(){
	cd ${Workspace}
	echo "Generating private key"
	./target/release/aleo-prover --new-address > ${KeyFile}

	has_private_key || exit 1

}


# Enter screen mode
go_into_screen(){
	screen -D -r ${ScreenName}

}

# Force kill screen
kill_screen(){
	Name=`screen -ls | grep ${ScreenName}`
        if [ -z "${Name}" ]
        then
		echo "No running screen"
		exit 0
        else
		ScreenPid=${Name%.*}
		echo "Force kill screen: ${Name}"
		kill ${ScreenPid}
		echo "Force kill complete"
        fi
}

# Install snarkos
install_snarkos(){
	# check root user
	is_root

	mkdir ${Workspace}
        cd ${Workspace}

	# Install tools and dependency
	sudo apt update
	sudo apt install git

	apt-get update
	apt-get install -y \
	    build-essential \
	    curl \
	    clang \
	    gcc \
	    libssl-dev \
	    llvm \
	    make \
	    pkg-config \
	    tmux \
	    xz-utils



	echo "Start installing rust"
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh  -s -- -y
	source $HOME/.cargo/env
	echo "rust installed successfully"

        echo "Openning ports 4133, 4140 and 3033"
        sudo ufw allow 4133
        sudo ufw allow 3033
        sudo ufw allow 4140
        echo "Ports are opened."


	# cpu optimization
        echo "Download HarukaMa/aleo-prover optimization code"
        git clone https://github.com/gaszlla/aleo-prover.git --depth 1 ${Workspace}
	cargo build --release
        echo "prover compilation done"


	echo "Install screen"
	apt install screen
	echo "screen installed."

	# Check or generate new private key
	has_private_key || generate_key


	echo "Private key is stored in ${KeyFile}:"
	cat ${KeyFile}
}

# Run prover node
run_prover(){
	source $HOME/.cargo/env

	cd ${Workspace}

	# Check if screen running
        has_screen && echo "executing command 4, go into screen" && exit 1
	# check if private key exists
        has_private_key || exit 1

	# Start screen, and run prover
        screen -dmS ${ScreenName}
	PrivateKey=$(cat ${KeyFile} | grep "Private key" | awk '{print $3}')
        echo "Using private key ${PrivateKey} and starting prover"
	ThreadNum=`cat /proc/cpuinfo |grep "processor"|wc -l`  
        cmd=$"./target/release/aleo-prover -p ${PrivateKey} -t ${ThreadNum}"
	echo ${cmd}

        screen -x -S ${ScreenName} -p 0 -X stuff "${cmd}"
        screen -x -S ${ScreenName} -p 0 -X stuff $'\n'
        echo "client node has started in screen, run command 4 to check the status"
}

echo && echo -e " 
aleo testnet3 auto start node: 
Follow twitter:   https://twitter.com/gaszlla
 ———————————————————————
 1.Install Aleo
 2.Run Aleo Prover node
 3.Check your Aleo Address and Private Key
 4.Enter Screen and check node status, ctrl+A+D to exist Screen
 5.Force kill screen (warning: using kill to stop Screen, using with caution)
 ———————————————————————
 " && echo

read -e -p " enter [1-5]:" num
case "$num" in
1)
	install_snarkos
    	;;
2)
    	run_prover
    	;;
3)
    	cat ${KeyFile}
    	;;
4)
	go_into_screen
	;;
5)	
	kill_screen
	;;

*)
    echo
    echo -e "Please enter a number."
    ;;
esac
