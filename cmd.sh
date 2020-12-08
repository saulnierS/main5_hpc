#! /bin/sh
nvcc -o merge_seq code/code_seq.cu
./merge_seq

nvcc -o mergeSmall_k code/mergeSmall_k.cu
./mergeSmall_k

nvcc -o mergeSmall_k_shared code/mergeSmall_k_shared.cu
./mergeSmall_k

nvcc -o  mergeBig_k code/mergeBig_k.cu
./mergeBig_k

nvcc -o sort code/sort.cu
./sort

nvcc -o sort_stream code/sort_stream.cu
./sort_stream

nvcc -o  mergeSmallBatches_Only code/mergeSmallBatches_Only.cu
./mergeSmallBatches_Only

nvcc -o  mergeBatches code/mergeBatches.cu
./mergeBatches