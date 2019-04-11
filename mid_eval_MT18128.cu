//Krishna Bagaria MT18128
//HAT --- Hashed Array Tree

#include <stdio.h>
#include <math.h>
#include <stdlib.h>

#define size 1000000   //initial size of HAT

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

//GPU method for inserting elements in HAT
__global__ void insert_gpu (int ** HAT_d, int *input, int inputsize, int n) {
	
	int i = blockIdx.x * blockDim.x + threadIdx.x ;
	
	if(i < inputsize){
		
		int j = i/n;
		int k = i % n;
		HAT_d[j][k] = input[i];
		
	}
}


int main (int argc, const char **argv) {
	int ** HAT;
	int n = sqrt(size);   //calculate size of main array or each leaf
	HAT = (int **)malloc(sizeof(int *) * n);
	
	int inputsize = count_ints ("data/input10000.txt");
	int * input = (int *)malloc(sizeof(int) * inputsize);
	read_ints("input.txt",input);
	
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
	
	const clock_t begin_time = clock();  // measure CPU time for insertion
	insert_tree(HAT, n , input, inputsize);
	float runTime_cpu = (float)( clock() - begin_time ) / CLOCKS_PER_SEC;
	
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
	//cudaDeviceSynchronize();
	float runTime_gpu = (float)( clock() - begin_time1 ) /  CLOCKS_PER_SEC;
	
	
	cudaMemcpy (HAT, HAT_d, sizeof(int*) * n , cudaMemcpyDeviceToHost);
	
	printf("\nOutput Tree by inserting from GPU:\n");
	print_tree(HAT,n);
	
	printf("Time for inserting(CPU): %fs\n\n", runTime_cpu);
	printf("\n\nTime for inserting(GPU): %fs\n\n", runTime_gpu);
	
	cudaFree(HAT_d);
	cudaFree(input_d);
	free(HAT);
	free(input);

	return 0;
}