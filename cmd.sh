#! /bin/sh
gcc -o fonctionsCPU.o -c fonctionsCPU.c

nvcc -o  question1_mergeSmall_k question1_mergeSmall_k.cu
./question1_mergeSmall_k

nvcc -o  question1_mergeSmall_k_shared question1_mergeSmall_k_shared.cu
./question1_mergeSmall_k_shared

nvcc -o  question2_mergeBig_k question2_mergeBig_k.cu
./question2_mergeBig_k

nvcc -o  question3_sort question3_sort.cu
./question3_sort

nvcc -o  question4_mergeBig_k question4_mergeBig_k.cu
./question4_mergeBig_k

nvcc -o  question4_mergeBig_k_stream question4_mergeBig_k_stream.cu
./question4_mergeBig_k_stream

nvcc -o  question5_mergeSmallBatch_shared question5_mergeSmallBatch_shared.cu
./question5_mergeSmallBatch_shared

nvcc -o  question5_treeMergePerBlock_simpleExemple question5_treeMergePerBlock_simpleExemple.cu
./question5_treeMergePerBlock_simpleExemple

nvcc -o  question5_smallBatchesOnly question5_smallBatchesOnly.cu
./question5_smallBatchesOnly