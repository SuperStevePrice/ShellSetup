#!/usr/bin/env ksh
sudo route delete -inet6 default fe80::%utun0
sudo route delete -inet6 default fe80::%utun1
sudo route delete -inet6 default fe80::%utun2
sudo route delete -inet6 default fe80::%utun3
