#! /bin/sh

if [ -e mergeSmall_k ]
then 
	make clean
fi
make question1

if [ -d ../res/ ]
then 
	echo ""
else
	mkdir ../res/
fi


if [ -e ../res/mergeSmall_k_thread.txt]
then 
	rm ../res/mergeSmall_k_thread.txt
fi

if [ -x mergeSmall_k ]
then 
	./mergeSmall_k --threads 4 2>../res/mergeSmall_k_thread.txt
	for i in `seq 14 10 1024`
	do
		./mergeSmall_k --threads $i 2>>../res/mergeSmall_k_thread.txt
	done
	echo "\n*** well done mergeSmall_k *** :)\n"

fi

if [ -e ../res/mergeSmall_k_shared_thread.txt]
then 
	rm ../res/mergeSmall_k_shared_thread.txt
fi

if [ -x mergeSmall_k_shared ]
then 
	./mergeSmall_k_shared --threads 4 2>../res/mergeSmall_k_shared_thread.txt
	for i in `seq 14 10 1024`
	do
		./mergeSmall_k_shared --threads $i 2>>../res/mergeSmall_k_shared_thread.txt
	done
	echo "\n*** well done mergeSmall_k_shared *** :)\n"

fi

