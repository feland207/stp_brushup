 Spanning Tree Protocol (STP):
 =============================

       ┌──────────┐
       │  Host01  │
       └─────┬────┘
         eth1│     
             │     
             │     
         eth3│     
       ┌─────┴────┐eth1                    eth1┌──────────┐
       │   SW01   ├────────────────────────────┤   SW02   │
       └─────┬────┘                            └─────┬────┘
             │eth2                               eth2│
             │                                       │
             │                                       │
             │                                       │
             │         eth2┌──────────┐eth1          │
             └─────────────┤   SW03   ├──────────────┘
                           └─────┬────┘
                             eth3│     
                                 │     
                                 │     
                                 │eth1 
                           ┌─────┴────┐
                           │  Host03  │
                           └──────────┘


## How STP works
STP works by blocking ports to create a Layer2 Ethernet loop free topology. We know Ethernet does not have TTL field, this can be the problem when we have
BUM traffic and loops.

Key considerations:
- STP uses BPDUs for its signaling. BPDUs are sent in only one direction and downstream hence a port that is blocked, does not send BPDUs.
- ARP is a Layer 3 protocol. It's how an IP device discovers which MAC address corresponds to an IP address. ARP runs at the host/gateway level.
- The ARP table (ip neigh) on sw1 is sw1's own IP-level neighbor cache, used only if sw1 itself needs to send IP traffic to someone (like pinging sw1's own br0 address).
- Unknown unicast frames keep their original destination MAC. — whatever MAC host1 put in the Ethernet header when it built the ICMP frame. If host1 already resolved host3's MAC as aa:c1:ab:xx:xx:xx via ARP, that real MAC stays in the destination field. The frame looks completely normal at the Ethernet level.
- The difference in one sentence: broadcast is "I want everyone to receive this" (explicit, in the frame). Unknown unicast flood is "I don't know where to send this so I'll send it everywhere"
- The Root Bridge sends BPDUs from all its ports; All its ports are DP.
- Non-root bridges sends BPDUs only in their Designated Ports (DP).

### Ports roles:
Root Port (RP): Every switch has only one RP. This are for upstream packets. The RP is the best path to the root bridge. It forwards BPDUs.
Designated Port (DP): Forwards root's BPDUs one hop further downstream. DPs will always connect to RP or to non-DP ports.
Non-designated Port (NDP): Silently listen for BPDUs; Never forwardsdata or BPDUs.

### Root election process
Force a switch to become root by lowering its priority
sudo ip link set dev br0 type bridge priority 4096

### Link failure and convergence timing
See how slow classic 802.1D STP actually is to reconverge — the exact reason RSTP superseded it.

##### On sw1: tear down the currently-forwarding inter-switch link
sudo ip link set eth1 down
sleep 45
sudo ip link set eth1 up

From host1 to host3 we should observe 30% packet lost:
64 bytes from 192.168.99.103: icmp_seq=99 ttl=64 time=0.095 ms
64 bytes from 192.168.99.103: icmp_seq=100 ttl=64 time=0.080 ms

--- 192.168.99.103 ping statistics ---
100 packets transmitted, 70 received, 30% packet loss, time 101368ms
rtt min/avg/max/mdev = 0.074/0.107/0.157/0.018 ms
deployer@host1:~$     

##### On sw2 and/or sw1: port cycle: blocking -> listening -> learning -> forwarding
watch -n0.5 'sudo bridge link show'


CLI STP Linux commands:
=======================
###### Expect exactly one port, on exactly one switch, in state blocking — the other ports in forwarding
```
sudo ip neigh flush all
sudo bridge fdb flush dev br0

sudo tcpdump -i eth3 -n arp
ip addr show dev br0
ip -d link show br0
# Find which switch is the root bridge — It will be the one with root_path_cost equals to 0
ip -d link show br0 | grep root_path_cost
# See the port states (forwarding and blocking)
sudo bridge link show

# Refreshes every 0.5 seconds, highlights changed lines
watch -n0.5 'sudo bridge link show'
# How the switch forwards frames between ports
sudo bridge fdb show
# Find which interface is used to forward traffic for a given host MAC address
sudo bridge fdb show | grep aa:c1:ab:02:95:06
# Ping (3 pings) with record IP hops
ping -c3 192.168.99.103 -R
```
