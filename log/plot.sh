#!/bin/bash

function plot {
echo "set title '$2 - $1'"                     >  "$1.gnu"
echo "set key box"                        >>  "$1.gnu"
echo "set key bottom right"                    >>  "$1.gnu"
echo "set size 1,1"                        >>  "$1.gnu"
echo "set xlabel 'time'"                    >>  "$1.gnu"
echo "set ylabel '$1'"            >>  "$1.gnu"
echo "set autoscale"                        >>  "$1.gnu"
echo "set term png"                    >>  "$1.gnu"
echo "set output '$2_$1.png'"    >>  "$1.gnu"
echo -n "plot " >> "$1.gnu"

mysql --column-names=0 -u root dastal << EOF | while read NAME
select distinct $3 from $2
EOF
do
	mysql --column-names=0 -u root dastal << EOF > $1_$NAME.dat
select time - (SELECT MIN(time) FROM t) as time, $1 from $2 where $3 = '$NAME'
EOF
echo -n "\"$1_$NAME.dat\" using 1:2 title \"$NAME\", " >>  "$1.gnu"
done

echo "0" >> "$1.gnu"
echo >> "$1.gnu"
 
gnuplot < "$1.gnu"
}

rm -f *png

plot "xp" "player_ot" "name"
plot "xp_sum" "player_ot" "name"
plot "level" "player_ot" "name"
plot "death" "player_ot" "name"
plot "kills_player" "player_ot" "name"
plot "xp_combat" "player_ot" "name"
plot "xp_creeps" "player_ot" "name"
plot "xp_resources" "player_ot" "name"
plot "barrier_dmg" "player_ot" "name"
plot "resources_dmg" "player_ot" "name"
plot "currentPain" "barrier_ot" "event"
#~ plot "controller" "resource_ot" '`desc`'

rm -f *gnu *dat

