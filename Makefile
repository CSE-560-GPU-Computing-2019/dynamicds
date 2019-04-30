rundictionary:
	nvcc -arch sm_60 -o endeval_dict End_Eval_MT18145_Dictionary.cu
cleand:
	rm -f endeval_dict
runHAT:
	nvcc -arch sm_60 final_eval_MT18128_HAT.cu -o HAT
cleanHAT:
	rm -f HAT
runHashTable:
	nvcc -arch sm_60 mid_eval_mt18108_hashtable.cu -o hashtable
clean:
	rm -f hashtable
