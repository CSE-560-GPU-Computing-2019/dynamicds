//Krishna Bagaria MT18128

#include <stdio.h>
#include <math.h>
#include <stdlib.h>

#define size 100


void print_tree(int ** HAT, int n){
	for (int i = 0; i < n; i++){
		if (HAT[i] != NULL){
			printf("\nBucket %d : ",i);
			for (int j =0; j<n ; j++){
				printf("%d ",HAT[i][j]);
			}
		}
	}
}


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

__global__ void insert_gpu (int ** HAT_d, int *input, int inputsize, int n) {
	
	int i = blockIdx.x * blockDim.x + threadIdx.x ;
	
	if(i<inputsize){
		
		int j = i/n;
		int k = i % n;
		HAT_d[j][k] = input[i];
		
	}
}


int main (int argc, const char **argv) {
	int ** HAT;
	int n = sqrt(size);
	HAT = (int **)malloc(sizeof(int *) * n);

	int inputsize;
	printf("Enter no. of elements to be inserted: ");
	scanf("%d",&inputsize);
	
	int * input = (int *)malloc(sizeof(int) * inputsize);
	printf("Enter the elements (integers): ");
	
	for (int i =0; i<inputsize; i++) {
		scanf("%d", &input[i]);
	}
	
	const clock_t begin_time = clock();
	insert_tree(HAT, n , input, inputsize);
	float runTime = (float)( clock() - begin_time ) /  CLOCKS_PER_SEC;
	printf("Time for inserting(CPU): %fs\n\n", runTime);
	printf("\nOutput Tree by inserting from CPU:\n");
	print_tree(HAT,n);
	
	//GPU code starts here
	int * input_d;
	int ** HAT_d;
	
	cudaMalloc ((void **)&input_d , sizeof(int) * inputsize);
	cudaMalloc ((void ***)&HAT_d , sizeof(int *) * n);
	
	int **support;
	support = (int**) malloc(sizeof(int*)*n);
	cudaMemcpy(support,HAT_d,n*sizeof(int*),cudaMemcpyDeviceToHost);
	
	for (int i =0; i<n; i++){
		cudaMalloc((void**)&support[i],sizeof(int) * n);
	}
	
	cudaMemcpy (input_d, input, sizeof(int) * inputsize , cudaMemcpyHostToDevice);
	
	int grid_size = (inputsize % 1024) ? ((inputsize/1024) + 1) : (inputsize/1024);
	int block_size = 1024;
	
	const clock_t begin_time1 = clock();
	insert_gpu<<<grid_size,block_size>>>(HAT_d,input_d, inputsize, n);
	cudaDeviceSynchronize();
	runTime = (float)( clock() - begin_time ) /  CLOCKS_PER_SEC;
	printf("\n\nTime for inserting(GPU): %fs\n\n", runTime);
	
	cudaMemcpy (HAT, HAT_d, sizeof(int*) * n , cudaMemcpyDeviceToHost);
	
	printf("\nOutput Tree by inserting from GPU:\n");
	print_tree(HAT,n);
	
	cudaFree(HAT_d);
	cudaFree(input_d);
	free(HAT);
	free(input);
	
	return 0;
}
