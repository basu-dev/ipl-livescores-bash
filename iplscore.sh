#!/bin/bash


#Created By Basu Dev Adhikari
#github https://github.com/basu-dev
matchId=35622
raw=$(curl -4 -s 'https://www.cricbuzz.com/api/cricket-match/commentary/'$matchId'' \
  --compressed | jq .miniscore)

#rawScore for showing Score Wickets and Overs only
rawScore=$(echo $raw | jq .matchScoreDetails)

matchTeams=$(echo $rawScore | jq .matchTeamInfo[])
batTeam=$(echo $matchTeams | jq -r .battingTeamShortName)
bowlTeam=$(echo $matchTeams | jq .bowlingTeamShortName)
summery=$(echo $rawScore | jq .inningsScoreList[])
runs=$(echo $summery | jq .score)
wickets=$(echo $summery | jq .wickets)
overs=$(echo $summery | jq .overs)

#Second Section About Striker and Non Striker
#plrs means Active Players
plrs=$(echo $raw | jq [.batsmanStriker,.batsmanNonStriker,.bowlerStriker])

nonStrikerDetails=$(echo $raw | jq .batsmanNonStriker)
bowlerStriker=$(echo $raw | jq .bowlerStriker)
#Names and Scores Per Ball of Striker and Non Striker
# strikerName=$(echo $strikerDetails | jq .batRuns,.batBalls)
# echo $strikerName
# echo $plrs | jq
batsManScores=$(echo $plrs | jq -r '"\(.[0].batName ) \(.[0].batRuns)(\(.[0].batBalls)) \(.[1].batName ) \(.[1].batRuns)(\(.[1].batBalls))"')
bowlerScore=$(echo $plrs | jq -r '" \(.[2].bowlName) \(.[2].bowlWkts)/\(.[2].bowlRuns) (\(.[2].bowlOvs)) " ')

echo $batsMans

# echo $nonStrikerDetails | jq
# echo $bowlerStriker | jq
echo " $batTeam $runs/$wickets ($overs) $batsMans" >> /tmp/display.txt
pkill -RTMIN+10 i3blocks


#

# echo $batTeam | jq
# echo $bowlTeam | jq
# echo $summery | jq
# echo $rawScore  | jq
# echo $raw | jq