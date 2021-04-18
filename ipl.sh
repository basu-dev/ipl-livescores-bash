
#!/bin/bash

function clear(){
    pkill -f 'iplscore.sh'
    echo "" > /tmp/display.txt
    #this command just signals my i3block display section to rerender
    pkill -RTMIN+10 i3blocks
}
raw=$(curl -s -4 "https://www.cricbuzz.com/" | pup "li.videos-carousal-item")
#scraping all match ids from "a" tag
matchIds+=($(echo $raw | pup "a attr{href} "  | awk -F "/" '{print $3}'))
#scraping match title from "a" tag title
matchTitles+=$(echo "$raw" | pup "a attr{title}")
#writin the titles along with STOP WATCHING to tmp file
echo "$matchTitles" > /tmp/matches.txt
echo "STOP WATCHING" >> /tmp/matches.txt
#Catching Selected Title From Rofi
title=$(cat /tmp/matches.txt | rofi -dmenu -i -p "Select Match")
echo $title
[ ${#title} == 0 ] && exit 0

[[ $title == "STOP WATCHING" ]] && clear && exit 0
#Getting Index of title selected 
index=$(echo "$matchTitles" | grep -n "$title" | awk -F ":" '{print $1}')
#Getting matchId from Index
matchId=$(echo "${matchIds[$index - 1]}")

pkill iplscore.sh
	
iplscore.sh $matchId

