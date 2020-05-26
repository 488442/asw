#!/bin/bash

echo "===================================="
echo "installing kubernetes (with kubeadm)"
echo "===================================="

# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

# let iptables see bridged traffic
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

# installing kubeadm, kubelet and kubectl

apt-get update && sudo apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# l'applicativo kubelet richiede lo swapoff
# see https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
# see https://askubuntu.com/questions/214805/how-do-i-disable-swap

swapoff -a
# setto lo swapoff anche per il post reboot
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# risolvo l'ip della macchina attuale
IP_ADDR=`ifconfig eth1 | grep inet | awk '{print $2}'| cut -f2 -d:`

# see https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/kubelet-integration/
# creo il file /etc/default/kubelet , se inesistente
if [[ ! -e /etc/default/kubelet ]]; then
    touch /etc/default/kubelet
fi

# see https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/kubelet-integration/
# see https://kubernetes.io/docs/tasks/administer-cluster/reserve-compute-resources/
# aggiungo informazioni aggiuntive per la configurazione di kubelet e 
# consentire la creazione corretta del cluster (è l'equivalente di override.conf per il demone docker)
# v1: echo -e "KUBELET_EXTRA_ARGS=--node-ip=$IP_ADDR --cgroup-driver=cgroupfs" >> /etc/default/kubelet
echo -e "KUBELET_EXTRA_ARGS=--node-ip=$IP_ADDR --cgroup-driver=systemd" >> /etc/default/kubelet

systemctl daemon-reload
systemctl restart kubelet