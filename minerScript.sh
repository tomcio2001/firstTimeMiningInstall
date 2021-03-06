#!/bin/bash
#made by steemit user omotherhen
#This is a script for a first time setup of a miner, done in a VM for a fresh install of Ubuntu 16.04
#base install for steem miner
cd ~
sudo apt-get -y install openssh-server 
sudo apt-get update 
sudo apt-get -y upgrade 
sudo apt-get -y install zip unzip cmake g++ python-dev autotools-dev libicu-dev build-essential libbz2-dev libboost-all-dev libssl-dev libncurses5-dev doxygen libreadline-dev dh-autoreconf screen 
git clone https://github.com/steemit/steem && cd steem && git checkout v0.12.0 && git submodule update --init --recursive && cmake -DCMAKE_BUILD_TYPE=Release-DLOW_MEMORY_NODE=ON . && make
clear


#needed for vanitygen, creating private keys
sudo apt-get -y install libpcre3-dev 
cd ~ 
git clone https://github.com/samr7/vanitygen 
cd vanitygen && make 
ranStr=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 2 | head -n 1) 
echo "Generating private key for your miners..." 
privKey=$(./vanitygen "1$ranStr" | grep Privkey) 
formattedPrivKey=${privKey#* } 
clear

cd ~
#arrays for storing valid miner names and their private keys
declare -a minerArr
declare -a witnessArr

echo "How many threads do you want to mine on?"
echo "This is the number of CPU cores you have, unless you have hyperthreading on, then it is double the amount of cores"
read cores
mining_threads="mining-threads = $cores"


echo "How many steem accounts would you like to make?"
read acc
i="0"
while [ $i -lt $acc ]
do
 echo
 echo "Enter in a name for Miner$i"
 echo "MAKE SURE YOU DO NOT ENTER IN THE SAME NAME TWICE"
 echo "Usernames must be all lowercase and start with a lower case letter and contain no special characters/spaces"
 echo "In addition to above restrictions, usernames must be 3+ characters, can't start with a number, can use . and - to create segments but the segments have to be at least three letters and can't be more than 16 characters long"

 read name
 wget -q  https://steemd.com/@$name
 wgetStatus=$?
 rm -f @*
 if [ $wgetStatus -gt 0 ]
  then
  echo "Name available! Miner account $i is: $name"
  minerArr[$i]="miner = [\"$name\",\"$formattedPrivKey\"]"
  witnessArr[$i]="witness = \"$name\""
  i=$[$i+1]
 else
  echo "Name taken or invalid, try another name"
 fi
done

i="0"
echo "Here are your witness + miner accounts and their corresponding WIF Key"
while [ $i -lt $acc ]
do
 echo
 echo "Witnesses: ${witnessArr[$i]}"
 echo "Miner account names and their private key: ${minerArr[$i]}"
 i=$[$i+1]
done

cd ~/steem/programs/steemd
./steemd &
PID=$!
sleep 3
kill $PID

echo "Modifying your ~/steem/programs/steemd/witness_node_data_dir/config.ini file"
cd  ~/steem/programs/steemd/witness_node_data_dir/

#TODO
#in config.ini replace "# seed-node = "

str="seed-node = 212.117.213.186:2016\n"
str+="seed-node = 185.82.203.92:2001\n"
str+="seed-node = 52.74.152.79:2001\n"
str+="seed-node = 52.63.172.229:2001\n"
str+="seed-node = 104.236.82.250:2001\n"
str+="seed-node = 104.199.157.70:2001\n"
str+="seed-node = steem.kushed.com:2001\n"
str+="seed-node = steemd.pharesim.me:2001\n"
str+="seed-node = seed.steemnodes.com:2001\n"
str+="seed-node = steemseed.dele-puppy.com:2001\n"
str+="seed-node = seed.steemwitness.com:2001\n"
str+="seed-node = seed.steemed.net:2001\n"
str+="seed-node = steem-seed1.abit-more.com:2001\n"
str+="seed-node = steem.clawmap.com:2001\n"
str+="seed-node = 52.62.24.225:2001\n"
str+="seed-node = steem-id.altexplorer.xyz:2001\n"
str+="seed-node = 213.167.243.223:2001\n"
str+="seed-node = 162.213.199.171:34191\n"
str+="seed-node = 45.55.217.111:12150\n"
str+="seed-node = 212.47.249.84:40696\n"
str+="seed-node = 52.4.250.181:39705\n"
str+="seed-node = 81.89.101.133:2001\n"
str+="seed-node = 46.252.27.1:1337\n"

sed -i "s/# seed-node =/&\n$str/" config.ini


#Replace "# rpc-endpoint = "
#with    "rpc-endpoint = 127.0.0.1:8090"
sed -i 's/# rpc-endpoint = /rpc-endpoint = 127.0.0.1:8090/' config.ini


#Replace "# witness = "
#with contents of witnessArr[], with each index being on a new line"
str=""
witness_count=${#witnessArr[*]}
index=0
while [ "$index" -lt "$witness_count" ]
do
	str+="${witnessArr[$index]}\n"
	index=$[$index+1]
done
sed -i "s/# witness =/&\n$str/" config.ini


#Replace "#  miner = "
#with contents of minerArr[], with each index being  on a new line"

str=""
miner_count=${#minerArr[*]}
index=0
while [ "$index" -lt "$miner_count" ]
do
	str+="${minerArr[$index]}\n"
	index=$[$index+1]
done
sed -i "s/# miner =/&\n$str/" config.ini


#Replace "# mining-threads"
#with contents of $mining_threads
sed -i "s/# mining-threads =/$mining_threads/" config.ini

echo "Boot-strapping blockchain for fast setup, then starting the miner!"
cd ~/steem/programs/steemd/witness_node_data_dir/blockchain/database/ && wget http://einfachmalnettsein.de/steem-blocks-and-index.zip && unzip -o steem-blocks-and-index.zip && cd ../../../ && ./steemd --replay

#TODO
#Setup automatic backup of blockchain for future compiling
