#!/usr/bin/env bash


#IFS=$'\n' SORTED=($(sort <<<"${DOMAINS[*]}"))
#IFS=$'\n' UNIQUE=($(uniq <<<"${SORTED[*]}"))
#echo "${UNIQUE[@]}"


# wget -O /usr/bin/yq  https://github.com/mikefarah/yq/releases/download/3.2.1/yq_linux_arm64
# chmod +x /usr/bin/yq
#rsync -ahv --exclude-from=mailpine-rsync-exclude.txt -e ssh . kft:/home/ubuntu/docker/mailpine

#shellcheck -x -e SC2206,SC2207 tools/*.sh
# fail2ban-client set mp_nginx unbanip 81.11.204.63

# iptables -I INPUT -p tcp --dport 1022 -j ACCEPT