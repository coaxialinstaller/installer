#!/bin/bash

if [[ $1 == "" ]]
then
    echo "Give Program"
    exit 1
fi

sudo echo &>/dev/null

program=$1

which apt 2>/dev/null | grep /apt &>/dev/null && PM="apt"
which pacman 2>/dev/null | grep /pacman &>/dev/null && PM="pacman"
[[ $PM == "" ]] && echo No && exit 0

exit=false
ls $program-install &>/dev/null || exit=true
$exit && echo "Program not install in the directory"
$exit && exit 0

if [[ $PM == "pacman" ]]
then
    echo "Installing $program..."
    for i in $(ls $program-install | grep -v .sig)
    do
        sudo pacman -U --noconfirm $program-install/$i &>/dev/null
    done
elif [[ $PM == "apt" ]]
then
    echo "Installing $program..."
    sudo dpkg -i $program-install/* &>/dev/null
fi