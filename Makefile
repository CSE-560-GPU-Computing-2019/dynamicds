rundictionary:
	nvcc -arch sm_60 -o dict Mid_Eval_MT18145_dictionary.cu
cleand:
	rm -f dict
runHAT:
	nvcc -arch sm_60 mid_eval_MT18128.cu -o HAT
cleanHAT:
	rm -f HAT
runHashTable:
	nvcc -arch sm_60 mid_eval_mt18108_hashtable.cu -o hashtable
clean:
	rm -f hashtable
