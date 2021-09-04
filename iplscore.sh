#!/bin/bash

# Created By Basu Dev Adhikari
# github https://github.com/basu-dev

matchId=$1
writeBlock(){
	echo $1 > /tmp/display.txt
	pkill -RTMIN+10 i3blocks
}
clearBlock(){
	echo "" > /tmp/display.txt
	pkill -RTMIN+10 i3blocks
}
matchNotStarted(){
	writeBlock "Match Not Started Yet"
	/bin/sleep 3
	clearBlock
	exit 1

}
validateMatchId(){
	status=$(curl -4 -I -s 'https://www.cricbuzz.com/api/cricket-match/commentary/'$matchId''\
	       	| awk '/HTTP/ {print $2}')
	if [ $status != 200 ]
	then
		echo "Invalid MatchId"
		writeBlock "Invalid MatchId"
		/bin/sleep 3
       		clearBlock	
		exit 1
	fi
}
validateMatchId
displaytype=0

fetch(){
	response=$(curl -4 -s 'https://www.cricbuzz.com/api/cricket-match/commentary/'$matchId'' --compressed)
	[ "${#response}" == 0 ] && exit 1
	rawScore=$(echo $response | jq .miniscore)
	[ "${#rawScore}" == 0 ] && matchNotStarted || echo $rawScore > /tmp/iplscore.json
}

construct(){
	#rawScore for showing Score Wickets and Overs only
	raw=$(cat /tmp/iplscore.json | jq)
	rawScore=$(echo $raw | jq .matchScoreDetails)
	inning=$(echo $raw | jq .inningsId)

	#Summery was always on the first element of inningScoreList array
	summery=$(echo $rawScore | jq .inningsScoreList[0])
	#if/else for showing Target and Current Batting Team

	if [ $inning == 0 ]
	then
		matchNotStarted
	elif [ $inning == 1 ]
	then
		target=$(echo "")
		#For inning 1 curreent batting and bowling teams were in position
		# 0 of matchTeamInfo and on position 2 on second inning
		matchTeams=$(echo $rawScore | jq .matchTeamInfo[0])
	elif [ $inning == 2 ]
	then
		target=$(echo "")
		matchTeams=$(echo $rawScore | jq .matchTeamInfo[1])
	elif [ $inning == 3 ]
	then
		target=$(echo "")
		matchTeams=$(echo $rawScore | jq .matchTeamInfo[2])
	else
		#target goes to third section of Scoreboard
		target=$(echo $rawScore | jq -r '"Target \(.inningsScoreList[4].score+1)"')
		echo "$inning"
		matchTeams=$(echo $rawScore | jq .matchTeamInfo["$inning"])
	fi
	batTeam=$(echo $matchTeams | jq -r .battingTeamShortName)
	bowlTeam=$(echo $matchTeams | jq -r .bowlingTeamShortName)
	

	plrs=$(echo $raw | jq "[.batsmanStriker,.batsmanNonStriker,.bowlerStriker]")

	#Score Card is the the First Section of Scoreboard
	scoreCard=$(echo $summery | jq -r '"'$batTeam' \(.score)/\(.wickets) (\(.overs))"')

	#Second Section About Striker and Non Striker
	batsManScores=$(echo $plrs | jq -r '"\(.[0].batName) \(.[0].batRuns)(\(.[0].batBalls)) \(.[1].batName)\(.[1].batRuns)(\(.[1].batBalls))"' \
) 
	#Bowling Stat of Strike Bowler aka current bowler
	bowlerScore=$(echo $plrs | jq -r '" \(.[2].bowlName) \(.[2].bowlWkts)/\(.[2].bowlRuns) (\(.[2].bowlOvs)) " '\
	       		| awk '{print $2,$3,$4}')
	#Show recent scores like ...1 3 4 W 1 ...W 
	recentScores=$(echo $raw | jq -r '" Recent \(.recentOvsStats) "')

	#Sate shows whether match is complete or ongoing
	state=$(echo $raw | jq -r .matchScoreDetails.state)
	crr=$(echo $raw | jq -r .currentRunRate)
	echo "$inning"
	[ "$inning" == 2 ] && reqRunRate=$(echo $raw | jq -r '".. RRR \(.requiredRunRate)"') || requiredRunRate=""
	matchStatus=$(echo $raw | jq -r .status)

}

display(){
	
	#Scoreboard has 3 sections 
	#First with batting team and score i.e Scorecard
	#Third With Bowling Team and Target
	#Middle with Some additional Info
	displaytype=$(tail -n 1 /tmp/displaytype.txt)
	if [ $displaytype -eq 0 ]
	then
		middleSection=$(echo "$batsManScores .. $bowlerScore")
	elif [ $displaytype -eq 1 ]
	then
		middleSection=$(echo "$recentScores ... CRR $crr ")
	else
		middleSection=$(echo "$matchStatus $reqRunRate") 
	fi

	scoreBoard=$(echo "$scoreCard .. $middleSection .. $target $bowlTeam")

	echo -e "\033[36m $scoreBoard \033[0m"
	echo -e "\033[0m "
	writeBlock "${scoreBoard}"
}
notInProgressMatch(){
	setdisplaytype 2 && display
	/bin/sleep 4
	setdisplaytype 0 && display
	/bin/sleep 4
	clearBlock
	exit 1
}
setdisplaytype(){
	echo $1 > /tmp/displaytype.txt
}
fetch
construct
while true
do 
	/bin/sleep 7
	fetch
	construct
	[[ $state !=  "In Progress" ]] && notInProgressMatch
	display 
done &
 while true
do
	[[ $state !=  "In Progress" ]] && notInProgressMatch
	construct
	display 
 	/bin/sleep 7 && construct
	setdisplaytype 1
       	display
 	/bin/sleep 7 && construct
	[[ $inning -gt 1 ]] && setdisplaytype 2 || setdisplaytype 0
 	display
 	/bin/sleep 7  && setdisplaytype 0
done


