#!/usr/bin/env bash
############################################################################
# sha3sum.sh
#	Copyright 2020-2025 OneCD
#
# Contact:
#	one.cd.only@gmail.com
#
# Description:
#   This script is part of the 'sha3sum' package
#
# Community forum:
#   https://community.qnap.com/t/qpkg-sha3sum-cli/1099
#
# QPKG source:
#   https://github.com/OneCDOnly/sha3sum
#
# Project source:
#   https://codeberg.org/maandree/sha3sum
#   https://codeberg.org/maandree/libkeccak
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
[[ -L /dev/fd ]] || ln -fns /proc/self/fd /dev/fd		# KLUDGE: `/dev/fd` isn't always created by QTS.
readonly r_user_args_raw=$*

Init()
    {

    readonly r_qpkg_name=sha3sum

    # KLUDGE: mark QPKG installation as complete.

    /sbin/setcfg $r_qpkg_name Status complete -f /etc/config/qpkg.conf

    # KLUDGE: 'clean' the QTS 4.5.1+ App Center notifier status.

    [[ -e /sbin/qpkg_cli ]] && /sbin/qpkg_cli --clean $r_qpkg_name &> /dev/null

    readonly r_qpkg_version=$(/sbin/getcfg $r_qpkg_name Version -f /etc/config/qpkg.conf)
    readonly r_service_action_pathfile=/var/log/$r_qpkg_name.action
    readonly r_service_result_pathfile=/var/log/$r_qpkg_name.result

    }

StartQPKG()
	{

    if IsNotQPKGEnabled; then
        echo -e "This QPKG is disabled. Please enable it first with:\n\tqpkg_service enable $r_qpkg_name"
        return 1
    else
        ln -sf $(/sbin/getcfg $r_qpkg_name Install_Path -f /etc/config/qpkg.conf)/*sum /usr/bin/
        ln -sf $(/sbin/getcfg $r_qpkg_name Install_Path -f /etc/config/qpkg.conf)/lib/libkeccak.so /usr/lib/
        ln -sf /usr/lib/libkeccak.so /usr/lib/libkeccak.so.1
        ln -sf /usr/lib/libkeccak.so /usr/lib/libkeccak.so.1.2
        echo 'application links created'
    fi

	}

StopQPKG()
	{

    rm -f /usr/bin/sha3*sum
    rm -f /usr/bin/keccack*sum
    rm -f /usr/bin/rawshake*sum
    rm -f /usr/bin/shake*sum
    rm -f /usr/lib/libkeccak*
    echo 'application links removed'

    }

ShowTitle()
    {

    echo "$(ShowAsTitleName) $(ShowAsVersion)"

    }

ShowAsTitleName()
	{

	TextBrightWhite $r_qpkg_name

	}

ShowAsVersion()
	{

	printf '%s' "v$r_qpkg_version"

	}

ShowAsUsage()
    {

    echo -e "\nUsage: $0 {start|stop|restart|status}"
    echo -e "\nTo launch the application: sha3sum -h"

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

    echo "$service_action" > "$r_service_action_pathfile"

	}

CommitServiceResult()
	{

    echo "$service_result" > "$r_service_result_pathfile"

	}

TextBrightWhite()
	{

	[[ -n ${1:-} ]] || return

    printf '\033[1;97m%s\033[0m' "${1:-}"

	}

IsQPKGEnabled()
	{

	# Inputs: (local)
	#   $1 = (optional) package name to check. If unspecified, default is $r_qpkg_name

	# Outputs: (local)
	#   $? = 0 : true
	#   $? = 1 : false

	[[ $(Lowercase "$(/sbin/getcfg ${1:-$r_qpkg_name} Enable -d false -f /etc/config/qpkg.conf)") = true ]]

	}

IsNotQPKGEnabled()
	{

	# Inputs: (local)
	#   $1 = (optional) package name to check. If unspecified, default is $r_qpkg_name

	# Outputs: (local)
	#   $? = 0 : true
	#   $? = 1 : false

	! IsQPKGEnabled "${1:-$r_qpkg_name}"

	}

Lowercase()
	{

	/bin/tr 'A-Z' 'a-z' <<< "${1:-}"

	}

Init

user_arg=${r_user_args_raw%% *}		# Only process first argument.

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
