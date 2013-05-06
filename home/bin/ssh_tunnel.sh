#!/bin/bash

tunnel_usr=${1:-snoc}
tunnel_dst=${2:-173.193.191.132}

if [ "$tunnel_usr" = "help" -o "$tunnel_usr" = "usage" ]
then
  echo "USAGE: $0 <login id> [target]"
  echo ""
  echo "  ENV VARs:"
  echo "    SSH_TRUST_KEY=/path/to/ssh/trust/key/for/<login id>"
  echo ""
  exit 1
fi

ssh_trust_key=
if [ ! -z "$SSH_TRUST_KEY" ] ; then
  ssh_trust_key="-i $SSH_TRUST_KEY"
  echo "Using [$ssh_trust_key] for user [$tunnel_usr] ..."
fi

out="The following mappings will be created:\n\n"

# Default options ...
#
# -C : Compression on
# -l : User to authenticate with
# -p : Port to connect to
#
ssh_opt="-C -l ${tunnel_usr} -p 22 $ssh_trust_key"
ssh_opt="$ssh_opt -o ServerAliveCountMax=10"
ssh_opt="$ssh_opt -o ServerAliveInterval=30"
ssh_opt="$ssh_opt -o TCPKeepAlive=yes"

# HAProxy stats page ...
ssh_opt="$ssh_opt -L *:18080:10.80.89.74:8080"     # lb VIP
ssh_opt="$ssh_opt -L *:18081:10.80.81.66:8080"     # lb01a
ssh_opt="$ssh_opt -L *:18082:10.80.81.68:8080"     # lb01b
out="$out  HAProxy VIP        http://localhost:18080/symhaproxy?stats\n"
out="$out  HAProxy lb01a      http://localhost:18081/symhaproxy?stats\n"
out="$out  HAProxy lb01b      http://localhost:18082/symhaproxy?stats\n"

# Graphite ...
ssh_opt="$ssh_opt -L *:19092:10.80.81.68:9090"     # lb01b
out="$out  Graphite lb01b     http://localhost:19092/ (primary)\n"

# Support Web
ssh_opt="$ssh_opt -L *:17071:10.80.81.66:7070"     # lb01a
ssh_opt="$ssh_opt -L *:17072:10.80.81.68:7070"     # lb01b
out="$out  Support Web lb01a  http://localhost:17071/ (peer)\n"
out="$out  Support Web lb01b  http://localhost:17072/ (peer)\n"

# MySQL ...
ssh_opt="$ssh_opt -L *:13301:10.60.66.130:3306"    # database01
ssh_opt="$ssh_opt -L *:13302:10.48.127.198:3306"   # database02
ssh_opt="$ssh_opt -L *:13303:10.60.66.144:3306"    # database03
ssh_opt="$ssh_opt -L *:13304:10.48.127.212:3306"   # database04
out="$out  MySQL db01         localhost:13301\n"
out="$out  MySQL db02         localhost:13302\n"
out="$out  MySQL db03         localhost:13303\n"
out="$out  MySQL db04         localhost:13304\n"

# Placement service
ssh_opt="$ssh_opt -L *:12701:10.60.66.138:9001"    # placement01
ssh_opt="$ssh_opt -L *:12702:10.48.127.210:9001"   # placement02
out="$out  Placement01:9001   http://localhost:12701/\n"
out="$out  Placement02:9001   http://localhost:12702/\n"

# FE server-status
ssh_opt="$ssh_opt -L *:12710:10.60.66.132:8088"    # frontend10
ssh_opt="$ssh_opt -L *:12711:10.60.66.134:8088"    # frontend11
ssh_opt="$ssh_opt -L *:12712:10.60.66.142:8088"    # frontend12
ssh_opt="$ssh_opt -L *:12720:10.48.127.194:8088"   # frontend20
ssh_opt="$ssh_opt -L *:12721:10.48.127.196:8088"   # frontend21
ssh_opt="$ssh_opt -L *:12722:10.48.127.200:8088"   # frontend22
out="$out  Frontend10:8088   http://localhost:12710/\n"
out="$out  Frontend11:8088   http://localhost:12711/\n"
out="$out  Frontend12:8088   http://localhost:12712/\n"
out="$out  Frontend20:8088   http://localhost:12720/\n"
out="$out  Frontend21:8088   http://localhost:12721/\n"
out="$out  Frontend22:8088   http://localhost:12722/\n"

#
# M/Monit ...
#

ssh_opt="$ssh_opt -L *:10080:10.80.81.66:10080"    # lb01a

#
# Monit ...
#

ssh_opt="$ssh_opt -L *:12801:10.80.81.66:2812"     # lb01a
ssh_opt="$ssh_opt -L *:12802:10.80.81.68:2812"     # lb01b
ssh_opt="$ssh_opt -L *:12803:10.48.127.206:2812"   # lb01a
ssh_opt="$ssh_opt -L *:12804:10.48.127.208:2812"   # lb01b

ssh_opt="$ssh_opt -L *:12810:10.60.66.132:2812"    # frontend10
ssh_opt="$ssh_opt -L *:12811:10.60.66.134:2812"    # frontend11
ssh_opt="$ssh_opt -L *:12812:10.60.66.142:2812"    # frontend12
ssh_opt="$ssh_opt -L *:12814:10.60.66.136:2812"    # frontend14
ssh_opt="$ssh_opt -L *:12820:10.48.127.194:2812"   # frontend20
ssh_opt="$ssh_opt -L *:12821:10.48.127.196:2812"   # frontend21
ssh_opt="$ssh_opt -L *:12822:10.48.127.200:2812"   # frontend22

ssh_opt="$ssh_opt -L *:12861:10.60.66.130:2812"    # database01
ssh_opt="$ssh_opt -L *:12862:10.48.127.198:2812"   # database02
ssh_opt="$ssh_opt -L *:12863:10.60.66.144:2812"    # database03
ssh_opt="$ssh_opt -L *:12864:10.48.127.212:2812"   # database04

ssh_opt="$ssh_opt -L *:12881:10.60.66.138:2812"    # placement01
ssh_opt="$ssh_opt -L *:12882:10.48.127.210:2812"   # placement02

ssh_opt="$ssh_opt -L *:12891:10.60.66.140:2812"    # operation01

ssh_opt="$ssh_opt -L *:12501:10.41.58.2:2812"      # bootstrap01
ssh_opt="$ssh_opt -L *:12502:10.25.9.196:2812"     # bootstrap02
ssh_opt="$ssh_opt -L *:12503:10.25.9.194:2812"     # bootstrap03
ssh_opt="$ssh_opt -L *:12504:10.8.42.194:2812"     # bootstrap04
ssh_opt="$ssh_opt -L *:12505:10.12.17.66:2812"     # bootstrap05
ssh_opt="$ssh_opt -L *:12506:10.28.201.68:2812"    # bootstrap06
ssh_opt="$ssh_opt -L *:12507:10.28.201.66:2812"    # bootstrap07
ssh_opt="$ssh_opt -L *:12508:10.41.58.4:2812"      # bootstrap08
ssh_opt="$ssh_opt -L *:12509:10.16.106.130:2812"   # bootstrap09
ssh_opt="$ssh_opt -L *:12510:10.41.58.6:2812"      # bootstrap10

ssh_opt="$ssh_opt -L *:12511:10.41.58.8:2812"      # bootstrap11
ssh_opt="$ssh_opt -L *:12512:10.16.106.132:2812"   # bootstrap12
ssh_opt="$ssh_opt -L *:12513:10.21.34.132:2812"    # bootstrap13
ssh_opt="$ssh_opt -L *:12514:10.21.34.130:2812"    # bootstrap14
ssh_opt="$ssh_opt -L *:12515:10.32.181.130:2812"   # bootstrap15
ssh_opt="$ssh_opt -L *:12516:10.32.181.132:2812"   # bootstrap16
ssh_opt="$ssh_opt -L *:12517:10.54.194.130:2812"   # bootstrap17
ssh_opt="$ssh_opt -L *:12518:10.54.194.132:2812"   # bootstrap18
ssh_opt="$ssh_opt -L *:12519:10.54.194.136:2812"   # bootstrap19
ssh_opt="$ssh_opt -L *:12520:10.54.194.134:2812"   # bootstrap20

ssh_opt="$ssh_opt -L *:12521:10.70.76.68:2812"     # bootstrap21
ssh_opt="$ssh_opt -L *:12522:10.70.76.66:2812"     # bootstrap22
ssh_opt="$ssh_opt -L *:12523:10.66.31.136:2812"    # bootstrap23
ssh_opt="$ssh_opt -L *:12524:10.66.31.134:2812"    # bootstrap24
ssh_opt="$ssh_opt -L *:12525:10.66.31.130:2812"    # bootstrap25
ssh_opt="$ssh_opt -L *:12526:10.66.31.132:2812"    # bootstrap26
ssh_opt="$ssh_opt -L *:12527:10.28.201.70:2812"    # bootstrap27
ssh_opt="$ssh_opt -L *:12528:10.54.194.138:2812"   # bootstrap28
ssh_opt="$ssh_opt -L *:12529:10.70.76.74:2812"     # bootstrap29
ssh_opt="$ssh_opt -L *:12530:10.32.181.134:2812"   # bootstrap30

ssh_opt="$ssh_opt -L *:12531:10.70.76.70:2812"     # bootstrap31
ssh_opt="$ssh_opt -L *:12532:10.70.76.72:2812"     # bootstrap32
ssh_opt="$ssh_opt -L *:12533:10.86.11.196:2812"    # bootstrap33
ssh_opt="$ssh_opt -L *:12534:10.86.11.194:2812"    # bootstrap34
ssh_opt="$ssh_opt -L *:12535:10.66.31.138:2812"    # bootstrap35
ssh_opt="$ssh_opt -L *:12536:10.48.127.204:2812"   # bootstrap36
ssh_opt="$ssh_opt -L *:12537:10.48.127.202:2812"   # bootstrap37
ssh_opt="$ssh_opt -L *:12538:10.28.201.72:2812"    # bootstrap38
ssh_opt="$ssh_opt -L *:12539:10.54.194.140:2812"   # bootstrap39
ssh_opt="$ssh_opt -L *:12540:10.70.76.76:2812"     # bootstrap40

out="$out  M/Monit lb01a      http://localhost:10080/\n"
out="$out  Monit   lb01a      http://localhost:12801/\n"
out="$out  Monit   lb01b      http://localhost:12802/\n"
out="$out  Monit   fexx       http://localhost:128xx/\n"
out="$out  Monit   db0x       http://localhost:1286x/\n"
out="$out  Monit   ps0x       http://localhost:1288x/\n"
out="$out  Monit   ops0x      http://localhost:1289x/\n"
out="$out  Monit   bsxx       http://localhost:125xx/\n"

echo -e "$out\n"

ssh $ssh_opt $tunnel_dst

exit 0
