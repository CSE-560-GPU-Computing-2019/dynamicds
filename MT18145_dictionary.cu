//MT18145(Shubham Kumar)
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#define NUM 16
//key-value pairs are also referred to as elements in this code.
//Structure for dictionary user-defined data type
//Use structure of arrays instead to use sort and merge
//Dictionary is not ordered and does not search for duplicate
//keys. It supports any number of elements to be inserted
//while executing on GPU. So it is dynamic dictionary.
//Key value pairs are stored in order in which they are inserted.
typedef struct
{
	char key[100];
	char value[100];
	//char* key;
	//char* value;
}Dictionary;

//batchsize < size(in this project for other operations, not insertion)
//Kernel to insert elements in existing dynamic GPU dictionary(Array of Structures)
__global__ void insertBatch(Dictionary *dictionary, Dictionary *data, int batchsize, int size)
{

	int index = blockIdx.x * blockDim.x + threadIdx.x;
	//key_len = strlen(data[index].key);
	//value_len = strlen(data[index].value);
	//for (int i=0;i<key_len;i++)
	if (index<batchsize)
	{
		for (int i=0;i<100;i++)
		{
			dictionary[index+size].key[i] = data[index].key[i];
		}
		//for (int i=0;i<value_len;i++)
		for (int i=0;i<100;i++)
		{
			dictionary[index+size].value[i] = data[index].value[i];
		}	
	}
	 
}
//Kernel to copy key-value pairs of two different Dictionary Array of Structures
__global__ void copyongpu(Dictionary* dst,Dictionary* src, int batchsize)
{
	int index = blockIdx.x * blockDim.x + threadIdx.x;
	if (index<batchsize)
	{
		for (int i=0;i<100;i++)
		{
			dst[index].key[i] = src[index].key[i];
			dst[index].value[i] = src[index].value[i];	
		}
		
	}
}

int main()
{
	int num = NUM, blocksize, numofblocks;
	//num represents number of elements user wants to enter
	//in any iteration
	//blocksize, numofblocks are used for kernel launch
	char input_string[200];//To take input from user
	int maxelements = 10;
	//if size of array of structure on GPU exceeds maxelements,
	//then array of structure is resized,i.e., maxelements*=2
	//and GPU array of structure is copied to temporary array
	//of structure and again copied back when resizing is done,
	//then insertion is done

	int size = 0;//Number of estimated key-value pairs in 
	//Array of Structure after insertion
	int numofelements = 0;// Number of existing key-value pairs
	char *token = NULL;//Used to separate key and value inserted by user
	printf("Enter number of key-value pairs. Enter 0 to exit. ");
	scanf("%d",&num);
	//If user enters 0 or negative number, error is thrown
	if (num<=0)
	return 0;
	Dictionary *gpu_output_dict;
	//desired Array of Structures on GPU of type Dictionary
	//to store key value pairs on GPU 
	//with inclusion of new key value pairs recently inserted
	cudaMalloc((void**)&gpu_output_dict,maxelements*sizeof(Dictionary));
	for (int j=0;j<maxelements;j++)
	{
		//limit on word length of key and value <= 100 characters
		cudaMemset(gpu_output_dict[j].key,'\0',sizeof(gpu_output_dict[j].key));
		cudaMemset(gpu_output_dict[j].value,'\0',sizeof(gpu_output_dict[j].value));
			 
	}
	Dictionary *gpu_temp_dict;
	//Array of Structures of type Dictionary
	//to store elements temporarily so that 
	//gpu_output_dict can be resized
	//Iteration starts
	//User would enter key-value pairs atleast once if num>0 from
	//input taken above
	//Iteration ends when user enters 0 or a negative number
	do
	{
		/*if (size<num)
		{
			//batchsize should always be less than number of existing elements
			printf("Number of elements to be inserted cannot be larger than existing elements. Exiting.");
			break;
		}*/
		size+=num;
		//represents total no of elements after insertion
		//Insertion yet to be done
		//printf("Number of elements: %d\n",numofelements);
		//printf("Number of elements estimated after insertion: %d\n",size);
		
		
		if (size>maxelements)
		{//resizing needed
			int numofblocks2 = 0, blocksize2 = 0;
			//blocksize2, numofblocks2 are used for kernel launch

			maxelements *= 2;
			cudaMalloc((void**)&gpu_temp_dict,maxelements*sizeof(Dictionary));
			for (int j=0;j<maxelements;j++)
			{
			//limit on word length of key and value <= 100 characters
				cudaMemset(gpu_temp_dict[j].key,'\0',sizeof(gpu_output_dict[j].key));
				cudaMemset(gpu_temp_dict[j].value,'\0',sizeof(gpu_output_dict[j].value));
			 
			}
			
			if (maxelements>1024)
			{
				numofblocks2 = (maxelements%1024)?(maxelements/1024):(maxelements/1024+1);
				blocksize2 = 1024;
			}
			else
			{
				numofblocks2 = 1;
				blocksize2 = maxelements;	
			}
			copyongpu<<<numofblocks2,blocksize2>>>(gpu_temp_dict,gpu_output_dict,maxelements);
			cudaFree(gpu_output_dict);
			cudaMalloc((void**)&gpu_output_dict,maxelements*sizeof(Dictionary));
			
			for (int j=0;j<maxelements;j++)
			{
			//limit on word length of key and value <= 100 characters
				cudaMemset(gpu_output_dict[j].key,'\0',sizeof(gpu_output_dict[j].key));
				cudaMemset(gpu_output_dict[j].value,'\0',sizeof(gpu_output_dict[j].value));
			 
			}
			copyongpu<<<numofblocks2,blocksize2>>>(gpu_output_dict,gpu_temp_dict,maxelements);
			cudaFree(gpu_temp_dict);

		}
		
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
			
			scanf("%s",input_string);
			//printf("Input: %s",input_string);
			token = strtok(input_string,"-");
			memset(dict[j].key,'\0',sizeof(dict[j].key));
			memset(dict[j].value,'\0',sizeof(dict[j].value));
			strncpy(dict[j].key,token,100);
			//printf("Key: %s\n",dict[j].key);
			token = strtok(NULL,"-");
			strncpy(dict[j].value,token,100);
			//printf("Value: %s\n",dict[j].value);
			 
			//dict[j].key = (char*)malloc(100);
			//dict[j].value = (char*)malloc(100);
			
			//printf("Enter value: ");
			
		}
		Dictionary *gpu_input_dict;
		cudaMalloc((void**)&gpu_input_dict,num*sizeof(Dictionary));
		
		cudaMemcpy(gpu_input_dict,dict,num*sizeof(Dictionary),cudaMemcpyHostToDevice);
		
		//cudaMemset((void**)&gpu_output_dict,'\0',num*sizeof(Dictionary));
		insertBatch<<<numofblocks,blocksize>>>(gpu_output_dict,gpu_input_dict,num,numofelements);
		Dictionary *cpu_output_dict = (Dictionary*)malloc(maxelements*sizeof(Dictionary));
		//memset(cpu_output_dict,'\0',sizeof(Dictionary)*num);
		for (int j=0;j<maxelements;j++)
		{//limit on word length of key and value <= 100 characters
			memset(cpu_output_dict[j].key,'\0',sizeof(cpu_output_dict[j].key));
			memset(cpu_output_dict[j].value,'\0',sizeof(cpu_output_dict[j].value));
			 
		}
		
		cudaMemcpy(cpu_output_dict,gpu_output_dict,maxelements*sizeof(Dictionary),cudaMemcpyDeviceToHost);
		printf("\n-------------------------------------------------\n");
		for (int j=0;j<size;j++)
		{
			printf("Key: %s\tValue: %s\n",cpu_output_dict[j].key,cpu_output_dict[j].value);
		}
		printf("-------------------------------------------------\n");
		free(dict);
		free(cpu_output_dict);
		cudaFree(gpu_input_dict);
		numofelements+=num;
		printf("Enter number of key-value pairs. Enter 0 to exit. ");
		scanf("%d",&num);
		
	}while (num>0);
	cudaFree(gpu_output_dict);

}
