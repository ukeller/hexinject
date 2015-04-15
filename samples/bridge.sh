#!/bin/bash
# A device with MAC 00:...:15 is connected to p5p1 and we want to bridge it to p4p1 (only 1 device)
OUTFACING=p4p1
INFACING=p5p1
MAC=00:11:12:13:14:15
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
                   "../hexinject -r -s -i $OUTFACING -f '(ether dst $MAC or ether dst $BCST) and not ether src $MAC' | ../hexinject -r -S -C  -p -i $INFACING"  \
                   "../hexinject -r -s -i $INFACING  -f '(ether src $MAC) and not ether dst $MAC' | ../hexinject -r -S -C  -p -i $OUTFACING" 
                   