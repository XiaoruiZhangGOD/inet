#!/bin/bash

# create TAP interface
sudo ip tuntap add mode tap dev tap0

# assign IP addresses to interface
sudo ip addr add 192.168.2.2/24 dev tap0

# bring up interface
sudo ip link set dev tap0 up

# run simulation
inet -u Cmdenv -c ExtUpperIeee80211InterfaceInHost2 --sim-time-limit=2s &> inet.out

# check output
if grep -q "from 192.168.2.2" "inet.out"; then echo $0 ": PASS"; else echo $0 ": FAIL"; firm *.out

# destroy TAP interface
sleep 1
sudo ip tuntap del mode tap dev tap0

