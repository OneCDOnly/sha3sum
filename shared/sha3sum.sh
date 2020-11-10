#!/usr/bin/env bash
############################################################################
# sha3sum.sh - (C)opyright 2020 OneCD [one.cd.only@gmail.com]
#
# This script is part of the 'sha3sum' package
#
# For more info: [https://forum.qnap.com/viewtopic.php?f=320&t=157827]
#
# Available in the Qnapclub Store: [https://qnapclub.eu/en/qpkg/1030]
# QPKG source: [https://github.com/OneCDOnly/sha3sum]
# Project source: [https://github.com/maandree/sha3sum]
# Project source: [https://github.com/maandree/libkeccak]
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see http://www.gnu.org/licenses/.
############################################################################

case "$1" in
    start)
        ln -sf $(/sbin/getcfg sha3sum Install_Path -f /etc/config/qpkg.conf)/*sum /usr/bin/
        ln -sf $(/sbin/getcfg sha3sum Install_Path -f /etc/config/qpkg.conf)/lib/libkeccak.so /usr/lib/
        ln -sf /usr/lib/libkeccak.so /usr/lib/libkeccak.so.1
        ln -sf /usr/lib/libkeccak.so /usr/lib/libkeccak.so.1.2
        ;;
    stop)
        rm -f /usr/bin/sha3*sum
        rm -f /usr/bin/keccack*sum
        rm -f /usr/bin/rawshake*sum
        rm -f /usr/bin/shake*sum
        rm -f /usr/lib/libkeccak*
        ;;
    restart)
        $0 stop
        $0 start
        ;;
    *)
        echo "run init as: $0 {start|stop|restart}"
        echo "to launch: sha3sum"
        ;;
esac

exit 0
