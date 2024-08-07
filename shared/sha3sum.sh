#!/usr/bin/env bash
############################################################################
# sha3sum.sh
#	copyright 2020-2024 OneCD
#
# Contact:
#	one.cd.only@gmail.com
#
# This script is part of the 'sha3sum' package
#
# QPKG source: [https://github.com/OneCDOnly/sha3sum]
# Community forum: https://forum.qnap.com/viewtopic.php?t=157827
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

set -o nounset -o pipefail
shopt -s extglob
ln -fns /proc/self/fd /dev/fd		# KLUDGE: `/dev/fd` isn't always created by QTS.

readonly USER_ARGS_RAW=$*

Init()
    {

    readonly QPKG_NAME=sha3sum

    # KLUDGE: mark QPKG installation as complete.
    /sbin/setcfg "$QPKG_NAME" Status complete -f /etc/config/qpkg.conf

    # KLUDGE: 'clean' the QTS 4.5.1+ App Center notifier status.
    [[ -e /sbin/qpkg_cli ]] && /sbin/qpkg_cli --clean "$QPKG_NAME" > /dev/null 2>&1

    readonly QPKG_VERSION=$(/sbin/getcfg $QPKG_NAME Version -f /etc/config/qpkg.conf)
	readonly SERVICE_ACTION_PATHFILE=/var/log/$QPKG_NAME.action
	readonly SERVICE_RESULT_PATHFILE=/var/log/$QPKG_NAME.result

    }

StartQPKG()
	{

    if IsNotQPKGEnabled; then
        echo -e "This QPKG is disabled. Please enable it first with:\n\tqpkg_service enable $QPKG_NAME"
        return 1
    else
        ln -sf $(/sbin/getcfg $QPKG_NAME Install_Path -f /etc/config/qpkg.conf)/*sum /usr/bin/
        ln -sf $(/sbin/getcfg $QPKG_NAME Install_Path -f /etc/config/qpkg.conf)/lib/libkeccak.so /usr/lib/
        ln -sf /usr/lib/libkeccak.so /usr/lib/libkeccak.so.1
        ln -sf /usr/lib/libkeccak.so /usr/lib/libkeccak.so.1.2
    fi

	}

StopQPKG()
	{

    rm -f /usr/bin/sha3*sum
    rm -f /usr/bin/keccack*sum
    rm -f /usr/bin/rawshake*sum
    rm -f /usr/bin/shake*sum
    rm -f /usr/lib/libkeccak*

    }

ShowTitle()
    {

    echo "$(ShowAsTitleName) $(ShowAsVersion)"

    }

ShowAsTitleName()
	{

	TextBrightWhite $QPKG_NAME

	}

ShowAsVersion()
	{

	printf '%s' "v$QPKG_VERSION"

	}

ShowAsUsage()
    {

    echo -e "\nUsage: $0 {start|stop|restart|status}"
    echo -e "\nTo launch: sha3sum"

	}

StatusQPKG()
	{

    if [[ -L /usr/bin/sha3sum ]]; then
        echo active
        exit 0
    else
        echo inactive
        exit 1
    fi

	}

SetServiceAction()
	{

	service_action=${1:-none}
	CommitServiceAction
	SetServiceResultAsInProgress

	}

SetServiceResultAsOK()
	{

	service_result=ok
	CommitServiceResult

	}

SetServiceResultAsFailed()
	{

	service_result=failed
	CommitServiceResult

	}

SetServiceResultAsInProgress()
	{

	# Selected action is in-progress and hasn't generated a result yet.

	service_result=in-progress
	CommitServiceResult

	}

CommitServiceAction()
	{

    echo "$service_action" > "$SERVICE_ACTION_PATHFILE"

	}

CommitServiceResult()
	{

    echo "$service_result" > "$SERVICE_RESULT_PATHFILE"

	}

TextBrightWhite()
	{

	[[ -n ${1:-} ]] || return

    printf '\033[1;97m%s\033[0m' "$1"

	}

IsQPKGEnabled()
	{

	# input:
	#   $1 = (optional) package name to check. If unspecified, default is $QPKG_NAME

	# output:
	#   $? = 0 : true
	#   $? = 1 : false

	[[ $(Lowercase "$(/sbin/getcfg "${1:-$QPKG_NAME}" Enable -d false -f /etc/config/qpkg.conf)") = true ]]

	}

IsNotQPKGEnabled()
	{

	# input:
	#   $1 = (optional) package name to check. If unspecified, default is $QPKG_NAME

	# output:
	#   $? = 0 : true
	#   $? = 1 : false

	! IsQPKGEnabled "${1:-$QPKG_NAME}"

	}

Lowercase()
	{

	/bin/tr 'A-Z' 'a-z' <<< "$1"

	}

Init

user_arg=${USER_ARGS_RAW%% *}		# Only process first argument.

case $user_arg in
    ?(-)r|?(--)restart)
        SetServiceAction restart

        if StopQPKG && StartQPKG; then
            SetServiceResultAsOK
        else
            SetServiceResultAsFailed
        fi
        ;;
    ?(--)start)
        SetServiceAction start

        if StartQPKG; then
            SetServiceResultAsOK
        else
            SetServiceResultAsFailed
        fi
        ;;
    ?(-)s|?(--)status)
        StatusQPKG
        ;;
    ?(--)stop)
        SetServiceAction stop

        if StopQPKG; then
            SetServiceResultAsOK
        else
            SetServiceResultAsFailed
        fi
        ;;
    *)
        ShowTitle
        ShowAsUsage
esac

exit 0
