#!/bin/sh
chown root:root /etc/postfix/sender_dependent_relayhost
postmap /etc/postfix/sender_dependent_relayhost

chown root:root /etc/postfix/sasl_password
postmap /etc/postfix/sasl_password

chown root:root /etc/postfix/smtp_tls_policy
postmap /etc/postfix/smtp_tls_policy
