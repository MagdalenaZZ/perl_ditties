#!/bin/bash




if [ "$1" == "-h" ]; then
  echo "Usage: bash `basename $0` file-name"
  echo "Takes a variant annotation call, and converts it to a FileMaker input file"
  exit 0
fi


if [ ! -f $1 ]; then
  echo "Usage: bash `basename $0` file-name"
  echo "Takes a variant annotation call, and converts it to a FileMaker input file"
  echo "Add a file after the command"
  exit 0
fi



in=$1

file="$1.txt"
genefile="$1.gene"

#echo "$in $file"



cat $in | head -1 |  tr '\t' '\n' | paste - - - - - - - - - > $genefile


caveat=$(cat $in | tail -1 |  tr '\t' '\n' | head -2)

printf "\n\n"
echo $caveat
printf "\n\n"

length=$(cat $in | tail -1 |  tr '\t' '\n' | wc -l)
length2=$(echo $length-2 | bc)

#echo $length2

cat $in | tail -1 |  tr '\t' '\n'    | tail -$length2 | paste - - - - - - - - -  | grep -v 'No Variant Detected' | grep -v 'No Result' | grep '/' > $file


exit 0


