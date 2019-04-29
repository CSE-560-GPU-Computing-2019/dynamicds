//Sujay Raj - MT18108
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <time.h>

typedef struct SlabList SlabList;

#define SLAB_SIZE 33
struct SlabList {
	int val[SLAB_SIZE - 2];
	int key[SLAB_SIZE - 2];
	struct SlabList * next;
};
__device__ volatile int sem = 0;

__device__ void acquire_semaphore(volatile int * lock) {
    while (atomicCAS((int * ) lock, 0, 1) != 0);
}

__device__ void release_semaphore(volatile int * lock) {
	* lock = 0;
	__threadfence();
}
struct SlabList * createSlablist(struct SlabList * head_ref, int * new_key, int * new_val, int size, int * del_array, int del_size) {
    head_ref = NULL;
    for (int i = 0; i < size / SLAB_SIZE; i++) {
        struct SlabList * new_node = (struct SlabList * ) malloc(sizeof(struct SlabList));
        for (int j = 0; j < SLAB_SIZE; j++) {
            new_node->key[j] = new_key[i * SLAB_SIZE + j];
            new_node->val[j] = new_val[i * SLAB_SIZE + j];
            //printf("key--->%d\tVal---->%d\n",new_node->key[j],new_node->val[j]);
        }
        new_node->next = head_ref;
        head_ref = new_node;
    }

    //Deletion
    //First search for the key and then fill the key and value with #
    while (head_ref != NULL) {
        for (int i = 0; i < SLAB_SIZE; i++) {
            for (int k = 0; k < del_size; k++) {
                if (head_ref->key[i] == del_array[k] && head_ref->key[i] != -999999 && head_ref->key[i] != 0) {
                    //					printf("Found!!! Key: %d\tValue:%d\n",head_ref->key[i],head_ref->val[i]); 		
                    head_ref->key[i] = -999999;
                    head_ref->val[i] = -999999;
                }
            }
        }
        head_ref = head_ref->next;
    }

    return head_ref;
}
void printList(struct SlabList * node) {
    while (node != NULL) {
        for (int i = 0; i < SLAB_SIZE; i++) {
            printf("Key: %d\tValue:%d\n", node->key[i], node->val[i]);
        }
        node = node->next;
    }
}
void printList1(struct SlabList * node, int size) {
    for (int j = 0; j < size; j++) {
        for (int i = 0; i < SLAB_SIZE; i++) {
            printf("Key: %d\tValue:%d\n", node[j].key[i], node[j].val[i]);
        }
    }
}
__global__ void kernelOps(struct SlabList * head_ref, int * new_key, int * new_val, int size, int * del_key, int del_size) {
    int id = blockIdx.x * blockDim.x + threadIdx.x;
    if (id < size) {
        head_ref = NULL;
        struct SlabList * new_node;
        if (id % SLAB_SIZE == 0)//Only one thread per group initialises a SlabList
            new_node = (struct SlabList * ) malloc(sizeof(struct SlabList));
        __syncthreads();
        if ((((id + 1) % SLAB_SIZE)) != 0) { //31,63,95 etc.,
            new_node[id / SLAB_SIZE].key[id] = new_key[id]; //Insert values to new_node[0],new_node[1] etc.,
            new_node[id / SLAB_SIZE].val[id] = new_val[id];
            //			printf(":key--->%d\tVal---->%d\n",new_node[id/SLAB_SIZE].key[id],new_node[id/SLAB_SIZE].val[id]);
        }
        if (id % SLAB_SIZE == SLAB_SIZE-1){ //All last nodes in the warp has to update the next counter
		 new_node[id / SLAB_SIZE].next = & (new_node[id / SLAB_SIZE + 1]);
        }
	__syncthreads();
        new_node->next = head_ref;
        //if (threadIdx.x == 0)
        //acquire_semaphore(&sem);	
        //__syncthreads();
        //memcpy(SL,new_node, size * sizeof(struct SlabList));
        
	//One node to search for element
//        if ((id % SLAB_SIZE) == 0) { //First thread of each warp searches for key in its Slab
	if(id<del_size){ 
      //    for (int k = 0; k < del_size; k++) {
            	for (int j = 0; j < SLAB_SIZE - 1; j++) {
           	    if(__shfl(new_node[id/SLAB_SIZE].key[j],(id+1)%SLAB_SIZE,32)==del_key[id] && __shfl(new_node[id/SLAB_SIZE].key[j],(id+1)%SLAB_SIZE,32) == -999999) {
                    //if (new_node[id / SLAB_SIZE].key[j] == del_key[k] && new_node[id / SLAB_SIZE].key[j] == -999999) {
                        //printf("found!!!\n");
			//Delete the node
                        new_node[id / SLAB_SIZE].key[j] = -999999;
                        new_node[id / SLAB_SIZE].val[j] = -999999;
                    }
                }
            //}
        }
        //__syncthreads();
        //if (threadIdx.x == 0)
        //release_semaphore(&sem);
        //__syncthreads();
    }
}

int main(int argc, char** argv) {
    int N = 1000000, M = 1000; //N: Insert Size; M: Del Size
    if(argc==2)
	N=atoi(argv[1]);
    if(argc==3){
	N= atoi(argv[1]);
	M= atoi(argv[2]);
}
/*if(M>N){
	printf("Not possible to delete!!!(M>N)\n");
	exit(0);
}*/
printf("----------------\nN: %d\tM:%d\n",N,M);
    int * val_array = (int * ) malloc(N * sizeof(int));
    int * key_array = (int * ) malloc(N * sizeof(int));
    int * del_key_array = (int * ) malloc(M * sizeof(int));
    int * d_val_array = NULL;
    int * d_key_array = NULL;
    int * d_del_key_array = NULL;
    float kTime=0, kplusMTime=0;
    struct SlabList * start = (struct SlabList * ) malloc(sizeof(struct SlabList));
    struct SlabList * d_start = NULL;
    cudaMalloc( & d_start, N * sizeof(struct SlabList));
    cudaMalloc( & d_val_array, N * sizeof(int));
    cudaMalloc( & d_key_array, N * sizeof(int));
    for (int i = 0; i < N; i++) {
        val_array[i] = i;
        key_array[i] = i + 10;
    }
    //Fill random with del_key array
    srand(time(0));
    for (int i = 0; i < M; i++) {
        int r = rand() % N;
        del_key_array[i] = r;
    }
    const clock_t seq_begin_time = clock();
    //Batch insertion
    start = NULL;
    struct SlabList * head = createSlablist(start, val_array, key_array, N, del_key_array, M);
    //	printList(head);
    float seq_runTime = (float)(clock() - seq_begin_time) / CLOCKS_PER_SEC;
    printf("Seq Time for matching keywords: %fs\n\n", seq_runTime);
    const clock_t par_begin_time1 = clock();
    //printf("done initializing\n");
    cudaMemcpy(d_val_array, val_array, N * sizeof(int), cudaMemcpyHostToDevice);
    cudaDeviceSetLimit(cudaLimitMallocHeapSize, sizeof(struct SlabList) * N);
    cudaMemcpy(d_key_array, key_array, N * sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_del_key_array, del_key_array, M * sizeof(int), cudaMemcpyHostToDevice);
    const clock_t par_begin_time2 = clock();
    int it=100;
    for(int i=0;i<it;i++){
    kernelOps << < 512, 512 >>> (d_start, d_val_array, d_key_array, N, d_del_key_array, M);
    cudaDeviceSynchronize();
    float par_runTime2 = (float)(clock() - par_begin_time2) / CLOCKS_PER_SEC;
    struct SlabList * head1 = (struct SlabList * ) malloc(N * sizeof(struct SlabList));
    //cudaMemcpy(head1, d_SL, N * sizeof(struct SlabList), cudaMemcpyDeviceToHost);
    float par_runTime1 = (float)(clock() - par_begin_time1) / CLOCKS_PER_SEC;
    kTime+=par_runTime2;
    kplusMTime+=par_runTime1;
  //  cudaFree(d_val_array);
    //cudaFree(d_key_array);
   // cudaFree(d_del_key_array); 
}   
    printf("Kernel timing: %fs\n\n", kTime/it);
    printf("Kernel plus memcopy timing: %fs\n\n", kplusMTime/it);
    printf("Speedup Over sequential execution is %f\n",seq_runTime*it/kTime);
//       printf("____________________________GPU Insertion!!!_______________________________________\n");
    //        printList1(head1,N/SLAB_SIZE);
    return 0;
}
