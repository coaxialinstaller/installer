#!/bin/bash

if [[ $1 == "" ]]
then
    echo "Give Program"
    exit 1
fi

sudo echo

program=$1

which apt 2>/dev/null | grep /apt &>/dev/null && PM="apt"
which pacman 2>/dev/null | grep /pacman &>/dev/null && PM="pacman"
[[ $PM == "" ]] && echo No && exit 0

exit=false
ls $program-install > /dev/null || $exit=true
if [[ $(exit) == true ]]
then
echo "Program not install in the directory"
exit 0
fi

if [[ $PM == "pacman" ]]
then
for i in $(ls $program-install | grep -v .sig)
do
    sudo pacman -U --noconfirm $program-install/$i
done
elif [[ $PM == "apt" ]]
then
    sudo dpkg -i $program-install/*
fi
