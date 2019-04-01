rundictionary:
	nvcc -arch sm_60 -o dict MT18145_dictionary.cu
cleand:
	rm -f dict
runHashTable:
	nvcc -arch sm_60 mt18108_hashtable.cu -o hashtable
clean:
	rm -f hashtable
