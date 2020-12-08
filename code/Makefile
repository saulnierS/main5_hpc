all: question1 question2 question3 question5 seq

question1: mergeSmall_k.cu mergeSmall_k_shared.cu
	nvcc -o  mergeSmall_k mergeSmall_k.cu
	nvcc -o  mergeSmall_k_shared mergeSmall_k_shared.cu

question2: mergeBig_k.cu
	nvcc -o  mergeBig_k mergeBig_k.cu

question3: sort.cu
	nvcc -o  sort sort.cu
	nvcc -o  sort_stream sort_stream.cu

question5: mergeSmallBatches_Only.cu
	nvcc -o  mergeSmallBatches_Only mergeSmallBatches_Only.cu
	nvcc -o  mergeBatches mergeBatches.cu

seq: mergeSmallBatches_Only.cu
	nvcc -o  code_seq code_seq.cu

clean:
	rm -f mergeSmall_k mergeSmall_k_shared mergeBig_k sort sort_stream mergeSmallBatches_Only code_seq mergeBatches

