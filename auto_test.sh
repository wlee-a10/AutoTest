#!/bin/bash

version="1.0"

srv_ip=$1
srv_port=$2

all=($@)

if [ $# -gt 2 ]
then
    for idx in `seq 2 $(($#-1))`
    do
	test_case+=(${all[$idx]})
    done
    echo ${test_case[@]}
else
    echo "Please give test case file(s)."
    exit 1
fi

echo "++++++++++++++++++++"
echo "+ AutoTest ver.$version +"
echo -e "++++++++++++++++++++\n"
echo "Start testing"
echo "============================================================"
for tc in ${test_case[@]}
do
    source $tc

    rm -f result_$tc
    
    echo -e "\e[36m$tc\e[0m:"
    echo "Failed Case(s)"
    for idx in `seq 0 $((${#request[@]} - 1))`
    do
        echo -n "Case $idx: "  >> result_$tc
	echo -ne "${request[$idx]}" | nc -N $srv_ip $srv_port | grep "${signature[$idx]}" > /dev/null && echo -e "Passed" >> result_$tc || (echo -e "Failed" >> result_$tc && echo -e "\e[31mCase $idx\e[0m" )
 
	echo "Request:" >> result_$tc
	echo -ne "${request[$idx]}" | sed -e "s/\t/(HTAB)/g" -e "s/^/\t|/"  >> result_$tc
	echo "Response:" >> result_$tc
	echo -ne "${request[$idx]}" | nc -N $srv_ip $srv_port | sed -e "s/\t/(HTAB)/g" -e "s/^/\t|/"  >> result_$tc
	echo -ne "\nSignature: ${signature[$idx]}"  >> result_$tc
        echo -e "\n============================================================"  >> result_$tc
    done
    echo -e "[Summary] Total: $(($idx+1)), \e[32mPassed\e[0m: `cat result_$tc | grep Passed | wc -l`, \e[31mFailed\e[0m: `cat result_$tc | grep Failed | wc -l`"
    echo "============================================================"
done

echo "Test finished"
