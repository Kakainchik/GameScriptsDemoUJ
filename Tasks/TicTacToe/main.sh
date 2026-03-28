#!/bin/bash
INPUT=
AGAINST_PC=1
TURN=0
CURRENT_PLAYER="X"
CELLS=(1 2 3 4 5 6 7 8 9)

SAVE_FILE=$1

if [[ -f $SAVE_FILE ]]
then
    echo "------------"
    echo "File $SAVE_FILE loaded"
    echo "------------"

    line_number=0
    while read -r line
    do
        if [[ line_number -eq 0 ]]
        then
            CURRENT_PLAYER=$line
        fi

        CELLS[((line_number - 1))]=$line
        ((line_number++))

        if [[ index -gt 10 ]]
        then
            break
        fi
    done < $SAVE_FILE
fi

echo "Input from 1 to 9 to pick the cell"
echo "Input 'exit' to end the game"
echo "Input 'save' to save the game"
echo "Are you going to play against PC? [Press y/n]"

while true
do
    read -rsn 1 INPUT
    if [ ${INPUT,,} = "y" ]
    then
        echo "------------"
        echo "- Play against PC -"
        AGAINST_PC=0
        break
    elif [ ${INPUT,,} = "n" ]
    then
        echo "------------"
        echo "- Play against another player -"
        AGAINST_PC=1
        break
    fi
done

print_board() {
    echo "------------"
    echo " ${CELLS[0]} | ${CELLS[1]} | ${CELLS[2]} "
    echo " ${CELLS[3]} | ${CELLS[4]} | ${CELLS[5]} "
    echo " ${CELLS[6]} | ${CELLS[7]} | ${CELLS[8]} "
    echo "------------"
}

check_win() {
    local player=$1
    if [[ ${CELLS[0]} = ${player} && ${CELLS[1]} = ${player} && ${CELLS[2]} = ${player} ]] ||
    [[ ${CELLS[3]} = ${player} && ${CELLS[4]} = ${player} && ${CELLS[5]} = ${player} ]] ||
    [[ ${CELLS[6]} = ${player} && ${CELLS[7]} = ${player} && ${CELLS[8]} = ${player} ]] ||
    [[ ${CELLS[0]} = ${player} && ${CELLS[3]} = ${player} && ${CELLS[6]} = ${player} ]] ||
    [[ ${CELLS[1]} = ${player} && ${CELLS[4]} = ${player} && ${CELLS[7]} = ${player} ]] ||
    [[ ${CELLS[2]} = ${player} && ${CELLS[5]} = ${player} && ${CELLS[8]} = ${player} ]] ||
    [[ ${CELLS[0]} = ${player} && ${CELLS[4]} = ${player} && ${CELLS[8]} = ${player} ]] ||
    [[ ${CELLS[6]} = ${player} && ${CELLS[4]} = ${player} && ${CELLS[2]} = ${player} ]]
    then
        return 0
    else
        return 1
    fi
}

check_cell() {
    local index=$1
    if [[ ${CELLS[(($index))]} = "X" || ${CELLS[(($index))]} = "O" ]]
    then
        return 0
    else
        return 1
    fi
}

save_file() {
    file_num=$(ls | egrep "\.sav" | sed -E "s/[^0-9]//g" | sort -n | tail -1)

    [ ${file_num:-0} ] || return

    ((file_num++))
    file_name="saveFile_${file_num}.sav"

    echo "$CURRENT_PLAYER" > "$file_name"

    for i in ${!CELLS[@]}
    do
        echo ${CELLS[$i]} >> "$file_name"
    done
}

until [ "$INPUT" = "exit" ]
do
    echo -e "Turn for:\t $CURRENT_PLAYER"
    print_board

    if [[ ${AGAINST_PC} -eq 0 && ${CURRENT_PLAYER} = "O" ]]
    then
        INPUT=$(shuf -i 1-9 -n 1)
    else
        read INPUT

        if [ ${INPUT} = "exit" ]
        then
            break
        fi

        if [ ${INPUT} = "save" ]
        then
            save_file
            break
        fi
    
        if [[ ! $INPUT =~ ^[1-9]$ ]]
        then
            echo -e "Invalid input, retry"
            continue
        fi
    fi

    if check_cell $(($INPUT - 1))
    then
        if [[ ${AGAINST_PC} -eq 1 ]]
        then
            echo -e "This cell is already taken"
        fi
        continue
    fi

    CELLS[(($INPUT - 1))]=$CURRENT_PLAYER
    
    if check_win $CURRENT_PLAYER
    then
        print_board
        echo -e "Player $CURRENT_PLAYER won"
        break
    fi

    ((TURN++))

    if [[ $TURN -eq 9 ]]
    then
        print_board
        echo -e "Nobody won"
        break
    fi

    if [[ ${CURRENT_PLAYER} = "X" ]]
    then
        CURRENT_PLAYER="O"
    else
        CURRENT_PLAYER="X"
    fi
done

exit 0