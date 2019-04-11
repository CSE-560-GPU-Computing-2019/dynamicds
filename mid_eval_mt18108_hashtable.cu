
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#define MAX_VAL 32
#define MIN_VAL 0
typedef struct Slab Slab;
typedef struct SlabList SlabList;

//Slab is a linkedlist nodes having key value pair
struct Slab {
	Slab **next;
  	int val;
  	int key;
};
//List of ll nodes
struct SlabList {
	Slab *head;
};

SlabList *createSlablist(void);
__device__ void insertSlablist(SlabList *slablist, int ele);
//Method to search for the element befroe insertion
__device__ Slab *node_search(SlabList *slablist, int ele, int search_key);
//Method to create a new node
__device__ Slab *node_create(int val, int key);
//Method to create head node
__global__ void create_head(SlabList *slablist);

__global__ void create_head(SlabList *slablist){
	//Call headnode creation with MAX permitted values
	slablist->head = node_create(MIN_VAL, MAX_VAL);
	memset(slablist->head->next, 0, MAX_VAL * sizeof(Slab *));
}

SlabList *createSlablist(void){
	SlabList *slablist;
	cudaMalloc(&slablist, sizeof(SlabList));
	//Invoke a kernel with single thread to create a head node
	create_head<<<1, 1>>>(slablist);
	cudaDeviceSynchronize();
	return slablist;
}
//We need to have two reads for synchronize
__device__ void insertSlablist(SlabList *slablist, int ele){
	Slab *new_node, *dest, *read1, *read2;
  	int i, key=1; 
 	while (key < MAX_VAL)
    		key++;// Randomly assign keys
	new_node = node_create(ele, key);
  	for (i = 0; i < key; i++) {
    		do {
      			dest = node_search(slablist, ele, i); // want to insert right after this node
      			read1 = dest->next[i];
      			new_node->next[i] = read1;
	//Ref: From stackoverflow for atomicCAS
      			read2= (Slab *)atomicCAS((unsigned long long int *)&(dest->next[i]),
        *(unsigned long long int *)&read1,
        *(unsigned long long int *)&new_node);
		} while (read1 != read2);
  	}
}
__device__ Slab *node_create(int val, int key){
	Slab *node= (Slab *)malloc(sizeof(Slab));
	node->val = val;
	node->key = key;
	node->next = (Slab **)malloc(key * sizeof(Slab *));
  	return node;
}
//Search for the element before the insertion
__device__ Slab *node_search(SlabList *slablist, int ele, int search_key){
	Slab *cur = slablist->head;
	Slab *next_node;
	int key, flag=0;
	for (key = MAX_VAL - 1;key >= search_key; key--) {
		next_node= cur->next[key];
		while (next_node!= NULL && next_node->val < ele) {
			if(!flag && blockIdx.x==0 && gridDim.x==32 && threadIdx.x==31){
		//		printf("Inserting Elements!!"); 
			printf("ele:%d\n",cur->next[key]->val);	
			}
		cur = next_node;
      		next_node= cur->next[key];
    		}
		flag=1;
  	}
	//if(blockIdx.x==0 && gridDim.x==32 && threadIdx.x==31)
 	printf("_______________");
  	return cur;
}

__global__ void insertKernel(SlabList *slablist, int *a, int N){
	int thId = threadIdx.x + blockIdx.x * blockDim.x;
	while (thId < N) {
    		insertSlablist(slablist, a[thId]);
    		thId += blockDim.x * gridDim.x;
  	}
}

int main(void){
	int N = 32;
  	int *array = (int *)malloc(N * sizeof(int));
  	int *device_array;
  	int i;
  	SlabList *slablist;
  	cudaDeviceSetLimit(cudaLimitMallocHeapSize, 128*1024*1024);
  	size_t limit;
  	cudaDeviceGetLimit(&limit, cudaLimitMallocHeapSize);
  	cudaMalloc(&device_array, N * sizeof(int));
  	for (i = 0; i < N; i++)
    		array[i] = i;
  	printf("done initializing\n");
  	slablist = createSlablist();
	const clock_t begin_time = clock();
  	cudaMemcpy(device_array, array, N * sizeof(int), cudaMemcpyHostToDevice);
 	insertKernel<<<32, 32>>>(slablist, device_array, N);
  	cudaDeviceSynchronize();
	float runTime = (float)( clock() - begin_time ) /  CLOCKS_PER_SEC;
        printf("Time for matching keywords: %fs\n\n", runTime);
  	printf("done inserting.\n");
	return 0;
}
