#!/bin/bash

# Created By Basu Dev Adhikari
# github https://github.com/basu-dev

matchId=$1
function writeBlock(){
	echo $1 > /tmp/display.txt
	pkill -RTMIN+10 i3blocks
}
function clearBlock(){
	echo "" > /tmp/display.txt
	pkill -RTMIN+10 i3blocks
}
function matchNotStarted(){
	writeBlock "Match Not Started Yet"
	/bin/sleep 3
	clearBlock
	exit 1

}
function validateMatchId(){
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

function fetch(){
	response=$(curl -4 -s 'https://www.cricbuzz.com/api/cricket-match/commentary/'$matchId'' --compressed)
	echo "fetched"
	[ "${#response}" == 0 ] && exit 1
	raw=$(echo $response | jq .miniscore)
	[ "${#raw}" == 0 ] && matchNotStarted
}

function construct(){
	#rawScore for showing Score Wickets and Overs only
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
	else
		#target goes to third section of Scoreboard
		target=$(echo $rawScore | jq -r '"Target \(.inningsScoreList[1].score+1)"')
		matchTeams=$(echo $rawScore | jq .matchTeamInfo[1])
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

}

function display(){
	echo "Displaying $displaytype"
	#Scoreboard has 3 sections 
	#First with batting team and score i.e Scorecard
	#Third With Bowling Team and Target
	#Middle with Some additional Info

	if [ $displaytype -eq 0 ]
	then
		middleSection=$(echo "$batsManScores .. $bowlerScore")
	elif [ $displaytype -eq 1 ]
	then
		middleSection=$(echo "$recentScores ... CRR $crr ")
	else
		[ $inning == 2 ] && reqRunRate=$(echo $raw | jq -r '".. RRR \(.requiredRunRate)"') || ""
		echo $inning
		matchStatus=$(echo $raw | jq -r .status)
		middleSection=$(echo "$matchStatus $reqRunRate") 
	fi

	scoreBoard=$(echo "$scoreCard .. $middleSection .. $target $bowlTeam")

	#echo -e "\033[36m $scoreBoard \033[0m"
	echo -e "\033[0m "
	writeBlock "${scoreBoard}"
}
function notInProgressMatch(){
	displaytype=2 && display
	/bin/sleep 4
	displaytype=0 && display
	/bin/sleep 4
	clearBlock
	exit 1
}
 while true
do
	fetch
	construct
	[[ $state !=  "In Progress" ]] && notInProgressMatch
	display 
 	/bin/sleep 5
	displaytype=1
       	display
 	/bin/sleep 4
	[[ $inning -gt 1 ]] && displaytype=2 || displaytype=0
 	display
 	/bin/sleep 4  && displaytype=0
done


