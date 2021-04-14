
#!/bin/bash

function clear(){
    pkill -f 'iplscore.sh'
    echo "" > /tmp/display.txt
    pkill -RTMIN+10 i3blocks
}

raw=$(curl -s -4 "https://www.cricbuzz.com/")
echo $raw | pup "li.videos-carousal-item" > ~/scripts/iplscore/test.html
echo $raw | pup "li.videos-carousal-item" | \
 pup "a attr{href}"  |\
  awk -F "/" '{print $4 " " $3}' > /tmp/livematches.txt 
echo "STOP WATCHING" >> /tmp/livematches.txt
match=$(cat /tmp/livematches.txt | rofi -dmenu -i -p "Select Match")
$(rm /tmp/livematches.txt)
echo $match
if [[ $match == "STOP WATCHING" ]]
then
clear
exit 0
else
matchId=$(echo $match | awk '{print $NF}')
echo $matchId
clear
$(iplscore.sh $matchId)

fi
pkill -f 'ipl';
