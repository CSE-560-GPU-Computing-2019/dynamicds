//Krishna Bagaria MT18128
//HAT --- Hashed Array Tree

#include <stdio.h>
#include <math.h>
#include <stdlib.h>

#define size 10000 //initial size of HAT

int count_ints (const char* file_name)
{
	FILE* file = fopen (file_name, "r");
	int i = 0;
	int inputsize = 0;
	fscanf (file, "%d", &i);    
	while (!feof (file))
	{  
		//printf ("%d ", i);
		fscanf (file, "%d", &i);
		inputsize++;
	}
	//printf("\n%d",inputsize);
	fclose (file);
	return inputsize;
}

void read_ints (const char* file_name, int * input)
{
	FILE* file = fopen (file_name, "r");
	int i = 0;
	int inputsize = 0;
	fscanf (file, "%d", &i);    
	while (!feof (file))
	{  
		input[inputsize] = i;
		//printf ("%d ", i);
		inputsize++;
		fscanf (file, "%d", &i);
	}
	//printf("%d",inputsize);
	fclose (file);
}

// method to print the HAT
void print_tree(int ** HAT, int n){
	for (int i = 0; i < n; i++){
		if (HAT[i] != NULL){
			printf("\nBucket %d : ",i);
			for (int j =0; j<n ; j++){
				printf("%d ",HAT[i][j]);
			}
		}
		else {
			printf("\nBucket %d is empty.",i);
		}
	}
}

//CPU method to insert elements in HAT from 'input' array passed as argument
void insert_tree (int ** HAT, int n, int * input, int inputsize) {
	for (int i = 0; i < inputsize; i++){
		int j = i/n;
		if (HAT[j]== NULL){
			HAT[j] = (int *)malloc(sizeof(int) * n);
		}
		int k = i % n;
		HAT[j][k] = input[i];
	}
}

void delete_tree (int ** HAT, int n, int inputsize, int * keys, int keysize) {
	
	for (int l =0; l<keysize; l++){
		for (int i = 0; i < inputsize; i++){
			int j = i/n;
			int k = i % n;
			if (HAT[j][k] == keys[l]) {
				HAT[j][k] = -999999;
			};
		}
	}
	
}

__global__ void delete_gpu (int ** HAT_d, int n, int inputsize, int key) {
	int i = blockIdx.x * blockDim.x + threadIdx.x ;
	if (i< inputsize) {
		int j = i/n;
		int k = i % n;
		if (HAT_d[j][k] == key) {
			HAT_d[j][k] = -999999;	
		};
	}
}

void search_tree (int ** HAT, int n, int inputsize, int key) {
	for (int i = 0; i < inputsize; i++){
		int j = i/n;
		int k = i % n;
		if (HAT[j][k] == key) {
			printf ("\n%d found at index %d (Bucket %d, Position %d)", key,i,j,k);	
		};
	}
}

__global__ void search_gpu (int ** HAT_d, int n, int inputsize, int key) {
	int i = blockIdx.x * blockDim.x + threadIdx.x ;
	if (i < inputsize){
		int j = i/n;
		int k = i % n;
		if (HAT_d[j][k] == key) {
			printf ("\n%d found at index %d (Bucket %d, Position %d)", key,i,j,k);	
		};
	}
}

//GPU method for inserting elements in HAT
__global__ void insert_gpu (int ** HAT_d, int *input, int inputsize, int n) {
	
	int i = blockIdx.x * blockDim.x + threadIdx.x ;
	//printf("\n%d",i);
	if(i < inputsize){
	
		int j = i/n;
		int k = i % n;
		printf("\n%d",HAT_d[j][k]);
		HAT_d[j][k] = input[i];
		
	}
}


int main (int argc, const char **argv) {
	int ** HAT;
	int n = sqrt(size);   //calculate size of main array or each leaf
	HAT = (int **)malloc(sizeof(int *) * n);
	
	int inputsize = count_ints ("data/input10000.txt");
	int * input = (int *)malloc(sizeof(int) * inputsize);
	read_ints("data/input10000.txt",input);
	
	/*
	for (int i =0; i<inputsize; i++) {
		printf("%d ", input[i]);
	}
	*/
	
	/*
	printf("Enter no. of elements to be inserted: ");
	scanf("%d",&inputsize);
	
	int * input = (int *)malloc(sizeof(int) * inputsize);
	printf("Enter the elements (integers): ");
	
	for (int i =0; i<inputsize; i++) {
		scanf("%d", &input[i]);
	}
	*/
	int keysize= 100;
	int *keys = (int *)malloc(sizeof(int)*keysize);
	for (int i=0; i<keysize; i++){
		keys[i] = i;
	}
	
	//search_tree(HAT,n,inputsize,2);
	
	const clock_t begin_time = clock();  // measure CPU time for insertion
	insert_tree(HAT, n , input, inputsize);
	printf("\nOutput Tree by inserting from CPU:\n");
	print_tree(HAT,n);
	
	delete_tree(HAT, n, inputsize, keys, keysize);
	float runTime_cpu = (float)( clock() - begin_time ) / CLOCKS_PER_SEC;
	
	
	
	printf("\nOutput Tree by deleting from CPU:\n");
	print_tree(HAT,n);
	
	
	//GPU code starts here
	int * input_d;
	int ** HAT_d;
	
	cudaMalloc ((void **)&input_d , sizeof(int) * inputsize);
	cudaMalloc ((void ***)&HAT_d , sizeof(int *) * n);
	
	int **support;
	support = (int**) malloc(sizeof(int*)*n);
	cudaMemcpy(support, HAT_d, n*sizeof(int*), cudaMemcpyDeviceToHost);
	
	for (int i =0; i<n; i++){
		cudaMalloc((void**)&support[i],sizeof(int) * n);
	}
	
	cudaMemcpy (input_d, input, sizeof(int) * inputsize , cudaMemcpyHostToDevice);
	
	int grid_size = (inputsize % 1024) ? ((inputsize/1024) + 1) : (inputsize/1024);
	int block_size = 1024;
	
	const clock_t begin_time1 = clock(); 
	insert_gpu<<<grid_size,block_size>>>(HAT_d,input_d, inputsize, n);
	cudaDeviceSynchronize();
	//search_gpu<<<grid_size,block_size>>>(HAT_d,n,inputsize,2);
	
	cudaStream_t stream[keysize];
	for (int i =0;i<keysize; i++){
		cudaStreamCreate(&stream[i]);
		delete_gpu<<< grid_size,block_size,0,stream[i]>>>(HAT, n, inputsize, keys[i]);
	}
	cudaDeviceSynchronize();
	float runTime_gpu1 = (float)( clock() - begin_time1 ) /  CLOCKS_PER_SEC;
	
	cudaMemcpy (HAT, HAT_d, sizeof(int*) * n , cudaMemcpyDeviceToHost);
	float runTime_gpu2 = (float)( clock() - begin_time1 ) /  CLOCKS_PER_SEC;
	
	printf("\nOutput Tree by deleting from GPU:\n");
	print_tree(HAT,n);
	
	printf("\n\nGPU Kernel Time: %fs\n\n", runTime_gpu1);
	printf("\nGPU Kernel + Memory Transfer Time: %fs\n\n", runTime_gpu2);
	printf("\nTime for inserting(CPU): %fs\n\n", runTime_cpu);
	
	cudaFree(HAT_d);
	cudaFree(input_d);
	free(HAT);
	free(input);

	return 0;
}