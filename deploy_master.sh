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
echo "**** config deamon cgroup ****"
echo 

echo '{"exec-opts": ["native.cgroupdriver=systemd"],"log-driver": "json-file","log-opts": {"max-size": "100m"},"storage-driver": "overlay2"}' > /etc/docker/daemon.json


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

echo 
echo "**** init cluster ****"
echo 

kubeadm config images pull
kubeadm init

mkdir -p $HOME/.kube 
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown  $(id -u):$(id -g)  $HOME/.kube/config

echo 
echo "**** autocompletion kubectl ****"
echo 

echo "source <(kubectl completion bash)" >> $HOME/.bashrc

echo 
"**** pod network - flannel net ****"
echo 

kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

echo 
echo "**** install helm ****"
echo 

curl -L https://git.io/get_helm.sh | bash

helm init

kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'

echo 
echo "**** view status cluster ****"
echo

kubectl get nodes,svc,deploy,rs,rc,po -o wide

echo 
echo "**** add node worker with token ****"
echo 

kubeadm token create --print-join-command

echo 
echo "finish install" 
