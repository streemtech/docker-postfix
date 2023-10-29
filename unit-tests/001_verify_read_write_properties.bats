#!/usr/bin/env bats

load /code/scripts/common.sh
load /code/scripts/common-run.sh


@test "verify reading and writting propreties" {
    local value
    local old_value
    old_value="$(get_postconf "mydestination")"

    do_postconf -# mydestination

    value="$(get_postconf "mydestination")"
    if [[ -n "${value}" ]]; then
        echo "Expected '', got: '$value' for 'mydestination'" >&2
        exit 1
    fi

    do_postconf -e 'mydestination=$myhostname, localhost.$mydomain $mydomain'

    value="$(get_postconf "mydestination")"
    if [[ "${value}" != 'mydestination=$myhostname, localhost.$mydomain $mydomain' ]]; then
        echo "Expected 'mydestination=\$myhostname, localhost.\$mydomain \$mydomain', got: '$value' for mydestination" >&2
        exit 1
    fi

    do_postconf -# mydestination
    echo "           mydestination    =       localhost" >> /etc/postfix/main.cf

    value="$(get_postconf "mydestination")"
    if [[ "${value}" != "localhost" ]]; then
        echo "Expected 'localhost', got: '$value' for mydestination" >&2
        exit 1
    fi

    do_postconf -e "mydestination=${old_value}"
}
