#!/bin/bash

# Make sure script is running with sudo privileges
sudo echo &>/dev/null

# Make sure there is an internet connection

if ! ping 8.8.8.8 -c 1 &>/dev/null
then
        echo "Failed to download package $package, no internet connection!"
        exit 1
fi


help() {
echo "Usage: $(basename $0) [OPTION]... [PACKAGES-TO-DOWNLOAD]...
Download all files locally needed to install a given package, without installing the package itself.

Flags:

  -p,  --pip    Use pip as the package manager
  -f,  --full   Download all dependencies recursively
  -h,  --help   Show this help page


This script is written by py-er and arch-err, see github links below:
https://github.com/py-er/
https://github.com/arch-err/
The source of this script can be found at https://github.com/py-er/local-installer"
}

repeatChar() {
    local input="$1"
    local count="$2"
    printf -v myString '%*s' "$count"
    printf '%s\n' "${myString// /$input}"
}


PACMAN() {

    sudo mkdir -p /var/cache/pacman/pkg-tmp
    sudo mv /var/cache/pacman/pkg/* /var/cache/pacman/pkg-tmp

    pkgs=$(cat dependencies | wc -l)
    po=30
    fo=0

    echo "Downloading $package..."
    big=$(((($po*100/$pkgs)*$fo)/100))
    small=$(($po-$big))
    str=$(repeatChar "=" $big)$(repeatChar "-" $small )
    echo -ne "\r[$str] ($(($fo*100/$pkgs))%)"

    for i in $(cat dependencies)
    do
        sudo pacman -Sw --noconfirm $i &>/dev/null || fail=true
        $fail && break
        fo=$(( $fo+1 ))

        big=$(( ( ($po*100/$pkgs) *$fo)/100 ))
        small=$(($po-$big))
        str=$(repeatChar "=" $big)$(repeatChar "-" $small )
        echo -ne "\r[$str] ($(( $fo*100/$pkgs ))%)"

    done

    $fail && echo && echo "Error downloading $package..." && rm dependencies
    $fail && $deldir && cd .. && rm -rf $package-install
    $fail && exit 1

    str=$(repeatChar "=" $po)
    echo -ne "\r[$str] (100%)"
    echo
    echo "Finished downloading $package successfully!"
    rm dependencies

    sudo mv /var/cache/pacman/pkg/* .
    sudo mv /var/cache/pacman/pkg-tmp/* /var/cache/pacman/pkg
    sudo rm -rf /var/cache/pacman/pkg-tmp
        exit 0
}

APT() {
        cd $package-install
        apt-cache depends $package | grep -vE "Recommends|Suggests|Breaks|Conflicts|Depends: <|Replaces:|Enhances:" | perl -pe 's/.*Depends: //; s/\ *//' > dependencies


        pkgs=$(cat dependencies | wc -l)
        po=30
        fo=0

        echo "Downloading $package..."
        big=$(( ( ($po*100/$pkgs) * $fo)/100 ))
        small=$(( $po - $big ))
        str=$(repeatChar "=" $big)$(repeatChar "-" $small )
        echo -ne "\r[$str] ($(( $fo * 100 / $pkgs))%)"

        for i in $(cat dependencies)
        do
            apt download $i &>/dev/null || fail=true
            $fail && break
            fo=$(($fo+1))

            big=$(( (($po*100/$pkgs) * $fo)/100 ))
            small=$(( $po - $big ))
            str=$(repeatChar "=" $big)$(repeatChar "-" $small )
            echo -ne "\r[$str] ($(($fo*100/$pkgs))%)"
        done

        if $fail
        then
                echo
                echo "Error downloading $package..."
                rm dependencies
                if $deldir
                then
                        cd ..
                        rm -rf $package-install
                fi
                exit 1

        fi

        str=$(repeatChar "=" $po)
        echo -ne "\r[$str] (100%)"
        echo
        echo "Finished downloading $package successfully!"
        rm dependencies


}

PIP() {
    pip --version > /dev/null || fail=true
    $fail && echo "Pip not installed" && exit 1

    po=30

    echo "Downloading $program..."
    str=$(repeatChar "-" $po)
    echo -ne "[$str] (0%)"
    pip download $program &>/dev/null || fail=true

    if [[ $fail ]]
    then
    echo
    echo "Faild to download program $program, program was not found!"
    $deldir
    cd ..
    rm -rf $program-install
    exit 1
    fi

    str=$(repeatChar "=" $po)
    echo -ne "\r[$str] (100%)"
    echo
    echo "Finished downloading $program successfully!"

    cd - > /dev/null

    exit 0
}

APT_FULL() {
    added=no
    for depends in $(cat dependencies)
    do  
        if ! [[ $(grep -P "^$depends$" checked) ]]
        echo $depends >> checked
        then
            apt-cache depends $depends 2>/dev/null | perl -pe "s/<.*>//g" > deps && vim deps -c "%s/\n    */ /g" -c wq 
            deps=$(cat deps | grep -vE "Recommends|Suggests|Breaks|Conflicts|Depends: <|Replaces:|Enhances:" | sed 's/.*Depends: //' | sed 's/\ *//')

            for x in $deps
            do
                old_deps_file=$(cat dependencies | sort | uniq)
                cat dependencies > tmp.dependencies
                echo $x >> tmp.dependencies
                new_deps_file=$(cat tmp.dependencies | sort | uniq)
                diff=$(diff <(echo $old_deps_file) <(echo $new_deps_file))
                if [[ $diff ]]
                then
                echo $new_deps_file | perl -pe "s/\ /\n/g" > dependencies
                added=yes
                fi
            done
        fi
    done

    if [[ $added == no ]]
    then
    going=false

    ## Clean-up ##
    rm tmp.dependencies deps checked

    fi
}


FULL=false
usePIP=false


packages=$(echo "$@" | perl -pe "s/ /\n/g" | grep -v "-")


# Handle options/flags
flags=$(echo "$@" | perl -pe "s/ /\n/g" | grep "-")
ARGS=$(getopt --options pfh --long "pip,full,help" -- $flags)
eval set --"$ARGS"
while true
do
        case "$1" in
                -f|--full) FULL=true; shift;;
                -p|--pip) usePIP=true; shift;;
                -h|--help) help; shift;;
                --) break ;;
                *) help; exit 1 ;;
        esac
done

fail=false
echo $packages
exit 1
for package in $packages
do
        mkdir -p $package-install
        deldir=false
done

$usePIP && PIP hello

[[ -z $(ls) ]] && deldir=true

which apt 2>/dev/null | grep /apt &>/dev/null && for package in $packages
do
        APT 
        echo 

        cd - > /dev/null
        $fail && $deldir && rm -rf $package-install
done && exit 0

which pacman 2>/dev/null | grep /pacman &>/dev/null && PACMAN && for package in $packages
do
        PACMAN
        echo 
        cd - > /dev/null
        $fail && $deldir && rm -rf $package-install
done && exit 0


echo "Error: Couldn't recognize package manager..." 
exit 1
