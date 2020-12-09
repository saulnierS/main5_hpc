#! /bin/sh

if [ -e sort ]
then 
	make clean
fi
make question3

if [ -d ../res/ ]
then 
	echo ""
else
	mkdir ../res/
fi



if [ -e ../res/sort.txt ]
then 
	rm ../res/sort.txt
fi

if [ -x sort ]
then 
	./sort --s 10 2>../res/sort.txt
	for i in `seq 10 10 100000`
	do
		./sort --s $i 2>>../res/sort.txt
	done
	echo "\n*** well done sort *** :)\n"

fi

if [ -e ../res/sort_stream.txt ]
then 
	rm ../res/sort_stream.txt
fi

if [ -x sort_stream ]
then 
	./sort_stream --s 10 2>../res/sort_stream.txt
	for i in `seq 10 10 100000`
	do
		./sort_stream --s $i 2>>../res/sort_stream.txt
	done
	echo "\n*** well done sort_stream *** :)\n"

fi

