//MT18145(Shubham Kumar)
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#define NUM 16
//Structure for dictionary user-defined data type
typedef struct
{
	char key[100];
	char value[100];
	//char* key;
	//char* value;
}Dictionary;


__global__ void insertBatch(Dictionary *dictionary, Dictionary *data)
{

	int index = blockIdx.x * blockDim.x + threadIdx.x;
	//key_len = strlen(data[index].key);
	//value_len = strlen(data[index].value);
	//for (int i=0;i<key_len;i++)
	for (int i=0;i<100;i++)
	{
		dictionary[index].key[i] = data[index].key[i];
	}
	//for (int i=0;i<value_len;i++)
	for (int i=0;i<100;i++)
	{
		dictionary[index].value[i] = data[index].value[i];
	} 
}

int main()
{
	int num = NUM, blocksize, numofblocks;
	char *input_string = (char*)malloc(sizeof(char)*200);
	printf("Enter number of key-value pairs. Enter 0 to exit. ");
	scanf("%d",&num);
	if (num<=0)
	return 0;
	do
	{
		if (num>1024)
		{
			numofblocks = (num%1024)?(num/1024):(num/1024+1);
			blocksize = 1024;
		}
		else
		{
			numofblocks = 1;
			blocksize = num;	
		}
		Dictionary *dict = (Dictionary*)malloc(num*sizeof(Dictionary));
		for (int j=0;j<num;j++)
		{//limit on word length of key and value <= 100 characters
			printf("Enter key and value separated by - : ");
			fgets(input_string,200,stdin);
			char *token = strtok(input_string,"-");
			strncpy(dict[j].key,token,sizeof(dict[j].key));
			token = strtok(input_string,"-");
			strncpy(dict[j].value,token,sizeof(dict[j].value));
			 
			//dict[j].key = (char*)malloc(100);
			//dict[j].value = (char*)malloc(100);
			//gets(dict[j].key);
			//printf("Enter value: ");
			//gets(dict[j].value);
			//fgets(dict[j].value,100,stdin);
		}
		Dictionary *gpu_output_dict,*gpu_input_dict;
		cudaMalloc((void**)&gpu_input_dict,num*sizeof(Dictionary));
		
		cudaMemcpy(gpu_input_dict,dict,num*sizeof(Dictionary),cudaMemcpyHostToDevice);
		cudaMalloc((void**)&gpu_output_dict,num*sizeof(Dictionary));
		cudaMemset((void**)&gpu_output_dict,'\0',num*sizeof(Dictionary));
		insertBatch<<<numofblocks,blocksize>>>(gpu_output_dict,gpu_input_dict);
		Dictionary *cpu_output_dict = (Dictionary*)malloc(num*sizeof(Dictionary));
		memset(cpu_output_dict,'\0',sizeof(Dictionary)*num);
		cudaMemcpy(cpu_output_dict,gpu_output_dict,num*sizeof(Dictionary),cudaMemcpyDeviceToHost);
		
		for (int j=0;j<num;j++)
		{
			printf("Key: %s\tValue: %s\n",cpu_output_dict[j].key,cpu_output_dict[j].value);
		}
		printf("Enter number of key-value pairs. Enter 0 to exit. ");
		scanf("%d",&num);
		
	}while (num>0);
}