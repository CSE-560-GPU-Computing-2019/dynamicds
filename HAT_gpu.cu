#include <stdio.h>
#include <math.h>
#include <stdlib.h>

#define size 100


void print_tree(int ** HAT, int n){
	for (int i = 0; i < n; i++){
		if (HAT[i] != NULL){
			printf("\n");
			for (int j =0; j<n ; j++){
				printf("%d ",HAT[i][j]);
			}
		}
	}
}


/*
void insert_tree (int ** HAT, int n, int * input, int inputsize) {
	for (int i = 0; i < inputsize; i++){
		int j = i/n;
		if (HAT[j]==NULL){
			HAT[j] = malloc(sizeof(int) * n);
		}
		int k = i % n;
		HAT[j][k] = input[i];
	}
}
*/

__global__ void insert_gpu (int ** HAT, int *input, int inputsize, int n) {
	printf("Inserted");
	int i = blockIdx.x * blockDim.x + threadIdx.x ;
	
	if(i<inputsize){
		printf("Inserted");
		int j = i/n;
		int k = i % n;
		HAT[j][k] = input[i];
	}
}


int main (int argc, const char **argv) {
	printf("1");
	int ** HAT;
	printf("2");
	int n = (int)sqrt(size);
	printf("sdfsdv");
	HAT = (int **)malloc(sizeof(int *) * n);
	for (int i =0; i<n; i++){
		HAT[i] = (int *)malloc(sizeof(int) * n);
	}
	//HAT[0] = malloc(sizeof(int) * n);
	//HAT[0][1] = 1;
	//printf("3");
	//printf("%d",HAT[0][1]);
	//printf("%d",HAT[0][2]);
	//printf("%d",HAT[0][3]);
	//printf("%d",HAT[1][1]);
	
	int input[100];
	int inputsize = 100;
	for (int i =0; i<inputsize; i++) {
		input[i] = i;
	}
	printf("3");
	//GPU code starts here
	int * input_d;
	int ** HAT_d;
	cudaMalloc ((void **)&input_d , sizeof(int) * inputsize);
	cudaMalloc ((void **)HAT_d , sizeof(int *) * n);
	
	for (int i =0; i<n; i++){
		cudaMalloc((void**)&HAT_d[i],sizeof(int) * n);
	}
	
	cudaMemcpy (input_d, input, sizeof(int) * inputsize , cudaMemcpyHostToDevice);
	
	int no_of_blocks;
	
	if (inputsize % 1024 == 0)
		no_of_blocks = inputsize/1024;
	else
		no_of_blocks = (inputsize/1024) + 1;
	printf("4");
	insert_gpu<<<no_of_blocks,1024 >>>(HAT_d,input_d, inputsize, n);
	printf("5");
	//insert_tree(HAT, n , input, inputsize);
	
	
	cudaMemcpy (HAT, HAT_d, sizeof(int*) * n , cudaMemcpyDeviceToHost);
	print_tree(HAT,n);
	cudaFree(HAT_d);
	cudaFree(input_d);
	return 0;
}
