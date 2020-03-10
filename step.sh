#!/bin/bash
set -eu

case "$OSTYPE" in
  linux*)
    echo "Configuring for Ubuntu"

    echo "Preparing CA"
    echo "${ca_crt}" > /etc/openvpn/ca.crt
    echo "Preparing TA"
    echo "${ta_key}" > /etc/openvpn/ta.key
    echo "Preparing Cert"    
    echo "${client_crt}" > /etc/openvpn/cert.crt
    echo "Preparing Key"    
    echo "${client_key}" > /etc/openvpn/key.txt

    cat <<EOF > /etc/openvpn/client.conf
client
dev tun
proto ${proto}
remote ${host} ${port} 
resolv-retry infinite
nobind
persist-key
persist-tun
comp-lzo
verb 3
ca /etc/openvpn/ca.crt
tls-auth /etc/openvpn/ta.key
cert /etc/openvpn/cert.crt
key /etc/openvpn/key.txt
cipher AES-256-CBC
auth SHA256
tls-client
tls-version-min 1.2
remote-cert-tls server
setenv CLIENT_CERT 0
key-direction 1
EOF
    # We start the VPN service. By default, openvpn takes the client.conf file from the path /etc/openvpn
    service openvpn start
    sleep 5

    if ifconfig | grep tun0 > /dev/null
    then
      echo "VPN connection succeeded"
    else
      echo "VPN connection failed!"
      exit 1
    fi
    ;;
  darwin*)
    
    echo "${ca_crt}" > ca.crt
    echo "${ta_key}" > ta.key
    echo "${client_crt}" > cert.crt
    echo "${client_key}" > key.txt

    # We call openvpn as a command, indicating all the necessary parameters by command line
    sudo openvpn --client --tls-client --remote-cert-tls server --resolv-retry infinite --dev tun --proto ${proto} --remote ${host} ${port} --key key.txt --cert cert.crt --auth SHA256 --persist-key --persist-tun --compress lz4-v2 --cipher AES-256-CBC --ca ca.crt --tls-auth ta.key --key-direction 1 > /dev/null 2>&1 &
    
    sleep 5

    if ifconfig -l | grep utun0 > /dev/null
    then
      echo "VPN connection succeeded"
    else
      echo "VPN connection failed!"
      exit 1
    fi
    ;;
  *)
    echo "Unknown operative system: $OSTYPE, exiting"
    exit 1
    ;;
esac
