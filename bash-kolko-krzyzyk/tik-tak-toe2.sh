#!/usr/bin/env bash

# ZMIENNE GLOBALNE
PLANSZA=("0" "1" "2" "3" "4" "5" "6" "7" "8")
GRACZ="1"
WYGRANA="0"
MARK="o"
LICZBA_TUR=9

BLEDNE_POLE="0"
ZAJETE_POLE="0"

PLIK_Z_ZAPISAMI="saves.txt"
GAME_MODE=""

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
BOLD='\033[1m'

function kolorowy_znak {
    local znak="$1"
    if [[ "$znak" == "x" ]]; then
        echo -e "${RED}x${NC}"
    elif [[ "$znak" == "o" ]]; then
        echo -e "${GREEN}o${NC}"
    else
        echo "$znak"
    fi
}

function wyswietl {
    local gracz
    if ["$GRACZ" == 1]; then
      gracz = "Gracz"
    else
      gracz = "Komputer"
    fi

    clear
    echo
    echo -e "${BLUE}       ┌───┬───┬───┐${NC}"
    echo -e "${BLUE}       │${NC} $(kolorowy_znak "${PLANSZA[0]}") ${BLUE}│${NC} $(kolorowy_znak "${PLANSZA[1]}") ${BLUE}│${NC} $(kolorowy_znak "${PLANSZA[2]}") ${BLUE}│${NC}"
    echo -e "${BLUE}       ├───┼───┼───┤${NC}"
    echo -e "${BLUE}       │${NC} $(kolorowy_znak "${PLANSZA[3]}") ${BLUE}│${NC} $(kolorowy_znak "${PLANSZA[4]}") ${BLUE}│${NC} $(kolorowy_znak "${PLANSZA[5]}") ${BLUE}│${NC}"
    echo -e "${BLUE}       ├───┼───┼───┤${NC}"
    echo -e "${BLUE}       │${NC} $(kolorowy_znak "${PLANSZA[6]}") ${BLUE}│${NC} $(kolorowy_znak "${PLANSZA[7]}") ${BLUE}│${NC} $(kolorowy_znak "${PLANSZA[8]}") ${BLUE}│${NC}"
    echo -e "${BLUE}       └───┴───┴───┘${NC}"
    echo
    echo -e "${BLUE}╔════════════════════════════════════╗${NC}"
        if [[ "${GRACZ}" == "1" ]]; then
            echo -e "${BLUE}║  ${NC}GRACZ: ${GRACZ} (${GREEN}O${NC})                     ${BLUE} ║${NC}"
        else
            echo -e "${BLUE}║  ${NC}GRACZ: ${GRACZ} (${RED}X${NC})                  ${BLUE}    ║${NC}"
        fi
    echo -e "${BLUE}║  ${NC}Prosze wybrac numer pola od 0 do 8${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}  ${PURPLE}Press 's' to save game${NC}            ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════╝${NC}"
}

function sprawdzKomorki {
    if [[ "${PLANSZA[${1}]}" == "${PLANSZA[${2}]}" ]] && \
       [[ "${PLANSZA[${2}]}" == "${PLANSZA[${3}]}" ]] && \
       [[ "${PLANSZA[${3}]}" == "${MARK}" ]]; then
        WYGRANA="1"
    fi
}

function sprawdzWygrana {
    # First check all winning combinations
    if [[ "${WYGRANA}" -ne "1" ]];then
        sprawdzKomorki 0 1 2
    fi
    if [[ "${WYGRANA}" -ne "1" ]];then
        sprawdzKomorki 3 4 5
    fi
    if [[ "${WYGRANA}" -ne "1" ]];then
        sprawdzKomorki 6 7 8
    fi
    if [[ "${WYGRANA}" -ne "1" ]];then
        sprawdzKomorki 0 3 6
    fi
    if [[ "${WYGRANA}" -ne "1" ]];then
        sprawdzKomorki 1 4 7
    fi
    if [[ "${WYGRANA}" -ne "1" ]];then
        sprawdzKomorki 2 5 8
    fi
    if [[ "${WYGRANA}" -ne "1" ]];then
        sprawdzKomorki 0 4 8
    fi
    if [[ "${WYGRANA}" -ne "1" ]];then
        sprawdzKomorki 6 4 2
    fi

    # If there's a winner, display the win message
    if [[ "${WYGRANA}" -eq "1" ]]; then
        wyswietl
        if [[ "${GRACZ}" == "1" ]]; then
            echo -e "Wygrał gracz ${GRACZ} (${GREEN}O${NC})"
        else
            echo -e "Wygrał gracz ${GRACZ} (${RED}X${NC})"
        fi
        return 1
    fi

    # Only check for a tie if there is no winner
    if [[ ${LICZBA_TUR} -le 0 ]]; then
        wyswietl
        echo "REMIS !!!"
        return 1
    fi
}

function zmienGracza {
    if [ "${GRACZ}" -eq "1" ];
    then
        GRACZ="2"
        MARK="x"
    else
        GRACZ="1"
        MARK="o"
    fi
}

function komunikatWyboruPola {
    if [[ "${BLEDNE_POLE}" -eq "1" ]]; then
        echo -e "\nPodano zly numer pola"
        BLEDNE_POLE="0"
    elif [[ "${ZAJETE_POLE}" -eq "1" ]]; then
        echo -e "\nTo pole jest juz zajete"
        ZAJETE_POLE="0"
    fi
}

function sprawdzWyborPola {
    if [[ "${POLE}" == "s" ]]; then
        echo "Zapisywanie gry"
        zapiszGre
        exit 0
    elif [[ ${POLE} -lt 0 ]] || [[ ${POLE} -gt 8 ]];then
        BLEDNE_POLE="1"
        return 1
    elif [[ "${PLANSZA["${POLE}"]}" == "o" ]] || [[ "${PLANSZA["${POLE}"]}" == "x" ]];then
        ZAJETE_POLE="1"
        return 1
    else
        PLANSZA[POLE]="${MARK}"
        LICZBA_TUR=$((LICZBA_TUR-1))
        return 0
    fi
}

function zapiszGre {
    echo "Podaj nazwe zapisu: "
    read -r save_name
    echo "${save_name} | ${GAME_MODE} | ${PLANSZA[0]} | \
${PLANSZA[1]} | ${PLANSZA[2]} | ${PLANSZA[3]} | \
${PLANSZA[4]} | ${PLANSZA[5]} | ${PLANSZA[6]} | \
${PLANSZA[7]} | ${PLANSZA[8]}" >> "${PLIK_Z_ZAPISAMI}"
}

function gra_pvp {
    while [ "${WYGRANA}" -eq "0" ]
    do
        wyswietl
        komunikatWyboruPola
        read -r POLE
        sprawdzWyborPola
        sprawdzWygrana

        if [[ ${?} -eq 1 ]]; then
            break
        fi

        if [ "${BLEDNE_POLE}" == "0" ] && [[ "${ZAJETE_POLE}" == "0" ]]; then
            zmienGracza
        fi
    done
}

function gra_pve {
    while [ "${WYGRANA}" -eq "0" ]
    do
        wyswietl
        komunikatWyboruPola

        if [[ "${GRACZ}" == "2" ]]; then
            # Keep trying until a valid move is found
            while true; do
                POLE=$(ruch_komputera)
                sprawdzWyborPola
                if [ $? -eq 0 ]; then
                    break
                fi
            done
        else
            read -r POLE
            sprawdzWyborPola
        fi

        sprawdzWygrana

        if [[ ${?} -eq 1 ]]; then
            break
        fi

        if [ "${BLEDNE_POLE}" == "0" ] && [[ "${ZAJETE_POLE}" == "0" ]]; then
            zmienGracza
        fi
    done
}

function sprawdzKombinacje {
    [[ ${PLANSZA[${1}]} == "o" ]] && [[ ${PLANSZA[${2}]} == "o" ]] && [[ ${PLANSZA[${3}]} != "x" ]] && [[ ${PLANSZA[${3}]} != "o" ]] && echo 1 && return
}

function ruch_komputera {
    PUSTE_POLA=()

    local array_counter
    array_counter=0

    for i in "${PLANSZA[@]}"
    do
        if [[ "${i}" != "o" ]] && [[ "${i}" != "x" ]]; then
            PUSTE_POLA+=("${array_counter}")
        fi
        array_counter=$((array_counter+1))
    done

    # Sprawdza czy gracz nie ma wygranej w zasiegu. Jezeli tak to zablokuj

    # POZIOMO
    [[ $( sprawdzKombinacje 0 1 2 ) == "1" ]] && echo 2 && return
    [[ $( sprawdzKombinacje 0 2 1 ) == "1" ]] && echo 1 && return
    [[ $( sprawdzKombinacje 1 2 0 ) == "1" ]] && echo 0 && return

    [[ $( sprawdzKombinacje 3 4 5 ) == "1" ]] && echo 5 && return
    [[ $( sprawdzKombinacje 3 5 4 ) == "1" ]] && echo 4 && return
    [[ $( sprawdzKombinacje 4 5 3 ) == "1" ]] && echo 3 && return

    [[ $( sprawdzKombinacje 6 7 8 ) == "1" ]] && echo 8 && return
    [[ $( sprawdzKombinacje 6 8 7 ) == "1" ]] && echo 7 && return
    [[ $( sprawdzKombinacje 7 8 6 ) == "1" ]] && echo 6 && return

    #PIONOWO
    [[ $( sprawdzKombinacje 2 5 8 ) == "1" ]] && echo 8 && return
    [[ $( sprawdzKombinacje 2 8 5 ) == "1" ]] && echo 5 && return
    [[ $( sprawdzKombinacje 5 8 2 ) == "1" ]] && echo 2 && return

    [[ $( sprawdzKombinacje 0 3 6 ) == "1" ]] && echo 6 && return
    [[ $( sprawdzKombinacje 0 6 3 ) == "1" ]] && echo 3 && return
    [[ $( sprawdzKombinacje 3 6 0 ) == "1" ]] && echo 0 && return

    [[ $( sprawdzKombinacje 1 4 7 ) == "1" ]] && echo 7 && return
    [[ $( sprawdzKombinacje 1 7 4 ) == "1" ]] && echo 4 && return
    [[ $( sprawdzKombinacje 4 7 1 ) == "1" ]] && echo 1 && return

    # PO SKOSIE
    [[ $( sprawdzKombinacje 0 4 8 ) == "1" ]] && echo 8 && return
    [[ $( sprawdzKombinacje 0 8 4 ) == "1" ]] && echo 4 && return
    [[ $( sprawdzKombinacje 4 8 0 ) == "1" ]] && echo 0 && return

    [[ $( sprawdzKombinacje 2 4 6 ) == "1" ]] && echo 6 && return
    [[ $( sprawdzKombinacje 2 6 4 ) == "1" ]] && echo 4 && return
    [[ $( sprawdzKombinacje 4 6 2 ) == "1" ]] && echo 2 && return

    # Jezeli nie ma ty wybierz losowe pole z dostepnych
    if [ ${#PUSTE_POLA[@]} -gt 0 ]; then
        wybrane_pole=${PUSTE_POLA[ $RANDOM % ${#PUSTE_POLA[@]} ]}
        echo "${wybrane_pole}"
    else
        echo "0" # Default fallback
    fi
}

function main_menu {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║         ${YELLOW}${BOLD}Kółko i krzyżyk by M.K.${NC}      ${BLUE}║${NC}"
    echo -e "${BLUE}╠══════════════════════════════════════╣${NC}"
    echo -e "${BLUE}║                                      ║${NC}"
    echo -e "${BLUE}║${NC}    ${GREEN}1.${NC} Nowa gra                       ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}    ${GREEN}2.${NC} załaduj grę                    ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}    ${GREEN}3.${NC} Wyjście                        ${BLUE}║${NC}"
    echo -e "${BLUE}║                                      ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
    echo
    echo -e "Please enter your choice ${GREEN}[1-3]${NC}: "
    read -r CHOICE

    if [[ "${CHOICE}" -eq "1" ]]; then
        mode_menu
    elif [[ "${CHOICE}" -eq "2" ]]; then
        load_menu
    elif [[ "${CHOICE}" -eq "3" ]]; then
        exit
    fi
}

function show_saves {
    cat "${PLIK_Z_ZAPISAMI}" | while read line; do
        echo $line
    done
}

function get_save {
    cat "${PLIK_Z_ZAPISAMI}" | while read line; do
        local nazwa
        nazwa=$( echo "${line}" | cut -d '|' -f1 | xargs)
        if [[ "${save_to_load}" == "${nazwa}" ]]; then
            echo "${line}" | cut -d '|' -f2-
            break
        fi
    done
}

function load_save {
    local save_string

    local save_to_load="${1}"
    save_string=$(get_save "${1}")

    first=0
    array_counter=0

    IFS="|"
    for i in "${save_string[@]}"
    do
        if [[ ${first} -eq 0 ]]; then
            GAME_MODE=$( echo "${i}" | xargs )
            first=1
        else
            PLANSZA["${array_counter}"]=$( echo "${i}" | xargs )
            array_counter=$((array_counter+1))
        fi
    done
}

function load_menu {
    clear
    echo "Choose save to load:"
    show_saves
    echo "Wybierz zapis do wczytania, podajac nazwe (pierwsza kolumna)"
    read -r load_choice
    echo "Wczytywania ${load_choice}"
    load_save "${load_choice}"

    if [[ "${GAME_MODE}" == "pvp" ]]; then
        gra_pvp
    elif [[ "${GAME_MODE}" == "pve" ]]; then
        gra_pve
    fi
}

function mode_menu {

	clear
  echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║         ${YELLOW}${BOLD}Kółko i krzyżyk by M.K.${NC}      ${BLUE}║${NC}"
  echo -e "${BLUE}╠══════════════════════════════════════╣${NC}"
  echo -e "${BLUE}║                                      ║${NC}"
  echo -e "${BLUE}║${NC}    ${GREEN}1.${NC} Player vs Player               ${BLUE}║${NC}"
  echo -e "${BLUE}║${NC}    ${GREEN}2.${NC} Player vs Computer             ${BLUE}║${NC}"
  echo -e "${BLUE}║                                      ║${NC}"
  echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
  echo
  echo -e "Please enter your choice ${GREEN}[1-3]${NC}: "
	read -r mode_choice


	if [[ "${mode_choice}" -eq "1" ]]; then
		GAME_MODE="pvp"
		gra_pvp
	elif [[ "${mode_choice}" -eq "2" ]]; then
    GAME_MODE="pve"
    gra_pve
	fi
}


main_menu
