#!/bin/sh

echo  
echo "**** Config node master with k8s, Docker and Helm *****"
echo   

echo 
echo "**** update repository package ****"
echo 

apt-get update

echo 
echo "**** disable swap ****"
echo 

swapoff -a
cp /etc/fstab /etc/fstab.bkp
sed -i.bak '/ swap / s/^\(.*\)$/#/g' /etc/fstab

echo 
echo "**** Add GPG key for Docker repository ****"
echo 

apt-get install ca-certificates curl gnupg lsb-release
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo 
echo "**** Add Docker repository ****"
echo 

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo 
echo "**** install repository packages kubernetes ****"
echo 

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat << EOF | tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

echo 
echo "**** update repository package ****"
echo 

apt-get update

echo 
echo "**** install kubectl, kubeadm and kubelet ****"
echo 

apt-get -y install docker.io
apt-get -y install kubectl
apt-get -y install kubeadm
apt-get -y install kubelet
apt-mark hold docker-ce kubelet kubeadm

systemctl enable kubelet
