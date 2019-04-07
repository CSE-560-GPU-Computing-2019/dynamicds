//Sujay Raj - MT18108
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
typedef struct SlabList SlabList;

#define SLAB_SIZE 4
struct SlabList{
	int val[SLAB_SIZE];
	int key[SLAB_SIZE];
	struct SlabList* next;
};

struct SlabList* createSlablist(struct SlabList* head_ref, int* new_key, int* new_val, int size) { 
	head_ref=NULL;
	for(int i=0;i<size/4;i++){
		struct SlabList* new_node = (struct SlabList*) malloc(sizeof(struct SlabList)); 
		for(int j=0;j<SLAB_SIZE;j++){
    			new_node->key[j] = new_key[i*SLAB_SIZE+j]; 
			new_node->val[j]= new_val[i*SLAB_SIZE+j];
	//		printf("key--->%d\tVal---->%d\n",new_node->key[j],new_node->val[j]);
		} 
    		new_node->next = head_ref; 
     		head_ref    = new_node;
	}
	return head_ref;
} 
void printList(struct SlabList *node) { 
    	while (node != NULL) { 
		for(int i=0;i<SLAB_SIZE;i++){
        		printf("Key: %d\tValue:%d\n",node->key[i],node->val[i]); 		
		}
  	     	node = node->next; 
	} 
} 
void printList1(struct SlabList *node, int size) {
	for(int j=0;j<size;j++) {
		for(int i=0;i<SLAB_SIZE;i++){
        		printf("Key: %d\tValue:%d\n",node[j].key[i],node[j].val[i]); 		
		}
	}
} 
__global__ void insertKernel(struct SlabList* head_ref, int* new_key, int* new_val, int size,struct SlabList* SL, struct SlabList* temp){
//__global__ void insertKernel(struct SlabList* SL){
	printf("INSIDEKERNEL!!!!\n");
	int id = blockIdx.x*blockDim.x + threadIdx.x;
	if(id==0){
//SL->key[0]=1;
//	SL->val[0]=2;
//SL->next=NULL;
	head_ref=NULL;
	for(int i=0;i<size/SLAB_SIZE;i++){
		//temp=NULL;
		struct SlabList* new_node = (struct SlabList*) malloc(sizeof(struct SlabList)); 
		for(int j=0;j<SLAB_SIZE;j++){
    			new_node->key[j] = new_key[i*SLAB_SIZE+j]; 
			new_node->val[j]= new_val[i*SLAB_SIZE+j];
    			//SL->key[j] = new_key[i*SLAB_SIZE+j]; 
			//SL->val[j]= new_val[i*SLAB_SIZE+j];
			printf("key--->%d\tVal---->%d\n",new_node->key[j],new_node->val[j]);
		}
		new_node->next = head_ref; 
    		//SL = SL->next;
		//SL->next = head_ref; 
	memcpy(SL,new_node, size * sizeof(struct SlabList));
     		head_ref    = new_node;
	//	memcpy(temp,new_node, size * sizeof(struct SlabList));
		SL++;
	}
	//SL->next =NULL;
		//SL =SL->next;	
	//return head_ref;
    	/*while (head_ref != NULL) { 
		for(int i=0;i<SLAB_SIZE;i++){
        		printf("Key: %d\tValue:%d\n",head_ref->key[i],head_ref->val[i]); 		
		}
  	     	head_ref = head_ref->next; 
	}*/
//	SL->next =NULL;
	printf("here!!!\n");
		/*while (SL != NULL) { 
		for(int i=0;i<SLAB_SIZE;i++){
        		printf("Key: %d\tValue:%d\n",SL->key[i],SL->val[i]); 		
		}
  	     	SL = SL->next; 
		}*/
}
} 

int main(void){
	int N = 12;
  	int *val_array = (int *)malloc(N * sizeof(int));
  	int *key_array = (int *)malloc(N * sizeof(int));
  	int *d_val_array = NULL;
  	int *d_key_array = NULL;
  	struct SlabList *start=(struct SlabList*)malloc(sizeof(struct SlabList));
  	struct SlabList *d_start=NULL;
	//HashTable = (struct Slab*)malloc(10*sizeof(struct Slab)); 
  	cudaMalloc(&d_start, N * sizeof(struct SlabList));
  	cudaMalloc(&d_val_array, N * sizeof(int));
  	cudaMalloc(&d_key_array, N * sizeof(int));
	for (int i = 0; i < N; i++){
		val_array[i] =i;
		key_array[i] =i+10;   
	}
	const clock_t begin_time = clock();
	//Batch insertion
	start = NULL;
	struct SlabList* head = createSlablist(start, val_array,key_array,N);  	
		//printf("%d\n",head->val[0]);
	float runTime = (float)( clock() - begin_time ) /  CLOCKS_PER_SEC;
        //printf("done initializing\n");
        cudaMemcpy(d_val_array, val_array, N * sizeof(int), cudaMemcpyHostToDevice);
        cudaDeviceSetLimit(cudaLimitMallocHeapSize, sizeof(struct SlabList)*N);
        cudaMemcpy(d_key_array, key_array, N * sizeof(int), cudaMemcpyHostToDevice);
	struct SlabList* d_SL = NULL;
  	cudaMalloc(&d_SL, N * sizeof(struct SlabList));
	struct SlabList* d_temp = NULL;
  	cudaMalloc(&d_temp, N * sizeof(struct SlabList));	
        const clock_t begin_time1 = clock();
        insertKernel<<<1, 1>>>(d_start,d_val_array,d_key_array,N,d_SL,d_temp);
//        insertKernel<<<1, 1>>>(d_SL);
//       cudaDeviceSynchronize();
        struct SlabList* head1 = (struct SlabList*)malloc(N*sizeof(struct SlabList));
        cudaMemcpy(head1, d_SL, N * sizeof(struct SlabList), cudaMemcpyDeviceToHost);
	//printf("%d\n",head1->key[0]);
        float runTime1 = (float)( clock() - begin_time1 ) /  CLOCKS_PER_SEC;
        printf("Time for matching keywords: %fs\n\n", runTime1);
        printf("____________________________GPU Insertion!!!_______________________________________\n");
        printList1(head1,N/SLAB_SIZE);
	printf("Insert number of elements you want to insert\n");
	int num;
	scanf("%d",&num);
	printf("Enter key and value pair \n");
	for(int i=0;i<num;i++)
		scanf("%d%d",&key_array[i],&val_array[i]);
	printf("Entered key values are\n");
	for(int i=0;i<num;i++)
		printf("Key:%d\tVal:%d\n",key_array[i],val_array[i]);
return 0;
}
