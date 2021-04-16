
#!/bin/bash

function clear(){
    pkill -f 'iplscore.sh'
    echo "" > /tmp/display.txt
    pkill -RTMIN+10 i3blocks
}

raw=$(curl -s -4 "https://www.cricbuzz.com/" | pup "li.videos-carousal-item")
matchIds=()
#echo $raw | pup "li.videos-carousal-item" > ~/scripts/iplscore/test.html

matchIds+=($(echo $raw | pup "a attr{href} "  | awk -F "/" '{print $3}'))

matchTitles=$(echo "$raw" | pup "a attr{title}")

title=$(echo "$matchTitles" | rofi -dmenu -i -p "Select Match")

index=$(echo "$matchTitles" | grep -n "$title" | awk -F ":" '{print $1}')

matchId=$(echo "${matchIds[$index]}")


# echo "STOP WATCHING" >> /tmp/livematches.txt


# match=$(cat /tmp/livematches.txt | rofi -dmenu -i -p "Select Match")

# #$(rm /tmp/livematches.txt)
# echo $match
# if [[ $match == "STOP WATCHING" ]]
# then
# clear
# exit 0
# else
# matchIds=$(echo $match | awk '{print $NF}')
# echo $matchIds
# clear
# $(iplscore.sh $matchIds)

# fi
$(iplscore.sh $matchId)
