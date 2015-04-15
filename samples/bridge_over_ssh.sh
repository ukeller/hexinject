#!/bin/sh
# A device with MAC 00:...:15 is connected to p5p1 on this host and we want to bridge it to p4p1 on a remote host (only 1 device)
# Can be achieved with ssh -w any Tunnel=etherent and brctl, however this feature is currently broken on Ubuntu

#REMOTE_=../hexinject
#REMOTE_="ssh -p 2222 root@localhost /home/ukeller/hexinject/hexinject"
REMOTE_="ssh root@localhost \"/home/ukeller/hexinject/hexinject"
_REMOTE="\""
LOCAL_=../hexinject
_LOCAL=""

OUTFACING=p4p1
INFACING=p5p1
MAC=00:01:02:03:04:05
BCST=00:00:00:00:00:00
cleanup() {
    echo "cleaning up"
    offload_enable $OUTFACING
    offload_enable $INFACING
    true
}

offload_disable() {
    ethtool --offload  $1  gso off gro off
    true
}
offload_enable() {
    ethtool --offload  $1  gso on gro on
    true
}
cleanup
trap cleanup INT
offload_disable $OUTFACING
offload_disable $INFACING

parallel -v -u -j 100 ::: \
                   "$REMOTE_ -r -t 0 -s -i $OUTFACING -f '(ether dst $MAC or ether dst $BCST) and not ether src $MAC' $_REMOTE | $LOCAL_ -r -S -C  -p -i $INFACING $_LOCAL"  \
                   "$LOCAL_ -r -t 0 -s -i $INFACING  -f '(ether src $MAC) and not ether dst $MAC $_LOCAL' | $REMOTE_ -r -S -C  -p -i $OUTFACING $_REMOTE"
