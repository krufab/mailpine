#!/usr/bin/env bash

function print_main_help {
  cat <<EOF
Mailpine
Usage: ${0} command [options]

command:
 c configure       Configure mailpine
 h -h help --help  This help
 r run             Run mailpine
 s stop            Stop mailpine
 u update          Update mailpine

For command specific options:
${0} command --help
I.e.: ${0} configure --help

EOF
}

function print_configuration_help {
  cat <<EOF
Mailpine - Configure mailpine
Usage: ${0} c|configure [options]

 -d --debug   Set services in debug mode
 -h --help    This help
 -l --list    Show the list of available services
 -s --service [service] Configure / run / restart the specific service
                Can be used multiple times
 -v --verbose Print out a verbose output of this script

EOF
}

function print_configuration_services {
  cat <<EOF
Mailpine config services:
 antivirus certificates fail2ban mail mailpine mariadb opendkim opendmarc spf web
EOF
}

function print_run_help {
  cat <<EOF
Mailpine - Run mailpine
Usage: ${0} r|run [options]

 -h --help    This help
 -l --list    Show the list of available services
 -R --restart Restart services after configuration
 -s --service [service] Configure / run / restart the specific service
                Can be used multiple times

EOF
}

function print_run_services {
  cat <<EOF
Mailpine run services:
 antivirus fail2ban mail mariadb opendkim opendmarc spf web
EOF
}

function print_stop_help {
  cat <<EOF
Mailpine - Stop mailpine
Usage: ${0} s|stop [options]

 -h --help    This help
 -l --list    Show the list of available services
 -s --service [service] Configure / run / restart the specific service
                Can be used multiple times

EOF
}

function print_stop_services {
  cat <<EOF
Mailpine stop services:
 antivirus fail2ban mail mariadb opendkim opendmarc spf web
EOF
}

function print_update_help {
  cat <<EOF
Mailpine - Stop, configure and relaunch mailpine
Usage: ${0} u|update [options]

 -h --help    This help
 -l --list    Show the list of available services
 -s --service [service] Configure / run / restart the specific service
                Can be used multiple times

EOF
}
