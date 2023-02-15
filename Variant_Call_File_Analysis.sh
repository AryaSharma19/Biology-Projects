#!/bin/bash
#Arya Sharma, Fall 2022
#This is a bash script that takes in two .vcf files and outputs the genomic position where each call file differ
#It is expected that the two inputs are from the same lineage
#Inputs are hardcoded on lines 12 and 13
#It helps to cut the headers of the .vcf files first before running them with this script.


touch tempoutput
touch tempoutputR
touch tempreport
cut -f2,4,5 T70B_data.txt > temp
cut -f2,4,5 T70C_data.txt > temp1
trap closer EXIT

closer() {
rm tempoutput
rm tempoutputR
rm temp
rm temp1
rm tempreport
}

cat temp1 | while read line
do
   if grep -o "$line" temp
   then
	continue
   else
	echo $line >> tempoutput
   fi
done

cat temp | while read line
do
   if grep -o "$line" temp1
   then
      continue
   else
      echo $line >> tempoutputR
   fi
done


a=$( wc -l temp | cut -d" " -f1 )
b=$( wc -l temp1 | cut -d" " -f1 )
c=$( wc -l tempoutput | cut -d" " -f1 )
d=$( wc -l tempoutputR | cut -d" " -f1 )
e=$((b-a))
f=$((c-d))

if [ $e -eq $f ]
then
   echo "ALL GOOD"
   echo "ALL GOOD" >> tempreport
else 
   echo "PROBLEM"
   echo "PROBLEM" >> tempreport
fi

echo -n "Substitutions gained: " >> tempreport
echo $c >> tempreport
echo -n "Substitutions lost: " >> tempreport
echo $d >> tempreport


cp tempoutput outputBC.txt
cp tempoutputR outputBCR.txt
cp tempreport reportBC.txt
