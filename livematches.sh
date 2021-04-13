#!/bin/bash

# raw=$(curl -4 "https://www.cricbuzz.com/")
# navlinks=$(echo $raw | sed -e 's/.*Featured Matches\(.*\)menu_branding.*/\1/')


# matches=$(echo $navlinks | awk -F "li" '{print $2}')
# echo $matches

val=$(cat test2.html | sed -e 's/.*title=\(.*\)href.*/\1/')
echo $val

