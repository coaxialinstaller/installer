#!/bin/bash

if [[ $1 == "" ]]
then
    echo "Give Program"
    exit 1
fi

repeatChar() {
    local input="$1"
    local count="$2"
    printf -v myString '%*s' "$count"
    printf '%s\n' "${myString// /$input}"
}


sudo echo &>/dev/null

program=$1

which apt 2>/dev/null | grep /apt &>/dev/null && PM="apt"
which pacman 2>/dev/null | grep /pacman &>/dev/null && PM="pacman"
[[ $PM == "" ]] && echo "Error: Couldn't recognize package manager..." && exit 0


fail=false

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
        sudo pacman -U --noconfirm $program-install/$i &>/dev/null

        fo=$(($fo+1))

        big=$(((($po*100/$packages)*$fo)/100))
        small=$(($po-$big))
        str=$(repeatChar "=" $big)$(repeatChar "-" $small )
        echo -ne "\r[$str] ($(($fo*100/$packages))%)"
    done

    $fail && echo && echo "Error downloading $program..."
    $fail && exit 1

    str=$(repeatChar "=" $po)
    echo -ne "\r[$str] (100%)"
    echo
    echo "Finished Downloading $program."

elif [[ $PM == "apt" ]]
then

    packages=$(cat dependencies | wc -l)
    po=30
    fo=0

    echo "Installing $program..."
    big=$(((($po*100/$packages)*$fo)/100))
    small=$(($po-$big))
    str=$(repeatChar "=" $big)$(repeatChar "-" $small )
    echo -ne "\r[$str] ($(($fo*100/$packages))%)"

    for i in $(ls $program-install | grep -v .sig)
    do

        sudo dpkg -i $program-install/* &>/dev/null || fail=true
        $fail && break

        fo=$(($fo+1))

        big=$(((($po*100/$packages)*$fo)/100))
        small=$(($po-$big))
        str=$(repeatChar "=" $big)$(repeatChar "-" $small )
        echo -ne "\r[$str] ($(($fo*100/$packages))%)"

    done

    $fail && echo && echo "Error downloading $program..."
    $fail && exit 1

    str=$(repeatChar "=" $po)
    echo -ne "\r[$str] (100%)"
    echo
    echo "Finished Downloading $program."
fi