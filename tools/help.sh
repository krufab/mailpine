#!/usr/bin/env bash

function print_configuration_help() {
  cat <<EOF
Mailpine - configuration
Usage: ${0} [options]

 -d --debug   Set services in debug mode
 -h --help    This help
 -l --list    Show the list of available services
 -r --run     Run services after configuration
 -R --restart Restart services after configuration
 -s --service [service] Configure / run / restart the specific service
                Can be used multiple times
 -v --verbose Print out a verbose output of this script

EOF
}

function print_configuration_services() {
  cat <<EOF
Mailpine config services:
 certificates mail mailpine mariadb opendkim opendmarc spf web
EOF
}

function print_run_help() {
  cat <<EOF
Mailpine - run
Usage: ${0} [options]

 -h --help    This help
 -l --list    Show the list of available services
 -R --restart Restart services after configuration
 -s --service [service] Configure / run / restart the specific service
                Can be used multiple times

EOF
}

function print_run_services() {
  cat <<EOF
Mailpine run services:
 mail mariadb opendkim opendmarc spf web
EOF
}

function print_stop_help() {
  cat <<EOF
Mailpine - stop
Usage: ${0} [options]

 -h --help    This help
 -l --list    Show the list of available services
 -s --service [service] Configure / run / restart the specific service
                Can be used multiple times

EOF
}

function print_stop_services() {
  cat <<EOF
Mailpine stop services:
 mail mariadb opendkim opendmarc spf web
EOF
}
