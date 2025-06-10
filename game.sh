#!/bin/bash

# -----------------------------------------
#            Variables
# -----------------------------------------

# Score is defined as the comined value of each empty(non-mine) cell the player opens
score=0


# The game board. It is represented as an array of size = rows x columns = 10 x 10 = 100
declare -a board

# Game Board columns with a predifined state
a="1 10 -10 -1"
b="-1 0 1"
c="0 1"
d="-1 0 1 -2 -3"
e="1 2 20 21 10 0 -10 -20 -23 -2 -1"
f="1 2 3 35 30 20 22 10 0 -10 -20 -25 -30 -35 -3 -2 -1"
g="1 4 6 9 10 15 20 25 30 -30 -24 -11 -10 -9 -8 -7"

# Utility variables for pretty printing
RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m" # No Color

# -----------------------------------------
#            Utility Functions
# -----------------------------------------
usage() {
cat <<_EOF_
  This game is made for fun, it has simple rules.

  * You can re-select an element if only it's -
    empty.
  * If even, double digits are given, only the
    first will be considered..

  Shown down here is a metrics 10x10 in size and
  to play you have to enter the coordinates.

  NOTE: To choose col- g, row- 5, give input - g5


_EOF_
}

graceful_exit() {
  printf '\n\n%s\n\n' "Exiting game...Thanks for playing!"
  exit 1
}


# -----------------------------------------
#            Main Functions
# -----------------------------------------

# Prints the mine field
playground() {

    # Clears the previous board:
    # "\e" escape character "[2J" clears screen "[H" moves cursor to its default position
    printf "\e[2J\e[H"

    # Print the first row
    printf '%s' "     a   b   c   d   e   f   g   h   i   j"
    printf '\n   %s\n' "-----------------------------------------"

    # Initialize a counter to loop over all cells in the game board
    r=0

    # Loop over game board which is an array of size 100
    for row in $(seq 0 9); do
        # Print the row number
        printf '%d  ' "$row"

        for col in $(seq 0 9); do
            # Increment counter
            # The "((...))" construct is for arithmetic operations in Bash
            # r=$((r + 1)) = ((r++)) = ((r+=1))
            ((r+=1))

            # This function will only be execute on the first call of "playground"
            initialize_empty_cell $r

            # Print the seperator "|" between adjacent cells
            printf '%s \e[33m%s\e[0m ' "|" "${board[$r]}"
        done

        # Print sperator between each row
        printf '%s\n' "|"
        printf '   %s\n' "-----------------------------------------"
    done

    printf '\n\n'
}


# This function will initialize the cells inside the game board with a dot "."\
# A cell with value = "." means that the player has yet to choose this cell
# This function is mainly used the first time the "playground" function is called
initialize_empty_cell() {
    # Store the input as a local scoped variable
    local e=$1
    
    # "-z": Check if the cell is empty 
    if [[ -z "${board[$e]}" ]];then

        # If it is empty then initialize it as a dot "."
        board[$r]="."
    fi
}


get_free_fields() {
    free_fields=0

    for n in $(seq 1 ${#board[@]}); do

        if [[ "${board[$n]}" = "." ]]; then
            ((free_fields+=1))
        fi
    done
}


is_free_field() {
    # Board Index that the player selected
    local b_index=$1

    # Randomly generated cell value (from 0 to 5)
    local cell_value=$2

    # Flag for detecting invalid player choice
    invalid_action=0 
    
    if [[ "${board[$b_index]}" = "." ]]; then

        board[$b_index]=$cell_value
        score=$((score+cell_value))
    else
        # If the index is out of bounds OR if the player selected a non-empty cell
        invalid_action=1
    fi
}



get_mines() {
    m=$(shuf -e a b c d e f g X -n 1)

    if [[ "$m" != "X" ]]; then
        for limit in ${!m}; do
            field=$(shuf -i 0-5 -n 1)
            index=$((i+limit))
            is_free_field $index $field
        done
    elif [[ "$m" = "X" ]]; then
        g=0
        board[$i]=X

        for j in {42..49}; do
            out="gameover"
            k=${out:$g:1}
            board[$j]=${k^^}
            ((g+=1)) 
        done
    fi
}


# Parses user input
get_coordinates() {

    # Example input: b4  >> col=b  ro=4
    colm=${opt:0:1}
    ro=${opt:1:1}

    # Translate the column letters into equivelant numbers
    case $colm in
        a ) o=1;;
        b ) o=2;;
        c ) o=3;;
        d ) o=4;;
        e ) o=5;;
        f ) o=6;;
        g ) o=7;;
        h ) o=8;;
        i ) o=9;;
        j ) o=10;;
    esac

    # Get the index of the cell = (row*10) + column
    cell=$(((ro*10)+o))

    # Checks if the selected cell has not been opened before
    # And if empty, assign a random score(from 1 to 5) to that cell
    is_free_field $cell "$(shuf -i 0-5 -n 1)"

    if [[ $invalid_action -eq 1 ]] || [[ ! "$colm" =~ [a-j] ]]; then
        printf "$RED \n%s: %s\n$NC" "warning" "not allowed!!!!"
    else
        get_mines
        playground
        get_free_fields

        if [[ "$m" = "X" ]]; then
            printf "\n\n\t $RED%s: $NC %s %d\n" "GAME OVER" "you scored" "$score"
            printf '\n\n\t%s\n\n' "You were just $free_fields mines away."
            exit 0
        elif [[ $free_fields -eq 0 ]]; then
            printf "\n\n\t $GREEN%s: %s $NC %d\n\n' "You Win" "you scored" "$score
            exit 0
        fi
    fi
}


main() {
 
    # Catch the interrupt signal "Ctrl+C"
    trap graceful_exit INT

    # Clear console and print start message
    printf "\e[2J\e[H"
    usage

    # Game start prompt
    read -r -p "Type Enter to continue. And good luck!"

    # The first run of "playground" initializes the cells as empty
    # Which is represented as a dot "."
    # Empty cell means: the player did not choose this cell
    playground

    # Main Game Loop
    while true; do
        printf "Remember: to choose col- g, row- 5, give input - g5 \n\n"
        read -r -p "info: enter the coordinates: " opt
        get_coordinates
    done
}

main
