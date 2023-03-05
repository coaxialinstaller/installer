#!/bin/bash

if [[ $1 == "" ]]
then
    echo "Fuck you"
    exit 1
fi

sudo echo

program=$1

exit=false
ls $program-install > /dev/null || $exit=true
if [[ $(exit) == true ]]
then
echo "Program not install in the directory"
exit
fi

sudo dpkg -i $program-install/*
