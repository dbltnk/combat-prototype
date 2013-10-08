#!/bin/bash

SESSION=$1
GAMEID=$2

echo process tracking of session $SESSION gameid $GAMEID

D="stats/$1_$2"

mkdir -p $D

php process_tracking_of_gameid.php $SESSION $GAMEID > $D/index.html

rsync -a --delete /home/sebialex/combat-prototype-enet/checkout/server/stats/. /home/sebialex/BTSync/Das\ Tal/Logs/stats/.
