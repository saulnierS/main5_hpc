#! /bin/sh

if [ -e mergeBatches ]
then 
	make clean
fi
make question5

if [ -d ../res/ ]
then 
	echo ""
else
	mkdir ../res/
fi



if [ -e ../res/mergeBatches.txt ]
then 
	rm ../res/mergeBatches.txt
fi

if [ -x mergeBatches ]
then 
	./mergeBatches --s 1024 2>../res/mergeBatches.txt
	for i in `seq 2048 2048 10000000`
	do
		./mergeBatches --s $i 2>>../res/mergeBatches.txt
	done
	echo "\n*** well done mergeBatches *** :)\n"

fi


