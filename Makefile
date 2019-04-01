runHashTable:
	nvcc -arch sm_60 mt18108_hashtable.cu -o hashtable
clean:
	rm -f hashtable
