#Place this file in/etc/profile.d/
#Make it executble sudo chmod +x /etc/profile.d/linux_motd.sh
#version 2.1 - Written by Alfredo Jo ® - 2024

#Random colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
WHITE='\033[0;37m'
RESET='\033[0m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
BRIGHTWHITE='\033[1;37m'
CYAN='\033[1;36m'   # Bold Cyan
MAGENTA='\033[1;35m' # Bold Magenta

#Variables

memoryUsed=$(free -m | awk '/^Mem:/ {printf "%.1f GB of %.1f GB\n", $3/1024, $2/1024}')
IPADDR=$(hostname -I | awk '{print $1}')
up=$(uptime -p)
DNS=$(awk '/^nameserver/ {printf "%s, ", $2} END {print ""}' /etc/resolv.conf | sed 's/, $//')
diskUtil=$(df -H / | awk 'NR==2 {printf "Size: %s Used: %s Avail: %s Use%%: %s\n", $2, $3, $4, $5}')
OS=$(. /etc/os-release && echo $PRETTY_NAME)
KERNEL=$(uname -r)

#install figlet
if ! command -v figlet >/dev/null; then
  if command -v apt >/dev/null; then
    sudo apt update -y && sudo apt install figlet -y
  elif command -v dnf >/dev/null; then
    sudo dnf install epel-release figlet -y
  fi
fi

#banner build

echo -e "${GREEN}********** Welcome to $HOSTNAME **********${RESET}"
hostname -s | figlet -k -l -t

echo -e "${RED}=========================================================================${RESET}"
echo -e "  ${CYAN}- OS Version.......:${RESET} ${OS}"
echo -e "  ${CYAN}- Kernel Version...:${RESET} ${KERNEL}"
echo -e "  ${CYAN}- Uptime...........:${RESET} ${up}"
echo -e "  ${CYAN}- IP address.......:${RESET} ${IPADDR}"
echo -e "  ${CYAN}- DNS servers......:${RESET} ${DNS}"
echo -e "  ${CYAN}- Memory Used......:${RESET} ${memoryUsed}"
echo -e "  ${CYAN}- Disk Util........:${RESET} ${diskUtil}"
echo -e "${RED}=========================================================================${RESET}"
