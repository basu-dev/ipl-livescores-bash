#!/bin/bash

#Created By Basu Dev Adhikari
#github https://github.com/basu-dev
matchId=35622
echo $2
function fetch(){
raw=$(curl -4 -s 'https://www.cricbuzz.com/api/cricket-match/commentary/'$matchId'' \
  --compressed | jq .miniscore)
# raw=`cat sample2.json | jq .miniscore`
# echo $raw | jq 
}
# echo $raw 
function construct(){

#rawScore for showing Score Wickets and Overs only
rawScore=$(echo $raw | jq .matchScoreDetails)
inning=$(echo $raw | jq .inningsId)
#Summery was always on the first element of inningScoreList array
summery=$(echo $rawScore | jq .inningsScoreList[0])
#if/else for showing Target and Current Batting Team
if [ $inning == 1 ]
then
target=$(echo "")
#For inning 1 curreent batting and bowling teams were in position
# 0 of matchTeamInfo and on position 2 on second inning
matchTeams=$(echo $rawScore | jq .matchTeamInfo[0])
else
#target goes to third section of Scoreboard
target=$(echo $rawScore | jq -r '"Target \(.inningsScoreList[1].score+1)"')
matchTeams=$(echo $rawScore | jq .matchTeamInfo[1])
fi

batTeam=$(echo $matchTeams | jq -r .battingTeamShortName)
bowlTeam=$(echo $matchTeams | jq -r .bowlingTeamShortName)
runs=$(echo $summery | jq .score)
wickets=$(echo $summery | jq .wickets)
overs=$(echo $summery | jq .overs)
plrs=$(echo $raw | jq [.batsmanStriker,.batsmanNonStriker,.bowlerStriker])
#Score Card is the the First Section of Scoreboard
scoreCard=$(echo "$batTeam $runs/$wickets ($overs)")

#Second Section About Striker and Non Striker
#Scores with balls by Striking and Non Striking Batsman
batsManScores=$(echo $plrs | jq -r '"\(.[0].batName  ) \(.[0].batRuns)(\(.[0].batBalls)) \(.[1].batName ) \(.[1].batRuns)(\(.[1].batBalls))"' \
| awk '{print $2,$3,$5,$6}') 

#Bowling Stat of Strike Bowler aka current bowler
bowlerScore=$(echo $plrs | jq -r '" \(.[2].bowlName) \(.[2].bowlWkts)/\(.[2].bowlRuns) (\(.[2].bowlOvs)) " ' | awk '{print $2,$3,$4}')
#Show recent scores like ...1 3 4 W 1 ...W 
recentScores=$(echo $raw | jq -r '" Recent Scores \(.recentOvsStats) "')
#Sate shows whether match is complete or ongoing
state=$(echo $raw | jq -r .matchScoreDetails.state)


}
displaytype=0
function display(){

#Scoreboard has 3 sections 
#First with batting team and score i.e Scorecard
#Third With Bowling Team and Target
#Middle with Some additional Info

if [ $state == "Complete" ]
then
middleSection=$(echo $raw | jq -r .status)
break
elif [ $displaytype -eq 0 ]
then
middleSection=$(echo "$batsManScores .. $bowlerScore")
break
elif [ $displaytype -eq 1 ]
then
middleSection=$recentScores
else 

middleSection=$(echo $raw | jq -r .status)
fi

scoreBoard=$(echo "$scoreCard .. $middleSection .. $target $bowlTeam")

echo -e "\033[36m $scoreBoard \033[0m"
echo -e "\033[0m "
echo $scoreBoard >> /tmp/display.txt
pkill -RTMIN+10 i3blocks
}

continue=true
while $continue
do
fetch
construct
display
/bin/sleep 3
displaytype=1
display
/bin/sleep 3
displaytype=2
display
if [ $state == "Complete" ]
then
continue=false
break
fi
displaytype=0
display
/bin/sleep 10
done


