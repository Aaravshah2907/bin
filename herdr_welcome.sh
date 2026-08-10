#!/bin/bash
source ~/.local/bin/cosmere_colors.sh

clear

# 1. Large Clock (figlet) in Honor Gold - nicely spaced out
echo -e "${T_HONOR_GOLD}"
if command -v figlet &> /dev/null; then
    date +"%I : %M %p" | figlet
else
    echo "  $(date +"%I : %M %p")"
fi
echo -e "${T_RESET}"

echo -e "${T_SAPPHIRE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${T_RESET}"

# 2. Fastfetch (Modern System Info)
echo -e "${T_PRES_GLACIAL}System Status:${T_RESET}\n"
if command -v fastfetch &> /dev/null; then
    # Full fetch including the logo, tinted with Cosmere colors
    fastfetch --logo-color-1 blue \
              --logo-color-2 cyan \
              --color-keys cyan \
              --color-title blue
else
    echo "Fastfetch is missing."
fi

echo -e "${T_SAPPHIRE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${T_RESET}"

# 3. Weather & Calendar
echo -e "${T_EMERALD}Morning Briefing:${T_RESET}\n"
curl -s "wttr.in/?0q" | head -n 7

echo -e "\n${T_VIOLET}Calendar:${T_RESET}"
cal -h | sed 's/^/  /'

echo -e "\n${T_DIM}Press any key to enter the storm...${T_RESET}"
read -n 1 -s
clear
exec zsh
