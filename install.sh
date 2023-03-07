#!/bin/bash

if [[ $1 == "--pip" ]]
then
    if [[ $2 == "" ]]
    then
        echo "--pip (optional) program (requierd)"
        exit 1
    fi
fi

if ! [[ $1 == "--pip" ]]
then
    if ! [[ $2 == "" ]]
    then
        echo "--pip (optional) program (requierd)"
        exit 1
    fi
fi

if [[ $1 == "" ]]
then
    echo "--pip (optional) program (requierd)"
    exit 1
fi

sudo echo &>/dev/null

repeatChar() {
    local input="$1"
    local count="$2"
    printf -v myString '%*s' "$count"
    printf '%s\n' "${myString// /$input}"
}

fail=false
if ! [[ $2 == "" ]]
then
program=$2
PM="pip"
else
program=$1
fi

! [[ $PM == "pip" ]] && which apt 2>/dev/null | grep /apt &>/dev/null && PM="apt"
! [[ $PM == "pip" ]] && which pacman 2>/dev/null | grep /pacman &>/dev/null && PM="pacman"
[[ $PM == "" ]] && echo "Error: Couldn't recognize package manager..." && exit 0


exit=false
ls $program-install &>/dev/null || exit=true
$exit && echo "Error: Couldn't find packages to install..."
$exit && exit 0



if [[ $PM == "pacman" ]]
then

    packages=$(ls $program-install | grep -v .sig | wc -l)
    po=30
    fo=0

    echo "Installing $program..."
    big=$(((($po*100/$packages)*$fo)/100))
    small=$(($po-$big))
    str=$(repeatChar "=" $big)$(repeatChar "-" $small )
    echo -ne "\r[$str] ($(($fo*100/$packages))%)"


    for i in $(ls $program-install | grep -v .sig)
    do
        sudo pacman -U --noconfirm $program-install/$i &>/dev/null || fail=true
        $fail && break

        fo=$(($fo+1))

        big=$(((($po*100/$packages)*$fo)/100))
        small=$(($po-$big))
        str=$(repeatChar "=" $big)$(repeatChar "-" $small )
        echo -ne "\r[$str] ($(($fo*100/$packages))%)"
    done

    $fail && echo && echo "Error installing $program..."
    $fail && exit 1

    str=$(repeatChar "=" $po)
    echo -ne "\r[$str] (100%)"
    echo
    echo "Finished installing $program successfully!"

elif [[ $PM == "apt" ]]
then

    packages=$(ls $program-install | wc -l)
    po=30
    fo=0

    echo "Installing $program..."
    big=$(((($po*100/$packages)*$fo)/100))
    small=$(($po-$big))
    str=$(repeatChar "=" $big)$(repeatChar "-" $small )
    echo -ne "\r[$str] ($(($fo*100/$packages))%)"

    for i in $(ls $program-install)
    do

        sudo dpkg -i $program-install/$i &>/dev/null || fail=true
        $fail && break

        fo=$(($fo+1))

        big=$(((($po*100/$packages)*$fo)/100))
        small=$(($po-$big))
        str=$(repeatChar "=" $big)$(repeatChar "-" $small )
        echo -ne "\r[$str] ($(($fo*100/$packages))%)"

    done

    $fail && echo && echo "Error installing $program..."
    $fail && exit 1

    str=$(repeatChar "=" $po)
    echo -ne "\r[$str] (100%)"
    echo
    echo "Finished installing $program successfully!"

elif [[ $PM == "pip" ]]
then

    pip --version > /dev/null || fail=true
    $fail && echo "Pip not installed" && exit 1

    packages=$(ls $program-install | wc -l)
    po=30
    fo=0

    echo "Installing $program..."
    big=$(((($po*100/$packages)*$fo)/100))
    small=$(($po-$big))
    str=$(repeatChar "=" $big)$(repeatChar "-" $small )
    echo -ne "\r[$str] ($(($fo*100/$packages))%)"

    for i in $(ls $program-install)
    do

        pip install $program-install/$i &>/dev/null || fail=true
        $fail && break

        fo=$(($fo+1))

        big=$(((($po*100/$packages)*$fo)/100))
        small=$(($po-$big))
        str=$(repeatChar "=" $big)$(repeatChar "-" $small )
        echo -ne "\r[$str] ($(($fo*100/$packages))%)"

    done
    $fail && echo && echo "Error installing $program..."
    $fail && exit 1

    str=$(repeatChar "=" $po)
    echo -ne "\r[$str] (100%)"
    echo
    echo "Finished installing $program successfully!"
fi