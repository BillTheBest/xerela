package DataThreeDNS;

use strict;
use warnings;
use Exporter 'import';
our @EXPORT_OK = qw($responsesThreeDNS);

our $responsesThreeDNS = {};

$responsesThreeDNS->{license} = <<'END';
cat /config/bigip.license
Auth vers :         5a
#
#
#       BIG-IP/3-DNS License Key File
#       DO NOT EDIT THIS FILE!!
#
#       Install this file as "/config/bigip.license".
#
#       Contact information in file /CONTACTS
#
#
Usage :             Production
#
#
#  Only the specific use referenced above is allowed. Any other uses are prohibited.
#
#
Vendor :            F5 Networks, Inc.
#
Serial :            RIOUG
#
Product Code :      3DNS
#
Licensed Date :     20040824
#
Registration Key :  ADXXQ-CEOSQ-LNMQV-SABLK-RIOUG
#
Licensed version :  4.5.10
#
Platform ID :       F20
#
Platform Data :     watchdog=wdt500
#
Dossier :           01827191f0e76c31a7e0ceb112d57a23e6013608b8e9a436b5509715193d351ca1ec04cadff4d0a9e541fe61c675bbf0ccd0f304f377c7183968ace9ccba89450426913d048b4ddea98e0a99b321042c8d8f95607304757e3e5b7bac63981216ebd683e961eb08ee018b8b458dd45e94e0349e1ed1dc1e0db87e2ac500e058c624c1bf2ae6293bb61213d5099b5de1c503159b78355cb2d73e86d35a80b07005a1b78f2eb8fc9156ef1589b1a37754e49eb8ab6f83fdc717200d868afeea7cd8c72e04848297e031c56221ea8b10c5aa322fbeb14dbbe2db178ec39bd4
#
#------------------------------------------------------------------------------------------
#
Authorization :     a40331b0b854ffa80930035a87ede528608b3993bc70f4526395f2c8da999630da56bc87d1ef22857c1d74a767084ec9a8bbdd1bcef833ad5c2987bf9b32486b363ab5470c7c1b0c87372920ea30431dea5a08eff2d4b7a968ec5ce03fbe75758e04913eb893c08473198fd3170599703230a2b399d2475bf7bc1ba3a9f5ea122bc8a80af5395065ae5237e229ac6eeb56da48fcfd29a1b1488b556dddcc13df8cd104a33702cfec4bb976ad7d1c697ac1cbecedc4c24d55ab9a4f8a6bf66cec40e2b8c9a1ff235a5d6f3faf249cbd53b44f2b017eeafc85812d37dee926a52ecf92609228aa851bc3728322d6effc473b4dd3996a68bf9fb2d038ea3653dd633dns1:~# 

END

$responsesThreeDNS->{snmp} = <<'END';
cat /etc/snmpd.conf

END

$responsesThreeDNS->{ucsv} = <<'END';
cat /config/ucs_version
Product: BIG-IP
Version: 4.5.10
Build: Build84-b
Edition: Global
Built: 040415105403
Date: Apr 15 2004 10:54:03 PDT

END

$responsesThreeDNS->{users} = <<'END';
cat /etc/passwd
root:*:0:0:System Administrator:/root:/bin/bash
daemon:*:1:1:System Daemon:/nonexistent:/sbin/nologin
sys:*:2:2:Operating System:/nonexistent:/sbin/nologin
bin:*:3:7:BSDI Software:/nonexistent:/sbin/nologin
operator:*:5:5:System Operator:/nonexistent:/sbin/nologin
tty:*:6:6:Terminal User:/nonexistent:/sbin/nologin
nobody:*:32767:32766:Unprivileged user:/nonexistent:/sbin/nologin
nonroot:*:65534:32766:Non-root root user for NFS:/nonexistent:/sbin/nologin
ceige:*:0:0:System Administrator:/root:/bin/bash

END

$responsesThreeDNS->{config} = <<'END';

END

$responsesThreeDNS->{hostname} = <<'END';
hostname
3dns1.inside.eclyptic.com

END

$responsesThreeDNS->{dd} = <<'END';
dd bs=65k count=10 skip=15 </dev/mem|strings|grep REV
dd: stdin: Operation not permitted

END

$responsesThreeDNS->{df} = <<'END';
df
Filesystem  1024-blocks     Used    Avail Capacity  Mounted on
/dev/wd0a         63500    33820    26505    56%    /
/dev/wd0h        253540   148552    92311    62%    /usr
/dev/wd0g       1521100   433365  1011680    30%    /var
/dev/wd0e       1014459       55   963681     0%    /3dns
/dev/wd0f         15968     1405    13764     9%    /config
mfs:37            39599        4    37615     0%    /tmp

END

$responsesThreeDNS->{uptime} = <<'END';
uptime
 4:03PM  up 63 days,  5:55, 1 user, load averages: 0.07, 0.08, 0.08

END

$responsesThreeDNS->{dmesg} = <<'END';
dmesg
BIG-IP Kernel 4.5.10 Build84Cpu-0 = Pentium III (551.25 MHz) GenuineIntel mdl 7 step 3 type 0, feat 383f9ff
real mem = 1073725440 (1023.98 MB)
avail mem = 1048264704 (999.70 MB)
buffer cache = 33554432 (32.00 MB)
apm: magic 0x0 flags 0x0
smbios: Version 2.3 [Structure Count = 44]
isa0 (root)
Found motherboard: ASUS P3B-F
pci0 at root: configuration mechanism 1
smb0 at pci0
keyboard disconnected? (code fe)
pccons0 at isa0 iobase 0x60 irq 1: color, 8 screens
com0 at isa0 iobase 0x3f8 irq 4: buffered (16550AF): console
com1 at isa0 iobase 0x2f8 irq 3: buffered (16550AF)
lp0 at isa0 iobase 0x378 irq 7
fdc0 at isa0 iobase 0x3f0 irq 6 drq 2: floppy controller
fd0 at fdc0 slave 0: 1.44M HD 3.5 floppy
pciwdc0 at pci0 iobase 0x1f0: Intel PIIX4 ATA33: DMA disk adaptor
wdc3 at pciwdc0 primary channel, iobase 0x1f0 irq 14: disk controller
wd0 at wdc3 drive 0: mode UDMA33 8421840*512
wdc4 at pciwdc0 secondary channel, iobase 0x170 irq 15: disk controller
wdpi0 at wdc4 drive 0: TOSHIBA CD-ROM XM-6602B rev=1017 
wdpi0: transfer size=2048 polled cmd DRQ
tg0 at wdpi0 target 0
sr0 at tg0 unit 0: CD-ROM: type 0x5, qual 0x80, ver 0 removable
npx0 at isa0 iobase 0xf0: math coprocessor
vga0 at isa0 iobase 0x3c0 maddr 0xa0000-0xaffff: VGA graphics
exp0 at pci0 irq 12 maddr 0xe1800000-0xe1800fff: eaddr 00:90:27:a4:32:a7 rev 8
i555p0 at exp0 phy 1: 10baseT 10baseT-FDX 100baseTX 100baseTX-FDX Auto
exp1 at pci0 irq 10 maddr 0xe0800000-0xe0800fff: eaddr 00:90:27:a4:30:f6 rev 8
i555p1 at exp1 phy 1: 10baseT 10baseT-FDX 100baseTX 100baseTX-FDX Auto
changing root device to wd0a
Initialized Watchdog: WDT-500

CPU: Pentium III (551 MHz)
Memory: 1023 MB
Network Interfaces: 
  5.1 00:90:27:a4:32:a7 (exp0) ether 100BaseTX 10BaseT
  4.1 00:90:27:a4:30:f6 (exp1) ether 100BaseTX 10BaseT
Other Devices: Floppy CDROM Video
3-DNS authorization successful.
3-DNS authorization successful.

END

$responsesThreeDNS->{interfaces} = <<'END';
ifconfig -a
5.1: (exp0) flags=8822<BROADCAST,NOTRAILERS,SIMPLEX,MULTICAST>
        link type ether 0:90:27:a4:32:a7 mtu 1500 speed 10Mbps
        media auto status no-carrier
4.1: (exp1) flags=8963<UP,BROADCAST,NOTRAILERS,RUNNING,PROMISC,SIMPLEX,MULTICAST>
        link type ether 0:90:27:a4:30:f6 mtu 1500 speed 100Mbps
        media auto (100baseTX full_duplex) status active
lo0: flags=8009<UP,LOOPBACK,MULTICAST>
        link type loop mtu 4352
        inet 127.0.0.1 netmask 255.0.0.0
external1: (vlan0) flags=8843<UP,BROADCAST,RUNNING,SIMPLEX,MULTICAST>
        link type vlan 0:90:27:a4:30:f6 mtu 1500
        Interfaces: (tag 4094)
                4.1: (exp1) flags=3<LEARNING,DISCOVER>
        inet 10.100.3.13 netmask 255.255.255.0 broadcast 10.100.3.255
ceige: (vlan1) flags=8843<UP,BROADCAST,RUNNING,SIMPLEX,MULTICAST>
        link type vlan mtu 1500
        Interfaces: (tag 22)

END

$responsesThreeDNS->{stp} = <<'END';
bigpipe stp show
bigpipe:  Error in STP domain list lookup:
        Spanning tree protocol (STP) domains are not available.

END
