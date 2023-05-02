#!/bin/bash

if [[ $2 == "--full" ]]
then
full=true
else
full=false
fi

sudo echo

repeatChar() {
    local input="$1"
    local count="$2"
    printf -v myString '%*s' "$count"
    printf '%s\n' "${myString// /$input}"
}

full_() {
    added=no
    for depends in $(cat dependencies)
    do
        deps=$([[ $PM == "apt" ]] && apt-cache depends $depends 2>/dev/null | grep -vE "Recommends|Suggests|Breaks|Conflicts|Depends: <|Replaces:|Enhances:" | sed 's/.*Depends: //' | sed 's/\ *//')
        for x in $deps
        do
            echo $x >> dependencies
            
            added=yes
            echo yes
            else
            echo no
            fi
        done
    done

    if [[$added == no]]
    then
    going=false
    fi
}

program=$1

fail=false
if [[ $2 == "--pip" ]]
then
PM="pip"
fi

no_internet=false
ping 8.8.8.8 -c 1 > /dev/null || no_internet=true
$no_internet && echo "Failed to download program $program, no internet connection!" && exit 0


! [[ $PM == "pip" ]] && which apt 2>/dev/null | grep /apt &>/dev/null && PM="apt"
! [[ $PM == "pip" ]] && which pacman 2>/dev/null | grep /pacman &>/dev/null && PM="pacman"
[[ $PM == "" ]] && echo "Error: Couldn't recognize package manager..." && exit 0


mkdir -p $program-install
cd $program-install
deldir=false
[[ $(ls) == "" ]] && deldir=true


[[ $PM == "apt" ]] && apt-cache depends $program | grep -vE "Recommends|Suggests|Breaks|Conflicts|Depends: <|Replaces:|Enhances:" | sed 's/.*Depends: //' | sed 's/\ *//' > dependencies
[[ $PM == "pacman" ]] && sudo pacman -Qi $program 2>/dev/null | grep "Depends On" | sed 's/.*: //' | perl -pe 's/ +/\n/g' > dependencies
! [[ $PM == "pip" ]] && [[ $(cat dependencies) == "" ]] && fail=true
$fail && cd .. && rm -rf $program-install && echo "Faild to download program $program, program was not found!" &&  exit 1
[[ $PM == "pacman" ]] && echo $program >> dependencies

if [[ $full ]]
then
    going=true
    while $going
    do
        full_
    done
fi

cat dependencies

exit 1

if [[ $PM == "apt" ]]
then
    packages=$(cat dependencies | wc -l)
    po=30
    fo=0

    echo "Downloading $program..."
    big=$(((($po*100/$packages)*$fo)/100))
    small=$(($po-$big))
    str=$(repeatChar "=" $big)$(repeatChar "-" $small )
    echo -ne "\r[$str] ($(($fo*100/$packages))%)"

    for i in $(cat dependencies)
    do
        apt download $i &>/dev/null || fail=true
        $fail && break
        fo=$(($fo+1))

        big=$(((($po*100/$packages)*$fo)/100))
        small=$(($po-$big))
        str=$(repeatChar "=" $big)$(repeatChar "-" $small )
        echo -ne "\r[$str] ($(($fo*100/$packages))%)"
    done

    $fail && echo && echo "Error downloading $program..." && rm dependencies
    $fail && $deldir && cd .. && rm -rf $program-install
    $fail && exit 1

    str=$(repeatChar "=" $po)
    echo -ne "\r[$str] (100%)"
    echo
    echo "Finished downloading $program successfully!"
    rm dependencies


elif [[ $PM == "pacman" ]]
then
    sudo mkdir -p /var/cache/pacman/pkg-tmp
    sudo mv /var/cache/pacman/pkg/* /var/cache/pacman/pkg-tmp

    packages=$(cat dependencies | wc -l)
    po=30
    fo=0

    echo "Downloading $program..."
    big=$(((($po*100/$packages)*$fo)/100))
    small=$(($po-$big))
    str=$(repeatChar "=" $big)$(repeatChar "-" $small )
    echo -ne "\r[$str] ($(($fo*100/$packages))%)"

    for i in $(cat dependencies)
    do
        sudo pacman -Sw --noconfirm $i &>/dev/null || fail=true
        $fail && break
        fo=$(($fo+1))

        big=$(((($po*100/$packages)*$fo)/100))
        small=$(($po-$big))
        str=$(repeatChar "=" $big)$(repeatChar "-" $small )
        echo -ne "\r[$str] ($(($fo*100/$packages))%)"

    done

    $fail && echo && echo "Error downloading $program..." && rm dependencies
    $fail && $deldir && cd .. && rm -rf $program-install
    $fail && exit 1

    str=$(repeatChar "=" $po)
    echo -ne "\r[$str] (100%)"
    echo
    echo "Finished downloading $program successfully!"
    rm dependencies

    sudo mv /var/cache/pacman/pkg/* .
    sudo mv /var/cache/pacman/pkg-tmp/* /var/cache/pacman/pkg
    sudo rm -rf /var/cache/pacman/pkg-tmp
elif [[ $PM == "pip" ]]
then
    pip --version > /dev/null || fail=true
    $fail && echo "Pip not installed" && exit 1

    po=30

    echo "Downloading $program..."
    str=$(repeatChar "-" $po)
    echo -ne "[$str] (0%)"
    pip download $program &>/dev/null || fail=true

    $fail && echo && echo "Faild to download program $program, program was not found!"
    $fail && $deldir && cd .. && rm -rf $program-install
    $fail && exit 1

    str=$(repeatChar "=" $po)
    echo -ne "\r[$str] (100%)"
    echo
    echo "Finished downloading $program successfully!"

fi

cd - > /dev/null

$fail && $deldir && rm -rf $program-install