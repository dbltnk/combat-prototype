#!/bin/bash

function plot {
echo "set title '$1'"                     >  "$1.gnu"
echo "set key box"                        >>  "$1.gnu"
echo "set key bottom right"                    >>  "$1.gnu"
echo "set size 1,1"                        >>  "$1.gnu"
echo "set xlabel 'time'"                    >>  "$1.gnu"
echo "set ylabel '$1'"            >>  "$1.gnu"
echo "set autoscale"                        >>  "$1.gnu"
echo "set term png"                    >>  "$1.gnu"
echo "set output '$1.png'"    >>  "$1.gnu"
echo -n "plot " >> "$1.gnu"

mysql --column-names=0 -u root dastal << EOF | while read NAME
select distinct name from player_ot
EOF
do
	mysql --column-names=0 -u root dastal << EOF > $1_$NAME.dat
select time - (SELECT MIN(time) FROM t) as time, $1 from player_ot where name = '$NAME'
EOF
echo -n "\"$1_$NAME.dat\" using 1:2 title \"$NAME\", " >>  "$1.gnu"
done

echo "0" >> "$1.gnu"
echo >> "$1.gnu"
 
gnuplot < "$1.gnu"
}

plot "xp"
plot "level"
plot "death"
plot "kills_player"
plot "xp_combat"
plot "xp_creeps"
plot "xp_resources"
plot "barrier_dmg"
plot "resources_dmg"
