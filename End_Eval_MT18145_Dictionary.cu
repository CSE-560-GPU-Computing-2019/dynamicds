//MT18145(Shubham Kumar)
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <thrust/sort.h>
#include <algorithm>
#define NUM 16
#define SIZE 16
#define MAXE 10000000
#define BLOCKSIZE 1024
#define INCREMENT 100000
unsigned long int numofelements = 0;
unsigned long int maxelements = MAXE;
unsigned long int size = 0; //Number of estimated key-value pairs in Array of Structure after insertion
unsigned int loop=0;
__device__ unsigned int found_flag = 0;//flag to be used to make other threads do the minimal work
//key-value pairs are also referred to as elements in this code.
//Structure for dictionary user-defined data type
//Use structure of arrays instead to use sort and merge
//Dictionary is not ordered and does not search for duplicate
//keys. It supports any number of elements to be inserted
//while executing on GPU. So it is dynamic dictionary.
//Key value pairs are stored in order in which they are inserted.
typedef struct
{
	char key[SIZE];
	char value[SIZE];
	//char* key;
	//char* value;
}Dictionary;

Dictionary *gpu_output_dict;
	//desired Array of Structures on GPU of type Dictionary
	//to store key value pairs on GPU 
	//with inclusion of new key value pairs recently inserted
	


//batchsize < size(in this project for other operations, not insertion)
//Kernel to insert elements in existing dynamic GPU dictionary(Array of Structures)
__global__ void insertBatch(Dictionary *dictionary, Dictionary *data, int batchsize, int size)
{

	int index = blockIdx.x * blockDim.x + threadIdx.x;
	if (index<batchsize)
	{
		for (int i=0;i<SIZE;i++)
		{
			dictionary[index+size].key[i] = '\0';
			//dictionary[index+size].key[i] = data[index].key[i];
		}
		for (int i=0;i<SIZE;i++)
		{
			dictionary[index+size].value[i] = '\0';
			//dictionary[index+size].value[i] = data[index].value[i];
		}
	}
	__syncthreads();
	if (index<batchsize)
	{
		//atomicAdd(count,1);
		for (int i=0;i<SIZE;i++)
		{
			//dictionary[index+size].key[i] = '\0';
			dictionary[index+size].key[i] = data[index].key[i];
		}
		//for (int i=0;i<value_len;i++)
		for (int i=0;i<SIZE;i++)
		{
			//dictionary[index+size].value[i] = '\0';
			dictionary[index+size].value[i] = data[index].value[i];
		}	
	}
	__syncthreads();
	
	 
}
__global__ void printDictionary(Dictionary *device_dictionary, int start, int end)
{
	//if (threadIx.x==0)
	for (int i=start;i<=end;i++)
	{
		printf("Key: %s \tValue: %s \n",device_dictionary[i].key,device_dictionary[i].value);
	}
}
//Kernel to copy key-value pairs of two different Dictionary Array of Structures
//__global__ void copyongpu(Dictionary** dst,Dictionary** src, int batchsize)
__global__ void copyongpu(Dictionary *dst, Dictionary *src, int batchsize)
{
	int index = blockIdx.x * blockDim.x + threadIdx.x;
	//if (index==0)
	//		*count=0;
	//	__syncthreads();
		if (index<batchsize)
		{
			for (int i=0;i<SIZE;i++) 
			{
				dst[index].key[i]='\0';
				dst[index].value[i]='\0';
				//dst[index].key[i] = src[index].key[i];
				//dst[index].value[i] = src[index].value[i];	
			}
		}
		__syncthreads();
	if (index<batchsize)
	{
		//atomicAdd(count,1);
		for (int i=0;i<SIZE;i++) 
		{
			//dst[index].key[i]='\0';
			//dst[index].value[i]='\0';
			dst[index].key[i] = src[index].key[i];
			dst[index].value[i] = src[index].value[i];	
		}
	
	}
	__syncthreads();
		
	
	//__syncthreads();
	//if (index>100000)
	//	printf("Index: %d\n", index);
}
__global__ void searchElements(Dictionary *temp, int *index_array, char** search_arr, int num, int numofelements)
{
	
	int index = blockIdx.x * blockDim.x + threadIdx.x;
	int flag = -1;
	
	__syncthreads();
	if (index < num)
	{
		for (int i=0;i<numofelements;i++) 
			{
				flag = 0;
				for (int j=0;search_arr[index][j]!='\0';j++)
				{
					//printf("Search arr: %c\n",search_arr[index][j]);
					//printf("Present element: %c\n",temp[i].key[j]);

					if (search_arr[index][j]!=temp[i].key[j])
						{	
							//int temp = flag+1;
							flag = 1;
							break;
						}
					
				}
				if (flag==0)
				{
					//printf("Index: %d\n",i);
					index_array[index]=i;
					//return;
					//return;
				}

			}
	}
	
	__syncthreads();

}

__global__ void deleteElements(Dictionary *temp, int *index_array, int num)
{
	
	int index = blockIdx.x * blockDim.x + threadIdx.x;
	if (index < num)
	{
		int temp_index = index_array[index];

		if (temp_index!=-1)
		{
			temp[temp_index].key[0]='{';
			temp[temp_index].value[0]='$';
		}
	}
	
	__syncthreads();

}


/*
__host__ __device__ 
*/
bool compareElements(const Dictionary &gpu_first_dictionary, const Dictionary &gpu_second_dictionary)
{
	//if (strncmp(*gpu_first_dictionary.value,*gpu_second_dictionary.value)!=0)
	//int comparebits = 15;
	int compared_value = 0;
	for (int k=0;k<SIZE;k++)
	{
		if (gpu_first_dictionary.key[k]<gpu_second_dictionary.key[k])
		{
			compared_value  = -1;
			break;
		}
		else if (gpu_first_dictionary.key[k]>gpu_second_dictionary.key[k])
		{
			compared_value = 1;
			break;
		}

	}
	//strncmp(gpu_first_dictionary.key,gpu_second_dictionary.key,comparebits);
	if (compared_value<0)
		return true;
	else
		return false;
	//else
		//return strncmp(*gpu_first_dictionary.value,*gpu_second_dictionary.key);
};
/**/


void insertData()
{	
	char input_string[35];//To take input from user
	int num=NUM;
	//int size = 0;
	//int numofelements = 0;// Number of existing key-value pairs
	printf("Enter number of key-value pairs. Enter 0 to exit. ");
	scanf("%d",&num);
	//If user enters 0 or negative number, program exits
	if (num<0)
	{
		printf("\nInvalid entry by user. Negative value encountered. ");
		return;
	}
	else if (num==0)
	{
		return;
	}
	unsigned int blocksize, numofblocks; //blocksize, numofblocks are used for kernel launch
	cudaError_t errors;		
	cudaError_t cudaStatus;
	maxelements = MAXE;
	//if size of array of structure on GPU exceeds maxelements,
	//then array of structure is resized,i.e., maxelements+=1000000
	//and GPU array of structure is copied to temporary array
	//of structure and again copied back when resizing is done,
	//then insertion is done
	char *token = NULL;//Used to separate key and value inserted by user
	//Iteration starts
	//User would enter key-value pairs atleast once if num>0 from
	//input taken above
	//Iteration ends when user enters 0 or a negative number
	
	//do
	//{
		if (maxelements<num)
		{
			//batchsize should always be less than number of existing elements
			printf("Number of elements to be inserted should be such that resizing is done only after many batches of insertions. Exiting. \n");
			return;
		}
		size+=num;
		//represents total no of elements after insertion
		//Insertion yet to be done
		//printf("Number of elements: %d\n",numofelements);
		//printf("Number of elements estimated after insertion: %d\n",size);
		//const clock_t begin_time2 = clock();
		
		loop+=1;	
		if (size>maxelements)
		{//resizing needed
			int numofblocks2 = 0, blocksize2 = 0;
			//blocksize2, numofblocks2 are used for kernel launch
			while (size>maxelements)
			maxelements += INCREMENT;
			Dictionary *gpu_temp_dict;
			//Array of Structures of type Dictionary
			//to store elements temporarily so that 
			//gpu_output_dict can be resized
			
			errors = cudaMalloc((void**)&gpu_temp_dict,maxelements*sizeof(Dictionary));
			if(errors!=cudaSuccess)
			{
				fprintf(stderr,"cudaMalloc failed for gpu_temp_dict: %s\n",cudaGetErrorString(errors));
			}
			/*for (int j=0;j<maxelements;j++)
			{
			//limit on word length of key and value <= 100 characters
				cudaMemset(gpu_temp_dict[j].key,'\0',sizeof(gpu_output_dict[j].key));
				cudaMemset(gpu_temp_dict[j].value,'\0',sizeof(gpu_output_dict[j].value));
			 
			}*/
			//printf("Maxelements :%d\n",maxelements);	
			//if (maxelements>1024)
			//{
				numofblocks2 = (maxelements%BLOCKSIZE==0)?(maxelements/BLOCKSIZE):(maxelements/BLOCKSIZE+1);
				blocksize2 = BLOCKSIZE;
				printf("Num of blocks %d\n",numofblocks2);
			//}
			/*else
			{
				numofblocks2 = 1;
				blocksize2 = maxelements;	
			}*/
			//errors = cudaMemcpy(gpu_temp_dict,gpu_output_dict,numofelements*sizeof(Dictionary),cudaMemcpyDeviceToDevice);
			//errors = cudaMemcpy(cpu_output_dict,gpu_output_dict,maxelements*sizeof(Dictionary),cudaMemcpyDeviceToHost);
			/*if (errors!=cudaSuccess)
			{
				fprintf(stderr,"cudaMemcpy failed for gpu_output_dict to gpu_temp_dict: %s\n",cudaGetErrorString(errors));
			}*/

			copyongpu<<<numofblocks2,blocksize2>>>((Dictionary*)gpu_temp_dict,(Dictionary*)gpu_output_dict,numofelements);
			/*cudaStatus = cudaGetLastError();
			if (cudaStatus!=cudaSuccess)
			{
				fprintf(stderr,"copyongpu kernel failed for gpu_output_dict to gpu_temp_dict: %s\n",cudaGetErrorString(cudaStatus));
			}*/

			errors = cudaDeviceSynchronize();
			if(errors!=cudaSuccess)
			{
				fprintf(stderr,"copyongpu kernel failed for gpu_output_dict to gpu_temp_dict: %s\n",cudaGetErrorString(errors));

				//fprintf(stderr,"cudaDeviceSynchronize failed for gpu_output_dict to gpu_temp_dict copyongpu: %s\n",cudaGetErrorString(errors));
			}
			
			//*cnt_host2 = 0;
			/*errors = cudaMemcpy(cnt_host2,cnt2,sizeof(int),cudaMemcpyDeviceToHost);
			if(errors!=cudaSuccess)
			{
				fprintf(stderr,"cudaMemcpy failed for cnt2 to cnt_host2: %s\n",cudaGetErrorString(errors));
			}
			printf("Count from copyongpu kernel: %d\n",*cnt_host2);
			errors = cudaMemset(cnt2,0,sizeof(int));
			if(errors!=cudaSuccess)
			{
				fprintf(stderr,"cudaMemset failed for count2: %s\n",cudaGetErrorString(errors));
			}*/
			errors = cudaFree(gpu_output_dict);
			if(errors!=cudaSuccess)
			{
				fprintf(stderr,"cudaFree failed for gpu_output_dict: %s\n",cudaGetErrorString(errors));
			}
			errors = cudaMalloc((void**)&gpu_output_dict,maxelements*sizeof(Dictionary));
			if(errors!=cudaSuccess)
			{
				fprintf(stderr,"cudaMalloc failed for resizing gpu_output_dict: %s\n",cudaGetErrorString(errors));
			}
			/*for (int j=0;j<maxelements;j++)
			{
			//limit on word length of key and value <= 100 characters
				cudaMemset(gpu_output_dict[j].key,'\0',sizeof(gpu_output_dict[j].key));
				cudaMemset(gpu_output_dict[j].value,'\0',sizeof(gpu_output_dict[j].value));
			 
			}*/
			copyongpu<<<numofblocks2,blocksize2>>>((Dictionary*)gpu_output_dict,(Dictionary*)gpu_temp_dict,numofelements);
			/*cudaStatus = cudaGetLastError();
			if (cudaStatus!=cudaSuccess)
			{
				fprintf(stderr,"copyongpu kernel failed for gpu_temp_dict to gpu_output_dict: %s\n",cudaGetErrorString(cudaStatus));
			}*/
			errors = cudaDeviceSynchronize();
			if(errors!=cudaSuccess)
			{
				fprintf(stderr,"copyongpu kernel failed for gpu_temp_dict to gpu_output_dict copyongpu: %s\n",cudaGetErrorString(errors));
			}
			//errors = cudaMemcpy(gpu_output_dict,gpu_temp_dict,numofelements*sizeof(Dictionary),cudaMemcpyDeviceToDevice);
			/*if (errors!=cudaSuccess)
			{
				fprintf(stderr,"cudaMemcpy failed for gpu_temp_dict to gpu_output_dict: %s\n",cudaGetErrorString(errors));
			}*/
			/*errors = cudaMemcpy(cnt_host2,cnt2,sizeof(int),cudaMemcpyDeviceToHost);
			if(errors!=cudaSuccess)
			{
				fprintf(stderr,"cudaMemcpy failed for cnt2 to cnt_host2: %s\n",cudaGetErrorString(errors));
			}
			printf("Count from copyongpu kernel: %d\n",*cnt_host2);
			errors = cudaMemset(cnt2,0,sizeof(int));
			if(errors!=cudaSuccess)
			{
				fprintf(stderr,"cudaMemset failed for count2: %s\n",cudaGetErrorString(errors));
			}*/
			errors = cudaFree(gpu_temp_dict);
			if(errors!=cudaSuccess)
			{
				fprintf(stderr,"cudaFree failed for gpu_temp_dict: %s\n",cudaGetErrorString(errors));
			}

		}
		
		//if (num>1024)
		//{
			numofblocks = (num%BLOCKSIZE==0)?(num/BLOCKSIZE):(num/BLOCKSIZE+1);
			blocksize = BLOCKSIZE;
		//}
		/*else
		{
			numofblocks = 1;
			blocksize = num;	
		}*/
		//char inpt = '1';
		//char jinp = '1';
		Dictionary *dict = (Dictionary*)malloc(num*sizeof(Dictionary));
		//Dictionary dict[num];
		for (int j=0;j<num;j++)
		{//limit on word length of key and value <= 100 characters
		//	printf("Enter key and value separated by - : ");
			
		//	scanf("%s",input_string);
			//printf("Input: %s",input_string);
			char *inp1 = (char*)malloc(SIZE*sizeof(char));
			char *inp2 = (char*)malloc(SIZE*sizeof(char));
			char jinp[10];
			char cloop[5];
			if (num>5)
			{
				sprintf(cloop,"%d",loop);
				sprintf(jinp,"%d",j);
				strcpy(inp1,"Key");
				strcat(inp1,(const char*)jinp);
				strcat(inp1,"_");
				strcat(inp1,cloop);
				strcpy(inp2,"Value");
				strcat(inp2,(const char*)jinp);
				strcat(inp2,"_");
				strcat(inp2,cloop);
				strcpy(input_string,inp1);
				strcat(input_string,"-");
				strcat(input_string,inp2);
		
			}
			
			else if (num>0 && num<=5)
			{
				printf("Enter key and value separated by -(at most 15 characters each): ");
				scanf("%s",input_string);	
			}
			token = strtok(input_string,"-");
			memset(dict[j].key,'\0',sizeof(dict[j].key));
			memset(dict[j].value,'\0',sizeof(dict[j].value));
			strncpy(dict[j].key,token,SIZE);
			//printf("Key: %s\n",dict[j].key);
			token = strtok(NULL,"-");
			strncpy(dict[j].value,token,SIZE);
			//printf("Value: %s\n",dict[j].value);
			 
			//dict[j].key = (char*)malloc(100);
			//dict[j].value = (char*)malloc(100);
			//jinp=jinp+1;
			//printf("Enter value: ");
			//inpt=inpt+'1';
		}
		Dictionary *gpu_input_dict;
		errors = cudaMalloc((void**)&gpu_input_dict,num*sizeof(Dictionary));
		if(errors!=cudaSuccess)
			{
				fprintf(stderr,"cudaMalloc failed for gpu_input_dict: %s\n",cudaGetErrorString(errors));
			}
		errors = cudaMemcpy(gpu_input_dict,dict,num*sizeof(Dictionary),cudaMemcpyHostToDevice);
		if(errors!=cudaSuccess)
			{
				fprintf(stderr,"cudaMemcpy failed for dict(host) to gpu_input_dict: %s\n",cudaGetErrorString(errors));
			}
		//const clock_t begin_time = clock();
		//cudaMemset((void**)&gpu_output_dict,'\0',num*sizeof(Dictionary));
		insertBatch<<<numofblocks,blocksize>>>(gpu_output_dict,gpu_input_dict,num,numofelements);
		cudaStatus = cudaDeviceSynchronize();
		if (cudaStatus!=cudaSuccess)
		{
			fprintf(stderr,"insertBatch kernel failed: %s\n",cudaGetErrorString(cudaStatus));
		}
		/*errors = cudaMemcpy(cnt_host1,cnt1,sizeof(int),cudaMemcpyDeviceToHost);
		if(errors!=cudaSuccess)
			{
				fprintf(stderr,"cudaMemcpy failed for cnt1 to cnt_host1: %s\n",cudaGetErrorString(errors));
			}*/
		//printf("Count from insertBatch kernel: %d\n",*cnt_host1);
		/*errors = cudaMemset(cnt1,0,sizeof(int));
		if(errors!=cudaSuccess)
			{
				fprintf(stderr,"cudaMemset failed for count1: %s\n",cudaGetErrorString(errors));
			}*/
		//errors = cudaDeviceSynchronize();
		//float runtime_insert = (float)(clock()-begin_time)/CLOCKS_PER_ ;
		//printf("Insertion time(Only Kernel launch) for %d elements on GPU: %fsec\n",num,runtime_insert);

		//Dictionary *cpu_output_dict = (Dictionary*)malloc(maxelements*sizeof(Dictionary));
		//memset(cpu_output_dict,'\0',sizeof(Dictionary)*num);
		/*Dictionary cpu_output_dict[maxelements];
		for (int j=0;j<maxelements;j++)
		{//limit on word length of key and value <= 100 characters
			memset(cpu_output_dict[j].key,'\0',sizeof(cpu_output_dict[j].key));
			memset(cpu_output_dict[j].value,'\0',sizeof(cpu_output_dict[j].value));
			 
		}
		*/
		/*errors = cudaMemcpy(cpu_output_dict,gpu_output_dict,maxelements*sizeof(Dictionary),cudaMemcpyDeviceToHost);
		if(errors!=cudaSuccess)
			{
				fprintf(stderr,"cudaMemcpy failed for gpu_output_dict to cpu_output_dict: %s\n",cudaGetErrorString(errors));
			}
			*/
		errors = cudaDeviceSynchronize();
		if(errors!=cudaSuccess)
			{
				fprintf(stderr,"cudaDeviceSynchronize failed for insertBatch: %s\n",cudaGetErrorString(errors));
			}
		//float runtime_insert2 = (float)(clock()-begin_time2)/CLOCKS_PER_SEC;
		//printf("Insertion time(Kernel launch+Memory calls) for %d elements on GPU: %fsec\n",num,runtime_insert2);

		//free(dict);
		//free(cpu_output_dict);
		errors = cudaFree(gpu_input_dict);
		if(errors!=cudaSuccess)
			{
				fprintf(stderr,"cudaFree failed for gpu_input_dict: %s\n",cudaGetErrorString(errors));
			}
		numofelements+=num;
		//printf("Enter number of key-value pairs. Enter 0 to exit. ");
		//scanf("%d",&num);
		//free(cpu_output_dict);
		free(dict);


		//sort the array of structures
		Dictionary *sort_dict = (Dictionary*)malloc(sizeof(Dictionary)*numofelements);
		errors = cudaMemcpy(sort_dict,gpu_output_dict,numofelements*sizeof(Dictionary),cudaMemcpyDeviceToHost);
		if (errors!=cudaSuccess)
		{
			fprintf(stderr,"cudaMemcpy failed for gpu_outut_dict to sort_dict: %s\n",cudaGetErrorString(errors));
		}
		std::sort(sort_dict,sort_dict+numofelements,compareElements);
		errors = cudaMemcpy(gpu_output_dict,sort_dict,numofelements*sizeof(Dictionary),cudaMemcpyHostToDevice);
		if (errors!=cudaSuccess)
		{
			fprintf(stderr,"cudaMemcpy failed for sort_dict to gpu_outut_dict: %s\n",cudaGetErrorString(errors));
		}
		
		free(sort_dict);

	//}while (num>0);

	/*
	errors = cudaFree(gpu_output_dict);
	
	if(errors!=cudaSuccess)
	{
		fprintf(stderr,"cudaFree failed for gpu_output_dict: %s\n",cudaGetErrorString(errors));
	}
	*/

}
void searchDictionary()
{
	int num=NUM;
	static int loop2=1;
	printf("Enter number of key-value pairs to search for. \n");
	scanf("%d",&num);
	if (num<=0)
	{
		printf("Invalid number. \n");
		return;
	}
	char input_string[SIZE];
	char **search_array = (char**)malloc(sizeof(char*)*num);
	for (int i=0;i<num;i++)
	{
		search_array[i] = (char*)malloc	(sizeof(char)*SIZE);
		memset(search_array[i],'\0',sizeof(char)*SIZE);
	}
	//memset(search_array,'\0',sizeof(char)*num*SIZE);
			
	for (int j=0;j<num;j++)
		{
			char *inp1 = (char*)malloc(SIZE*sizeof(char));
			char jinp[10];
			char cloop[5];
			if (num>5)
			{
				sprintf(cloop,"%d",loop2);
				sprintf(jinp,"%d",j);
				strcpy(inp1,"Key");
				strcat(inp1,(const char*)jinp);
				strcat(inp1,"_");
				strcat(inp1,cloop);
				strcpy(input_string,inp1);
				//printf("Key to search for: %s .\n",input_string);
			}
			
			else if (num>0 && num<=5)
			{
				printf("Enter the key to search for (at most 15 characters in length): ");
				scanf("%s",input_string);	
			}
			
			strncpy(search_array[j],input_string,SIZE);
			//printf("Search array: %s. \n",search_array[j]);
		}
		int *index_array = (int*)malloc(sizeof(int)*num);
		//TO store indices of elements
		int *index_d;
		cudaMalloc((void**)&index_d,sizeof(int)*num);
		char **search_d_array;
		char **search_h_array = (char**)malloc(sizeof(char*)*num);
		cudaMalloc((void**)&search_d_array,sizeof(char*)*num);
		cudaMemcpy(search_h_array,search_d_array,sizeof(char*)*num,cudaMemcpyDeviceToHost);
		for (int i=0;i<num;i++)
		{
			cudaMalloc((void**)&search_h_array[i],sizeof(char)*SIZE);
			cudaMemset(search_h_array[i],'\0',sizeof(char)*SIZE);
			cudaMemcpy(search_h_array[i],search_array[i],sizeof(char)*SIZE,cudaMemcpyHostToDevice);
		}
		cudaMemcpy(search_d_array,search_h_array,sizeof(char*)*num,cudaMemcpyHostToDevice);
		//for (int i=0;i<num;i++)
		//	printf("Elements: %s\n",search_h_array[i]);
		unsigned int blocksize = 0, numofblocks = 0;
		blocksize = BLOCKSIZE;
		numofblocks = (num%BLOCKSIZE==0)?(num/BLOCKSIZE):(num/BLOCKSIZE+1);
		//locksize = 1, numofblocks = 1;
		//for (int element = 0;element<num;element++)
		cudaMemset(index_d,-1,sizeof(int)*num);
		searchElements<<<numofblocks,blocksize>>>(gpu_output_dict,index_d,search_d_array,num,numofelements);
		//errors = 
		cudaDeviceSynchronize();
		cudaMemcpy(index_array,index_d,sizeof(int)*num,cudaMemcpyDeviceToHost);
		/*if (errors!=cudaSuccess)
		{
			printf("Error in cudaMemcpy from index host to index device. \n");
		}*/

		char keystring[SIZE];
		char valuestring[SIZE];
			
		for (int i=0;i<num;i++)
		{
			memset(keystring,'\0',SIZE*sizeof(char));
			memset(valuestring,'\0',SIZE*sizeof(char));
			//cudaMemcpy(keystring,search_h_array[i],sizeof(char)*SIZE,cudaMemcpyDeviceToHost);
			//printf("Indices for key %s is : %d.\n",keystring,index_array[i]);
			if (index_array[i]!=-1)
			{
				cudaMemcpy(keystring,gpu_output_dict[index_array[i]].key,sizeof(char)*SIZE,cudaMemcpyDeviceToHost);
				cudaMemcpy(valuestring,gpu_output_dict[index_array[i]].value,sizeof(char)*SIZE,cudaMemcpyDeviceToHost);
				printf("Key: %s, Value: %s\n",keystring,valuestring);
			
			}
			else
			{
				cudaMemcpy(keystring,search_h_array[i],sizeof(char)*SIZE,cudaMemcpyDeviceToHost);
				printf("Key-Value does not exist for Queried Key: %s\n",keystring);
			}
			cudaFree(search_h_array[i]);

		}
		for (int i=0;i<num;i++)
			free(search_array[i]);
		free(search_array);
		free(index_array);
		cudaFree(index_d);
		cudaFree(search_d_array);
		loop2+=1;
}

void deleteDictionary()
{
	static int loop2=1;
	int num=NUM;
	printf("Enter number of key-value pairs to delete from dictionary. \n");
	scanf("%d",&num);
	if (num<=0)
	{
		printf("Invalid number. \n");
		return;
	}
	char input_string[SIZE];
	char **search_array = (char**)malloc(sizeof(char*)*num);
	for (int i=0;i<num;i++)
	{
		search_array[i] = (char*)malloc	(sizeof(char)*SIZE);
		memset(search_array[i],'\0',sizeof(char)*SIZE);
	}
	//memset(search_array,'\0',sizeof(char)*num*SIZE);
			
	for (int j=0;j<num;j++)
		{
			char *inp1 = (char*)malloc(SIZE*sizeof(char));
			char jinp[10];
			char cloop[5];
			if (num>5)
			{
				sprintf(cloop,"%d",loop2);
				sprintf(jinp,"%d",j);
				strcpy(inp1,"Key");
				strcat(inp1,(const char*)jinp);
				strcat(inp1,"_");
				strcat(inp1,cloop);
				strcpy(input_string,inp1);
				//printf("Key to search for: %s .\n",input_string);
			}
			
			else if (num>0 && num<=5)
			{
				printf("Enter the key corrsponding to key-value pair to be deleted(at most 15 characters in length): ");
				scanf("%s",input_string);	
			}
			
			strncpy(search_array[j],input_string,SIZE);
			//printf("Search array: %s. \n",search_array[j]);
		}
		int *index_array = (int*)malloc(sizeof(int)*num);
		//TO store indices of elements
		int *index_d;
		cudaMalloc((void**)&index_d,sizeof(int)*num);
		char **search_d_array;
		char **search_h_array = (char**)malloc(sizeof(char*)*num);
		cudaMalloc((void**)&search_d_array,sizeof(char*)*num);
		cudaMemcpy(search_h_array,search_d_array,sizeof(char*)*num,cudaMemcpyDeviceToHost);
		for (int i=0;i<num;i++)
		{
			cudaMalloc((void**)&search_h_array[i],sizeof(char)*SIZE);
			cudaMemset(search_h_array[i],'\0',sizeof(char)*SIZE);
			cudaMemcpy(search_h_array[i],search_array[i],sizeof(char)*SIZE,cudaMemcpyHostToDevice);
		}
		cudaMemcpy(search_d_array,search_h_array,sizeof(char*)*num,cudaMemcpyHostToDevice);
		//for (int i=0;i<num;i++)
		//	printf("Elements: %s\n",search_h_array[i]);
		unsigned int blocksize = 0, numofblocks = 0;
		blocksize = BLOCKSIZE;
		numofblocks = (num%BLOCKSIZE==0)?(num/BLOCKSIZE):(num/BLOCKSIZE+1);
		//locksize = 1, numofblocks = 1;
		//for (int element = 0;element<num;element++)
		cudaMemset(index_d,-1,sizeof(int)*num);
		searchElements<<<numofblocks,blocksize>>>(gpu_output_dict,index_d,search_d_array,num,numofelements);
		//errors = 
		cudaDeviceSynchronize();
		cudaMemcpy(index_array,index_d,sizeof(int)*num,cudaMemcpyDeviceToHost);
		/*if (errors!=cudaSuccess)
		{
			printf("Error in cudaMemcpy from index host to index device. \n");
		}*/
		int count = 0;
		for (int loop=0;loop<num;loop++)
		{
			if (index_array[loop]!=-1)
				count++;
		}

		//char keystring[SIZE];
		//char valuestring[SIZE];
		cudaError_t errors;
		deleteElements<<<numofblocks,blocksize>>>(gpu_output_dict,index_d,num);
		cudaDeviceSynchronize();

		for (int i=0;i<num;i++)
		{
			cudaFree(search_h_array[i]);

		}
		for (int i=0;i<num;i++)
			free(search_array[i]);
		free(search_array);
		free(index_array);
		cudaFree(index_d);
		cudaFree(search_d_array);

		Dictionary *sort_dict = (Dictionary*)malloc(sizeof(Dictionary)*numofelements);
		errors = cudaMemcpy(sort_dict,gpu_output_dict,numofelements*sizeof(Dictionary),cudaMemcpyDeviceToHost);
		if (errors!=cudaSuccess)
		{
			fprintf(stderr,"cudaMemcpy failed for gpu_outut_dict to sort_dict: %s\n",cudaGetErrorString(errors));
		}
		std::sort(sort_dict,sort_dict+numofelements,compareElements);
		errors = cudaMemcpy(gpu_output_dict,sort_dict,numofelements*sizeof(Dictionary),cudaMemcpyHostToDevice);
		if (errors!=cudaSuccess)
		{
			fprintf(stderr,"cudaMemcpy failed for sort_dict to gpu_outut_dict: %s\n",cudaGetErrorString(errors));
		}
		
		free(sort_dict);

		printf("Found key-value pairs Deleted. \n");
		numofelements = numofelements - count;
		size = size - count;

		loop2+=1;
}

void rangeQuery()
{
	//static int loop2=1;
	int num=NUM;
	//printf("Enter number of key-value pairs to delete from dictionary. \n");
	//scanf("%d",&num);
	char input_string[SIZE];
	char **search_array = (char**)malloc(sizeof(char*)*2);
	//char search_array[2][SIZE];
	for (int i=0;i<2;i++)
	{
		search_array[i] = (char*)malloc	(sizeof(char)*SIZE);
		memset(search_array[i],'\0',sizeof(char)*SIZE);
	}
			num = 2;
	for (int j=0;j<2;j++)
		{
			printf("Enter the key(Key must be exisitng in dictionary): ");
			scanf("%s",input_string);	
			
			strncpy(search_array[j],input_string,SIZE);
			//printf("Search array: %s. \n",search_array[j]);
		}

		int *index_array = (int*)malloc(sizeof(int)*2);
		//int index_array[2];
		//TO store indices of elements
		int *index_d;
		cudaMalloc((void**)&index_d,sizeof(int)*2);
		char **search_d_array;
		//char search_d_array
		char **search_h_array = (char**)malloc(sizeof(char*)*num);
		cudaMalloc((void**)&search_d_array,sizeof(char*)*num);
		cudaMemcpy(search_h_array,search_d_array,sizeof(char*)*num,cudaMemcpyDeviceToHost);
		for (int i=0;i<num;i++)
		{
			cudaMalloc((void**)&search_h_array[i],sizeof(char)*SIZE);
			cudaMemset(search_h_array[i],'\0',sizeof(char)*SIZE);
			cudaMemcpy(search_h_array[i],search_array[i],sizeof(char)*SIZE,cudaMemcpyHostToDevice);
		}
		cudaMemcpy(search_d_array,search_h_array,sizeof(char*)*num,cudaMemcpyHostToDevice);
		//for (int i=0;i<num;i++)
		//	printf("Elements: %s\n",search_h_array[i]);
		unsigned int blocksize = 0, numofblocks = 0;
		//blocksize = BLOCKSIZE;
		//numofblocks = (num%BLOCKSIZE==0)?(num/BLOCKSIZE):(num/BLOCKSIZE+1);
		//locksize = 1, numofblocks = 1;
		//for (int element = 0;element<num;element++)
		cudaMemset(index_d,-1,sizeof(int)*num);
		searchElements<<<1,2>>>(gpu_output_dict,index_d,search_d_array,num,numofelements);
		//errors = 
		cudaDeviceSynchronize();
		cudaMemcpy(index_array,index_d,sizeof(int)*num,cudaMemcpyDeviceToHost);
		/*if (errors!=cudaSuccess)
		{
			printf("Error in cudaMemcpy from index host to index device. \n");
		}*/
		int count = 0;
		if (index_array[0]!=-1)
			count++;
		if (index_array[1]!=-1)
			count++;
		
		if (count!=2)
		{
			printf("One or more key not found in dictionary. Please enter existing key. \n");
			return;
		}
		if (index_array[1]<index_array[0])
			{
				int temp_var = index_array[0];
				index_array[0] = index_array[1];
				index_array[1] = temp_var;
			}
		int rangecount = index_array[1]-index_array[0]+1;

		printf("Number of elements between elements corresponding to given two keys are: %d\n",rangecount);
		printf("Elements are: \n");
		printDictionary<<<1,1>>>(gpu_output_dict,index_array[0],index_array[1]);
		//char keystring[SIZE];
		//char valuestring[SIZE];
		//cudaError_t errors;
		//printDictionary<<<numofblocks,blocksize>>>(gpu_output_dict,index_d,num);
		cudaDeviceSynchronize();

		for (int i=0;i<num;i++)
		{
			cudaFree(search_h_array[i]);

		}
		for (int i=0;i<num;i++)
			free(search_array[i]);
		free(search_array);
		free(index_array);
		cudaFree(index_d);
		cudaFree(search_d_array);

		
		//loop2+=1;
}

int main()
{
	//int num = NUM;
	//num represents number of elements user wants to enter
	//in any iteration
	cudaError_t errors;
	
	char user_input[50];
	memset(user_input,'\0',50);
	errors = cudaMalloc((void**)&gpu_output_dict,maxelements*sizeof(Dictionary));
	if(errors!=cudaSuccess)
	{
		fprintf(stderr,"cudaMalloc failed for gpu_output_dict: %s\n",cudaGetErrorString(errors));
	}
	
	do
	{
		printf("\n\n**********************************************CHOICES**********************************************\n\n");
		printf("Enter insert for Insert opeation in batches. \n");
		printf("Enter delete for Delete operation in batches. \n");
		printf("Enter showlast for viewing last 10 elements in the dictionary. \n");
		printf("Enter showfirst for viewing first 10 elements in the dictionary. \n");
		printf("Enter search for search/lookup operation over all elements. \n");
		printf("Enter range-search for getting list of key-value pairs and count between a particular range of existing keys. \n");
		printf("\n\n***************************************************************************************************\n\n");
		printf("Enter your choice [insert/delete/showlast/showfirst/search/range-search/exit]: ");
		scanf("%s",user_input);
		cudaEvent_t start,stop;
		float time;
		cudaEventCreate(&start);
		cudaEventCreate(&stop);
			
		if (strncmp(user_input,"insert",6)==0)
		{
			printf("Insert operation. \n");
			cudaEventRecord(start,0);
			insertData();
			cudaEventRecord(stop,0);
			cudaEventSynchronize(stop);
			cudaEventElapsedTime(&time,start,stop);
			printf("Time taken for Insertion on GPU: %fms.\n",time/1000);
		}
		else if (strncmp(user_input,"delete",6)==0)
		{
			if (numofelements==0)
			{
				printf("Deletion not possible. Dictionary is empty. \n");
			}
			else
			{
				printf("Delete operation. \n");
				cudaEventRecord(start,0);
				deleteDictionary();
				cudaEventRecord(stop,0);
				cudaEventSynchronize(stop);
				cudaEventElapsedTime(&time,start,stop);
				printf("Time taken for Deletion on GPU: %fms.\n",time/1000);		
			}
			
		}
		else if (strncmp(user_input,"showlast",8)==0)
		{
			if (numofelements==0)
			{
				printf("Can't display last 10 elements. Dictionary is empty. \n");
			}
			else if (numofelements > 0)
			{
				printf("\n-------------------------------------------------\n");
				printf("Last 10 elements of Dictionary: \n");
				int j=(size>10)?(size-10):0;
				
				printDictionary<<<1,1>>>(gpu_output_dict,j,size-1);
				errors = cudaDeviceSynchronize();
				if (errors!=cudaSuccess)
				{
					printf("Error in printing first 10 elements of array. ");
				}
				printf("\n-------------------------------------------------\n");
				
			}
			
		}
		else if (strncmp(user_input,"showfirst",9)==0)
		{
			if (numofelements==0)
			{
				printf("Can't display first 10 elements. Dictionary is empty. \n");
			}
			else if (numofelements > 0)
			{
				printf("\n-------------------------------------------------\n");
				printf("First 10 elements of Dictionary: \n");
				int start = 0;
				int end = (size<10)?size-1:9;
				printDictionary<<<1,1>>>(gpu_output_dict,start,end);
				errors = cudaDeviceSynchronize();
				if (errors!=cudaSuccess)
				{
					printf("Error in printing first 10 elements of array. ");
				}
				printf("\n-------------------------------------------------\n");
		
				}
			}
		else if (strncmp(user_input,"search",6)==0)
		{
			if (numofelements==0)
			{
				printf("Can't do search operation. Dictionary is empty. \n");
			}
			else
			{
				printf("Search operation. \n");
				cudaEventRecord(start,0);
				
				searchDictionary();
				cudaEventRecord(stop,0);
				cudaEventSynchronize(stop);
				cudaEventElapsedTime(&time,start,stop);
				printf("Time taken for Lookup operation on GPU: %fms.\n",time/1000);
			}
			
		}
		else if (strncmp(user_input,"range-search",12)==0)
		{
			if (numofelements==0)
			{
				printf("Can't do range-search operation. Dictionary is empty. \n");
			}
			else
			{
				printf("Range-Search operation. \n");
				cudaEventRecord(start,0);
				rangeQuery();
				cudaEventRecord(stop,0);
				cudaEventSynchronize(stop);
				cudaEventElapsedTime(&time,start,stop);
				printf("Time taken for Range search/Count operation on GPU: %fms.\n",time/1000);
				
			}
			
		}
		else if (strncmp(user_input,"exit",4)!=0)
		{
			printf("Invalid input. Enter valid input. \n");
			
		}	 

	
	}while(strncmp(user_input,"exit",4)!=0);
	
	errors = cudaFree(gpu_output_dict);
	
	if(errors!=cudaSuccess)
	{
		fprintf(stderr,"cudaFree failed for gpu_output_dict: %s\n",cudaGetErrorString(errors));
	}

	
	return 0;
	
}
