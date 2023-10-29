#!/usr/bin/env bats

load /code/scripts/common.sh
load /code/scripts/common-run.sh


@test "verify reading of daemon_directory" {
    local daemon_directory
    local old_daemon_directory
    local dir_debian="/usr/lib/postfix/sbin"
    local dir_alpine="/usr/libexec/postfix"
    local dir_temp="/tmp/deamon_directory"
    old_daemon_directory="$(get_postconf "daemon_directory")"

    rm -rf "${dir_debian}.bak" "${dir_alpine}.bak"
    if [[ -d "${dir_debian}" ]]; then
        cp -r ${dir_debian} ${dir_temp}
        mv ${dir_debian} ${dir_debian}.bak
    fi

    if [[ -d "${dir_alpine}" ]]; then
        cp -r ${dir_alpine} ${dir_temp}
        mv ${dir_alpine} ${dir_alpine}.bak
    fi

    # Test if Debian/Ubuntu directory remains the same when run on Debian/Ubuntu
    cp -r ${dir_temp} ${dir_debian}
    do_postconf -e "daemon_directory=${dir_debian}"
    postfix_upgrade_daemon_directory
    postfix check
    rm -rf ${dir_debian} ${dir_alpine}
    [ "$(get_postconf "daemon_directory")" == "${dir_debian}" ]

    # Test if Debian/Ubuntu directory gets changes the same when run on Alpine
    cp -r ${dir_temp} ${dir_alpine}
    do_postconf -e "daemon_directory=${dir_debian}"
    postfix_upgrade_daemon_directory
    postfix check
    rm -rf ${dir_debian} ${dir_alpine}
    [ "$(get_postconf "daemon_directory")" == "${dir_alpine}" ]

    # Test if Alpine directory remains the same when run on Alpine
    cp -r ${dir_temp} ${dir_alpine}
    do_postconf -e "daemon_directory=${dir_alpine}"
    postfix_upgrade_daemon_directory
    postfix check
    rm -rf ${dir_debian} ${dir_alpine}
    [ "$(get_postconf "daemon_directory")" == "${dir_alpine}" ]

    # Test if Alpine directory gets changes the same when run on Debian/Ubuntu
    cp -r ${dir_temp} ${dir_debian}
    do_postconf -e "daemon_directory=${dir_alpine}"
    postfix_upgrade_daemon_directory
    postfix check
    rm -rf ${dir_debian} ${dir_alpine}
    [ "$(get_postconf "daemon_directory")" == "${dir_debian}" ]

    # Test if things work with custom directory
    do_postconf -e "daemon_directory=${dir_temp}"
    postfix_upgrade_daemon_directory
    postfix check
    rm -rf ${dir_debian} ${dir_alpine}
    [ "$(get_postconf "daemon_directory")" == "${dir_temp}" ]

    rm -rf ${dir_temp}

    if [[ -d "${dir_debian}.bak" ]]; then
        mv ${dir_debian}.bak ${dir_debian}
    fi

    if [[ -d "${dir_alpine}.bak" ]]; then
        mv ${dir_alpine}.bak ${dir_alpine}
    fi

    do_postconf -e "daemon_directory=${old_daemon_directory}"
}
