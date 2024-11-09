#!/usr/bin/env bash

# GLOBAL VARIABLES
BOARD=("0" "1" "2" "3" "4" "5" "6" "7" "8")
PLAYER="1"
MARK="o"
WIN="0"
TURN_COUNT=9
GAME_MODE=""
SAVE_FILE="tic_tac_toe_save.txt"

function display_board {
    clear
    echo
    echo "     ${BOARD[0]} | ${BOARD[1]} | ${BOARD[2]}"
    echo "    ---|---|---"
    echo "     ${BOARD[3]} | ${BOARD[4]} | ${BOARD[5]}"
    echo "    ---|---|---"
    echo "     ${BOARD[6]} | ${BOARD[7]} | ${BOARD[8]}"
    echo
}

function check_cells {
    if [[ "${BOARD[$1]}" == "${BOARD[$2]}" ]] && \
       [[ "${BOARD[$2]}" == "${BOARD[$3]}" ]] && \
       [[ "${BOARD[$1]}" == "${MARK}" ]]; then
        WIN="1"
    fi
}

function check_win {
    check_cells 0 1 2
    check_cells 3 4 5
    check_cells 6 7 8
    check_cells 0 3 6
    check_cells 1 4 7
    check_cells 2 5 8
    check_cells 0 4 8
    check_cells 2 4 6

    if [[ "${WIN}" -eq "1" ]]; then
        display_board
        echo "Player ${PLAYER} (${MARK}) won!"
        exit
    elif [[ "${TURN_COUNT}" -eq 0 ]]; then
        display_board
        echo "It's a TIE!"
        exit
    fi
}

function switch_player {
    if [[ "${PLAYER}" -eq "1" ]]; then
        PLAYER="2"
        MARK="x"
    else
        PLAYER="1"
        MARK="o"
    fi
}

function computer_move {
    local available_moves=()
    for i in "${!BOARD[@]}"; do
        if [[ "${BOARD[i]}" != "o" && "${BOARD[i]}" != "x" ]]; then
            available_moves+=("$i")
        fi
    done

    # Choose a random move from available moves
    local random_index=$((RANDOM % ${#available_moves[@]}))
    echo "${available_moves[random_index]}"
}

function game_loop_pvp {
    while [[ "${WIN}" -eq "0" ]]; do
        display_board
        echo "Player ${PLAYER} (${MARK}), choose a position (0-8) or enter 's' to save the game:"
        read -r POSITION
        if [[ "$POSITION" == "s" ]]; then
            save_game
            continue
        fi

        if [[ "${POSITION}" =~ ^[0-8]$ ]] && [[ "${BOARD[$POSITION]}" != "o" ]] && [[ "${BOARD[$POSITION]}" != "x" ]]; then
            BOARD[POSITION]="${MARK}"
            TURN_COUNT=$((TURN_COUNT - 1))
            check_win
            switch_player
        else
            echo "Invalid choice, try again."
        fi
    done
}

function game_loop_pvc {
    while [[ "${WIN}" -eq "0" ]]; do
        display_board
        if [[ "${PLAYER}" -eq "1" ]]; then
            echo "Player ${PLAYER} (${MARK}), choose a position (0-8) or enter 's' to save the game:"
            read -r POSITION
            if [[ "$POSITION" == "s" ]]; then
                save_game
                continue
            fi
        else
            echo "Computer is making a move..."
            POSITION=$(computer_move)
            sleep 1
        fi

        if [[ "${POSITION}" =~ ^[0-8]$ ]] && [[ "${BOARD[$POSITION]}" != "o" ]] && [[ "${BOARD[$POSITION]}" != "x" ]]; then
            BOARD[POSITION]="${MARK}"
            TURN_COUNT=$((TURN_COUNT - 1))
            check_win
            switch_player
        else
            echo "Invalid choice, try again."
        fi
    done
}

function save_game {
    echo "${GAME_MODE}" > "$SAVE_FILE"
    echo "${PLAYER}" >> "$SAVE_FILE"
    echo "${MARK}" >> "$SAVE_FILE"
    echo "${TURN_COUNT}" >> "$SAVE_FILE"
    echo "${BOARD[*]}" >> "$SAVE_FILE"
    echo "Game saved successfully."
}

function load_game {
    if [[ -f "$SAVE_FILE" ]]; then
        readarray -t save_data < "$SAVE_FILE"
        GAME_MODE="${save_data[0]}"
        PLAYER="${save_data[1]}"
        MARK="${save_data[2]}"
        TURN_COUNT="${save_data[3]}"
        BOARD=(${save_data[4]})
        echo "Game loaded successfully."
        
        if [[ "$GAME_MODE" == "pvp" ]]; then
            game_loop_pvp
        elif [[ "$GAME_MODE" == "pvc" ]]; then
            game_loop_pvc
        fi
    else
        echo "No saved game found."
    fi
}

function main_menu {
    clear
    echo "Welcome to Tic-Tac-Toe"
    echo "1. Player vs Player"
    echo "2. Player vs Computer"
    echo "3. Load Game"
    echo "4. Exit"
    echo
    read -p "Choose an option (1-4): " CHOICE

    case "$CHOICE" in
        1)
            GAME_MODE="pvp"
            game_loop_pvp
            ;;
        2)
            GAME_MODE="pvc"
            game_loop_pvc
            ;;
        3)
            load_game
            ;;
        4)
            echo "Exiting game."
            exit
            ;;
        *)
            echo "Invalid choice. Please enter 1, 2, 3, or 4."
            main_menu
            ;;
    esac
}

main_menu
