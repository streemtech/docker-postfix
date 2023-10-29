#!/usr/bin/env bats

load /code/scripts/common.sh
load /code/scripts/common-run.sh

declare temporary_file
declare dir_debian="/usr/lib/postfix/sbin"
declare dir_alpine="/usr/libexec/postfix"
declare dir_temp


setup() {
    temporary_file="$(mktemp -t)"
    dir_temp="$(mktemp -d)"
    mkdir -p "${dir_temp}"
    cp /etc/postfix/main.cf "${temporary_file}"

    rm -rf "${dir_debian}.bak" "${dir_alpine}.bak"
    if [[ -d "${dir_debian}" ]]; then
        cp -r "${dir_debian}" "${dir_temp}/postfix"
        mv "${dir_debian}" "${dir_debian}.bak"
    fi

    if [[ -d "${dir_alpine}" ]]; then
        cp -r "${dir_alpine}" "${dir_temp}/postfix"
        mv "${dir_alpine}" "${dir_alpine}.bak"
    fi

}

teardown() {
    rm -rf "${dir_temp}"

    if [[ -d "${dir_debian}.bak" ]]; then
        mv ${dir_debian}.bak ${dir_debian}
    fi

    if [[ -d "${dir_alpine}.bak" ]]; then
        mv ${dir_alpine}.bak ${dir_alpine}
    fi

    cat "${temporary_file}" > /etc/postfix/main.cf
    rm -rf "${temporary_file}"
}

@test "Test if Debian/Ubuntu directory remains the same when run on Debian/Ubuntu" {
    local daemon_directory

    rm -rf "${dir_debian}" "${dir_alpine}"
    error "$(ls -lah ${dir_temp})"
    cp -r "${dir_temp}/postfix" "${dir_debian}"
    do_postconf -e "daemon_directory=${dir_debian}"
    postfix_upgrade_daemon_directory
    postfix check
    rm -rf "${dir_debian}" "${dir_alpine}"
    [ "$(get_postconf "daemon_directory")" == "${dir_debian}" ]
}

@test "Test if Debian/Ubuntu directory gets changes the same when run on Alpine" {
    local daemon_directory

    rm -rf "${dir_debian}" "${dir_alpine}"
    cp -r "${dir_temp}/postfix" "${dir_debian}"
    do_postconf -e "daemon_directory=${dir_debian}"
    postfix_upgrade_daemon_directory
    postfix check
    rm -rf "${dir_debian}" "${dir_alpine}"
    [ "$(get_postconf "daemon_directory")" == "${dir_alpine}" ]
}

@test "Test if Alpine directory remains the same when run on Alpine" {
    local daemon_directory

    rm -rf "${dir_debian}" "${dir_alpine}"
    cp -r "${dir_temp}/postfix" "${dir_alpine}"
    do_postconf -e "daemon_directory=${dir_alpine}"
    postfix_upgrade_daemon_directory
    postfix check
    rm -rf "${dir_debian}" "${dir_alpine}"
    [ "$(get_postconf "daemon_directory")" == "${dir_alpine}" ]
}

@test "Test if Alpine directory gets changes the same when run on Debian/Ubuntu" {
    local daemon_directory

    rm -rf "${dir_debian}" "${dir_alpine}"
    cp -r "${dir_temp}/postfix" "${dir_alpine}"
    do_postconf -e "daemon_directory=${dir_alpine}"
    postfix_upgrade_daemon_directory
    postfix check
    rm -rf "${dir_debian}" "${dir_alpine}"
    [ "$(get_postconf "daemon_directory")" == "${dir_debian}" ]
}

@test "Test if things work with custom directory" {
    local daemon_directory

    do_postconf -e "daemon_directory=${dir_temp}/postfix"
    postfix_upgrade_daemon_directory
    postfix check
    rm -rf "${dir_debian}" "${dir_alpine}"
    [ "$(get_postconf "daemon_directory")" == "${dir_temp}" ]
}
