#!/bin/bash

trap 'gameover' INT TERM QUIT

slash=0
declare -A square
declare -A color
for i in {1..16}
do  color+=([color$i]=$i)
done
[[ $1 =~ ^[0-9]+$ ]] && [ $1 -le ${#color[*]} ] && [ $1 -ge 3 ] && MAX=$1 || MAX=${#color[*]}
txtcolor=(origin ${!color[*]})
txtcolor=(${txtcolor[*]:0:$[$MAX+1]})
pos=()
TERM=xterm-256color
CONFIGFILE='./cqconf'
tlx=1 #top left point
tly=1
clear
tput civis

border(){
    local i

    tput setab 7 #white
    for i in `seq $tly $[$tly+$MAX+1]`
    do  echo -ne "[$i;${tlx}H  "
        echo -ne "[$i;$[$MAX*2+2+$tlx]H  "
    done
    for i in `seq $[$tlx+2] $[$MAX*2+1+$tlx]`
    do  echo -en "[$tly;${i}H "
        echo -en "[$[$MAX+1+$tly];${i}H "
    done
}

initsquare(){
    local i j x y z
    for i in `seq $MAX`
    do  for j in `seq $MAX`
        do  square[$i,$j]='origin'
        done
    done

    [ ! -f "$CONFIGFILE" ] || [ ! -r "$CONFIGFILE" ] && {
        CONFIGFILE=`mktemp /tmp/cqXXXXXXXXXXXX`
        for i in `seq $[$RANDOM%10]`
        do  echo "$[$RANDOM%$MAX+1] $[$RANDOM%$MAX+1] ${txtcolor[$RANDOM%$MAX+1]}"
        done > $CONFIGFILE
    }

    while read x y z
    do  check $x $y $z && {
            square[$x,$y]=$z
            pos+=($x,$y)
            tput setab ${color[$z]}
            echo -e "[$[$y+$tly];$[$x*2+$tlx]H  "
        }
    done < $CONFIGFILE
}

check(){
    local i

    for i in `seq $[$1-1]` `seq $[$1+1] $MAX`
    do  [ "${square[$i,$2]}" = "$3" ] && return 1
    done

    for i in `seq $[$2-1]` `seq $[$2+1] $MAX`
    do  [ "${square[$1,$i]}" = "$3" ] && return 1
    done

    [ $slash -eq 1 ] && {
            local x y

	    x=$[$1-1]
	    y=$[$2-1]
	    while [ $x -ne 0 ] && [ $y -ne 0 ]
	    do  [ "${square[$x,$y]}" = "$3" ] && return 1
		((x--))
		((y--))
	    done

	    x=$[$1+1]
	    y=$[$2-1]
	    while [ $x -ne $[$MAX+1] ] && [ $y -ne 0 ]
	    do  [ "${square[$x,$y]}" = "$3" ] && return 1
		((x++))
		((y--))
	    done

	    x=$[$1-1]
	    y=$[$2+1]
	    while [ $x -ne 0 ] && [ $y -ne $[$MAX+1] ]
	    do  [ "${square[$x,$y]}" = "$3" ] && return 1
		((x--))
		((y++))
	    done

	    x=$[$1+1]
	    y=$[$2+1]
	    while [ $x -ne $[$MAX+1] ] && [ $y -ne $[$MAX+1] ]
	    do  [ "${square[$x,$y]}" = "$3" ] && return 1
		((x++))
		((y++))
	    done
    }

    return 0
}

startgame(){
    local i j k l

    for((i=1;i<=MAX+1;i++))
    do  for((j=1;j<=MAX;j++))
        do  [ $i -eq $[$MAX+1] ] && {
                copyone
                j=$[$MAX-2]
                i=$[$MAX-1]
                continue
            }

        for k in ${pos[*]}
            do  [ "$j,$i" = "$k" ] && continue 2
            done
            for k in `seq 0 $MAX`
            do  [ ${square[$j,$i]} = ${txtcolor[$k]} ] && break
            done
            for l in `seq $[$k+1] $MAX`
            do  check $j $i ${txtcolor[$l]} && {
                    square[$j,$i]=${txtcolor[$l]}
                    tput setab ${color[${txtcolor[$l]}]}
                    echo -e "[$[$i+$tly];$[$j*2+$tlx]H  "
                    continue 2
                }
            done
            square[$j,$i]='origin'
            tput setab 0
            echo -e "[$[$i+$tly];$[$j*2+$tlx]H  "

            ((j--))
            while [ $i -ne 0 ]
            do  while [ $j -ne 0 ]
                do  ((j--))
                    for k in ${pos[*]}
                    do  [ "$[$j+1],$i" = "$k" ] && continue 2
                    done
                    continue 3
                done
                ((i--))
                j=$MAX
            done
            return
        done
    done
}

copyone(){
    local lines=`tput lines`
    local cols=`tput cols`
    local i j

    if [ $[$tlx+$MAX*4+8] -le $cols ]
    then    ((tlx+=2*MAX+5))
    else    ((tly+=MAX+3))
            tlx=1
            if [ $[$tly+$MAX+1] -gt $lines ]
    	then	    tput setab 0
            echo -e "[$lines;1H"
                    for i in `seq $[$tly+$MAX-$lines]`
                    do  echo
                    done
                    tly=$[$lines-$MAX-1]
            fi
    fi


    border
    for i in `seq $[$MAX-1]`
    do  for j in `seq $MAX`
        do  [ $i -eq $[$MAX-1] ] && [ $j -eq $[$MAX-2] ] && break
            tput setab ${color[${square[$j,$i]}]}
            echo -e "[$[$i+$tly];$[$j*2+$tlx]H  "
        done
    done

    for i in ${pos[*]}
    do  tput setab ${color[${square[$i]}]}
        j=${i%,*}
        i=${i#*,}
        echo -e "[$[$i+$tly];$[$j*2+$tlx]H  "
    done
}

gameover(){
    tput setab 0
    tput cnorm
    echo -e "[$[$MAX+2+$tly];1HGAMEOVER!"
    exit 
}

waitsec(){
    tput setab 0
    for i in {5..1}
    do  echo -e "[$[$MAX+2+$tly];1H   $i..."
        sleep 1
    done
    echo -e "[$[$MAX+2+$tly];1H        "
}

border
initsquare
waitsec
startgame
gameover
