#!/bin/bash

if [[ $1 == "" ]]
then
    echo "Program"
    exit 1
fi

fail=false
program=$1
dependencies=$(apt-cache depends $program | grep -vE "Recommends|Suggests|Breaks|Conflicts|Depends: <" | sed 's/.*Depends: //' | sed 's/\ *//')

if [[ $dependencies == "" ]]
then
    fail=true
fi

mkdir -p $program-install
cd $program-install

for i in $dependencies
do
    apt download $i || fail=true
    $fail && break
done

cd - > /dev/null

$fail && rm -rf $program-install