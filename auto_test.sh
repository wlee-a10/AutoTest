#!/bin/bash

version="3.0"

srv_ip=$1
srv_port=$2

all=($@)

nc_opt="-w1"

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

dir="$srv_ip":"$srv_port"

ls $dir > /dev/null || mkdir $dir

echo "++++++++++++++++++++"
echo "+ AutoTest ver.$version +"
echo -e "++++++++++++++++++++\n"
echo "Start testing"
echo "============================================================"
for tc in ${test_case[@]}
do
    source $tc

    result_file="$dir/result_$tc"
    rm -f $result_file

    echo -e "\e[36m$tc\e[0m:"
    echo "Failed Case(s)"
    for idx in `seq 0 $((${#request[@]} - 1))`
    do
        echo -n "Case $idx: "  >> $result_file
	    response="`echo -ne "${request[$idx]}" | nc $nc_opt $srv_ip $srv_port`"
        valid=(${valid_pattern[$idx]})

        passed=0

        for i in `seq 0 $((${#valid[@]} - 1))`
        do
            echo -ne "$response" | grep "${pattern[${valid[$i]}]}" > /dev/null
            if [ $? -eq 0 ]
            then
                passed=1
                echo -e "Passed" >> $result_file && break
            fi
        done

        if [ $passed -ne 1 ]
        then
            echo -e "Failed" >> $result_file && echo -e "\e[31mCase $idx\e[0m" 
        fi

	    echo "Request:" >> $result_file
	    echo -ne "${request[$idx]}" | sed -e "s/\t/(HTAB)/g" -e "s/^/\t|/"  >> $result_file
	    echo "Response:" >> $result_file
	    echo -ne "${request[$idx]}" | nc $nc_opt $srv_ip $srv_port | sed -e "s/\t/(HTAB)/g" -e "s/^/\t|/"  >> $result_file
	    echo -ne "\nSignature: ${signature[$idx]}"  >> $result_file
        echo -e "\n============================================================"  >> $result_file
    done
    echo -e "[Summary] Total: $(($idx+1)), \e[32mPassed\e[0m: `cat $result_file | grep Passed | wc -l`, \e[31mFailed\e[0m: `cat $result_file | grep Failed | wc -l`"
    echo "============================================================"
done

echo "Test finished"
