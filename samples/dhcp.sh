#!/bin/bash
#Replaces data in a dhcp packet on a bridge containing p4p1 and p5p1, only dhcp passes through hexinject
#The other traffic goes through the bridge (see brctl ...)

search_="7D 26 ..."
replace="7D 26 ..."
         
cleanup() {
echo "cleaning up"
iptables -t mangle -F
iptables -t mangle -F DHCP_MANGLE >/dev/null
iptables -t mangle -X DHCP_MANGLE >/dev/null
}

setupiptables() {
iptables -t mangle -N DHCP_MANGLE
iptables -t mangle -A POSTROUTING -p udp --sport 67 -j DHCP_MANGLE
iptables -t mangle -A DHCP_MANGLE -m limit --limit 2/min -j LOG --log-prefix "Dropped to mangle: " --log-level 4
iptables -t mangle -A DHCP_MANGLE -j DROP
}


trap cleanup EXIT
trap cleanup INT
cleanup
setupiptables
../hexinject -s -i p4p1 -f 'udp and port 67' | sed "s/$search_/$replace/gi"| ../hexinject -p -i p5p1

