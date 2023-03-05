#!/bin/bash

if [[ $1 == "" ]]
then
    echo "Program"
    exit 1
fi

fail=false
program=$1

which apt 2>/dev/null | grep /apt &>/dev/null && PM="apt"
which pacman 2>/dev/null | grep /pacman &>/dev/null && PM="pacman"
[[ $PM == "" ]] && echo No && exit 0


[[ $PM == "apt" ]] && dependencies=$(apt-cache depends $program | grep -vE "Recommends|Suggests|Breaks|Conflicts|Depends: <" | sed 's/.*Depends: //' | sed 's/\ *//')
[[ $PM == "pacman" ]] && dependencies=$(sudo pacman -Qi $program | grep "Depends On" | sed 's/.*: //' | perl -pe 's/ +/\n/g' && echo $program)
[[ $dependencies == "" ]] && fail=true

mkdir -p $program-install
cd $program-install

if [[ $PM == "apt" ]]
then
    echo "Downloading $program..."
    for i in $dependencies
    do
        apt download $i &>/dev/null || fail=true
        $fail && break
    done
elif [[ $PM == "pacman" ]]
then
    sudo mkdir -p /var/cache/pacman/pkg-tmp
    sudo mv /var/cache/pacman/pkg/* /var/cache/pacman/pkg-tmp

    echo "Downloading $program..."

    for i in $dependencies
    do
        sudo pacman -Sw --noconfirm $i &>/dev/null

    done
    sudo mv /var/cache/pacman/pkg/* .
    sudo mv /var/cache/pacman/pkg-tmp/* /var/cache/pacman/pkg
    sudo rm -rf /var/cache/pacman/pkg-tmp
fi

cd - > /dev/null

$fail && rm -rf $program-install