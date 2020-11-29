question1 = question1_mergeSmall_k question1_mergeSmall_k_shared
question2 = question2_mergeBig_k
question3 = question3_sort
question4 = question4_mergeBig_k question4_mergeBig_k_stream 
question5 = question5_mergeSmallBatch_shared question5_treeMergePerBlock_simpleExemple question5_smallBatchesOnly

OBJECT = fonctionsCPU.o
all: $(question1) $(question2) $(question3) $(question4) $(question5)
$(OBJECT): fonctionsCPU.c
	gcc -o $(OBJECT) -c fonctionsCPU.c
$(question1): $(OBJECT) question1_mergeSmall_k.cu question1_mergeSmall_k_shared.cu
	nvcc -o  question1_mergeSmall_k question1_mergeSmall_k.cu
	nvcc -o  question1_mergeSmall_k_shared question1_mergeSmall_k_shared.cu

$(question2): $(OBJECT) question2_mergeBig_k.cu
	nvcc -o  question2_mergeBig_k question2_mergeBig_k.cu

$(question3): $(OBJECT) question3_sort.cu
	nvcc -o  question3_sort question3_sort.cu

$(question4): $(OBJECT) question4_mergeBig_k.cu question4_mergeBig_k_stream.cu
	nvcc -o  question4_mergeBig_k question4_mergeBig_k.cu
	nvcc -o  question4_mergeBig_k_stream question4_mergeBig_k_stream.cu

$(question5): $(OBJECT) question5_mergeSmallBatch_shared.cu question5_treeMergePerBlock_simpleExemple.cu question5_smallBatchesOnly.cu
	nvcc -o  question5_mergeSmallBatch_shared question5_mergeSmallBatch_shared.cu
	nvcc -o  question5_treeMergePerBlock_simpleExemple question5_treeMergePerBlock_simpleExemple.cu
	nvcc -o  question5_smallBatchesOnly question5_smallBatchesOnly.cu

clean:
	rm -f $(OBJECT) $(question1) $(question2) $(question3) $(question4) $(question5)

