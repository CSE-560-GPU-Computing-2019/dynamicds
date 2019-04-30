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

//key-value pairs are also referred to as elements in this code.
//Structure for dictionary user-defined data type
//Use structure of arrays instead to use sort and merge
//Dictionary is ordered lexicographically and does not search for duplicate
//keys. It supports any number of elements to be inserted
//while executing on GPU. So it is dynamic dictionary on GPU.
//However, batch size during insertion/deletion should be less than maxelements,
//otherwise risizing would become frequent and performance would degrade.
//Key value pairs are stored in lexicographically sorted order.
typedef struct
{
	char key[SIZE];
	char value[SIZE];
	
}Dictionary;

Dictionary *gpu_output_dict;
	//desired Array of Structures on GPU of type Dictionary
	//to store key value pairs on GPU 
float runtime=0.0;

//Kernel to insert elements in existing dynamic GPU dictionary(Array of Structures)
__global__ void insertBatch(Dictionary *dictionary, Dictionary *data, int batchsize, int size)
{

	int index = blockIdx.x * blockDim.x + threadIdx.x;
	if (index<batchsize)
	{
		for (int i=0;i<SIZE;i++)
		{
			dictionary[index+size].key[i] = '\0';
		}	
		for (int i=0;i<SIZE;i++)
		{
			dictionary[index+size].value[i] = '\0';
		}
	}
	__syncthreads();
	if (index<batchsize)
	{
		for (int i=0;i<SIZE;i++)
		{
			dictionary[index+size].key[i] = data[index].key[i];
		}
		for (int i=0;i<SIZE;i++)
		{
			dictionary[index+size].value[i] = data[index].value[i];
		}	
	}
	__syncthreads();	 
}

//Kernel to print elements of the Dictionary between index start and end
__global__ void printDictionary(Dictionary *device_dictionary, int start, int end)
{
	//if (threadIx.x==0)
	for (int i=start;i<=end;i++)
	{
		printf("Key: %s \tValue: %s \n",device_dictionary[i].key,device_dictionary[i].value);
	}
}

//Kernel to copy key-value pairs of two different Dictionary Array of Structures
__global__ void copyongpu(Dictionary *dst, Dictionary *src, int batchsize)
{
	int index = blockIdx.x * blockDim.x + threadIdx.x;
		/*if (index<batchsize)
		{
			for (int i=0;i<SIZE;i++) 
			{
				dst[index].key[i]='\0';
				dst[index].value[i]='\0';
			}
		}
		__syncthreads();*/
	if (index<batchsize)
	{
		for (int i=0;i<SIZE;i++) 
		{
			dst[index].key[i] = src[index].key[i];
			dst[index].value[i] = src[index].value[i];	
		}
	
	}
	__syncthreads();

}

//Kernel to search bulk of elements in Dictionary
__global__ void searchElements(Dictionary *temp, int *index_array, char** search_arr, int num, int numofelements)
{
	
	int index = blockIdx.x * blockDim.x + threadIdx.x;
	int flag = -1;
	int tid = threadIdx.x;
	__shared__ char search_arr_shared[1024][SIZE]; 
	if (index<num)
	{
		for (int i=0;i<SIZE;i++)
		search_arr_shared[tid][i]=search_arr[index][i];
	}
	__syncthreads();
	if (index < num)
	{
		for (int i=0;i<numofelements;i++) 
			{
				flag = 0;
				for (int j=0;search_arr_shared[tid][j]!='\0';j++)
				
				{
				
					if (search_arr_shared[tid][j]!=temp[i].key[j])
						{	
							flag = 1;
							break;
						}
					
				}
				if (flag==0)
				{
					index_array[index]=i;
				}

			}
	}
	
	__syncthreads();

}

//Kernel to delete already searched elements by changing the first character of such elements in Dictionary and then eliminating them
//after sorting. Complete logic is in method deleteElements() 
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

//Comparator function to be passed to sort()
bool compareElements(const Dictionary &gpu_first_dictionary, const Dictionary &gpu_second_dictionary)
{
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
	if (compared_value<0)
		return true;
	else
		return false;
};


//Function to handle the logic for insertion of elements into dynamic dictionary on GPU
void insertData()
{	
	char input_string[35];//To take input from user
	int num=NUM;
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
	//then array of structure is resized,
	//and GPU array of structure is copied to temporary array
	//of structure and again copied back when resizing is done,
	//then insertion is done
	char *token = NULL;//Used to separate key and value inserted by user
	
		if (maxelements<num)
		{
			//batchsize should always be less than number of already allocated elements. Resizing should not be frequent.
			printf("Number of elements to be inserted should be such that resizing is done only after many batches of insertions. Please enter value < 10 million. \n");
			return;
		}
		size+=num;
		//declared as global variable, helps in deletion operation too
		//represents total no of elements after insertion
		//Insertion yet to be done
		
		loop+=1;	
		if (size>maxelements)
		{
			//resizing needed
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
				numofblocks2 = (maxelements%BLOCKSIZE==0)?(maxelements/BLOCKSIZE):(maxelements/BLOCKSIZE+1);
				blocksize2 = BLOCKSIZE;
				printf("Num of blocks %d\n",numofblocks2);
			
			copyongpu<<<numofblocks2,blocksize2>>>((Dictionary*)gpu_temp_dict,(Dictionary*)gpu_output_dict,numofelements);
			
			errors = cudaDeviceSynchronize();
			if(errors!=cudaSuccess)
			{
				fprintf(stderr,"copyongpu kernel failed for gpu_output_dict to gpu_temp_dict: %s\n",cudaGetErrorString(errors));

			}
			
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
			
			copyongpu<<<numofblocks2,blocksize2>>>((Dictionary*)gpu_output_dict,(Dictionary*)gpu_temp_dict,numofelements);
			
			errors = cudaDeviceSynchronize();
			if(errors!=cudaSuccess)
			{
				fprintf(stderr,"copyongpu kernel failed for gpu_temp_dict to gpu_output_dict copyongpu: %s\n",cudaGetErrorString(errors));
			}
			
			errors = cudaFree(gpu_temp_dict);
			if(errors!=cudaSuccess)
			{
				fprintf(stderr,"cudaFree failed for gpu_temp_dict: %s\n",cudaGetErrorString(errors));
			}

		}

		clock_t initial_time,finish_time;
		initial_time = clock();
		numofblocks = (num%BLOCKSIZE==0)?(num/BLOCKSIZE):(num/BLOCKSIZE+1);
		blocksize = BLOCKSIZE;
		Dictionary *dict = (Dictionary*)malloc(num*sizeof(Dictionary));
		for (int j=0;j<num;j++)
		{
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
			token = strtok(NULL,"-");
			strncpy(dict[j].value,token,SIZE);
			 
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
		insertBatch<<<numofblocks,blocksize>>>(gpu_output_dict,gpu_input_dict,num,numofelements);
		cudaStatus = cudaDeviceSynchronize();
		if (cudaStatus!=cudaSuccess)
		{
			fprintf(stderr,"insertBatch kernel failed: %s\n",cudaGetErrorString(cudaStatus));
		}
		finish_time = clock();
		runtime = finish_time - initial_time;
		errors = cudaFree(gpu_input_dict);
		if(errors!=cudaSuccess)
		{
			fprintf(stderr,"cudaFree failed for gpu_input_dict: %s\n",cudaGetErrorString(errors));
		}
		numofelements+=num;
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
		printf("Time taken for Insertion on GPU: %fs.\n",(float)runtime/CLOCKS_PER_SEC);	
		

}

//Function to handle the logic for search operation applied over dynamic dictionary on GPU
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
				
			}
			
			else if (num>0 && num<=5)
			{
				printf("Enter the key to search for (at most 15 characters in length): ");
				scanf("%s",input_string);	
			}
			
			strncpy(search_array[j],input_string,SIZE);
			
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
		clock_t initial_time,finish_time;
		initial_time = clock();
		cudaMemcpy(search_d_array,search_h_array,sizeof(char*)*num,cudaMemcpyHostToDevice);
		unsigned int blocksize = 0, numofblocks = 0;
		blocksize = BLOCKSIZE;
		numofblocks = (num%BLOCKSIZE==0)?(num/BLOCKSIZE):(num/BLOCKSIZE+1);
		cudaMemset(index_d,-1,sizeof(int)*num);
		searchElements<<<numofblocks,blocksize>>>(gpu_output_dict,index_d,search_d_array,num,numofelements);
		cudaDeviceSynchronize();
		finish_time = clock();
		runtime = finish_time - initial_time;
		cudaMemcpy(index_array,index_d,sizeof(int)*num,cudaMemcpyDeviceToHost);
		
		char keystring[SIZE];
		char valuestring[SIZE];
			
		for (int i=0;i<num;i++)
		{
			memset(keystring,'\0',SIZE*sizeof(char));
			memset(valuestring,'\0',SIZE*sizeof(char));
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
		printf("Time taken for Lookup on GPU: %fs.\n",(float)runtime/CLOCKS_PER_SEC);
		
		loop2+=1;
}

//Function to handle the logic for delete operation applied over dynamic dictionary on GPU
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
				
			}
			
			else if (num>0 && num<=5)
			{
				printf("Enter the key corrsponding to key-value pair to be deleted(at most 15 characters in length): ");
				scanf("%s",input_string);	
			}
			
			strncpy(search_array[j],input_string,SIZE);
			
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
		unsigned int blocksize = 0, numofblocks = 0;
		blocksize = BLOCKSIZE;
		numofblocks = (num%BLOCKSIZE==0)?(num/BLOCKSIZE):(num/BLOCKSIZE+1);
		cudaMemset(index_d,-1,sizeof(int)*num);
		clock_t initial_time,finish_time;
		initial_time = clock();
		searchElements<<<numofblocks,blocksize>>>(gpu_output_dict,index_d,search_d_array,num,numofelements);
		//Found elements would be deleted. Two step for deletion - search then if found, delete
		cudaDeviceSynchronize();
		cudaMemcpy(index_array,index_d,sizeof(int)*num,cudaMemcpyDeviceToHost);
		int count = 0;
		for (int loop=0;loop<num;loop++)
		{
			if (index_array[loop]!=-1)
				count++;
		}

		cudaError_t errors;
		deleteElements<<<numofblocks,blocksize>>>(gpu_output_dict,index_d,num);
		cudaDeviceSynchronize();
		finish_time = clock();
		runtime = finish_time - initial_time;
		
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
		printf("Time taken for Deletion on GPU: %fs.\n",(float)runtime/CLOCKS_PER_SEC);

}

//Function to handle the logic for Range Query Operation(Count+Lookup) applied over dynamic dictionary on GPU
void rangeQuery()
{
	int num=NUM;
	char input_string[SIZE];
	char **search_array = (char**)malloc(sizeof(char*)*2);
	for (int i=0;i<2;i++)
	{
		search_array[i] = (char*)malloc	(sizeof(char)*SIZE);
		memset(search_array[i],'\0',sizeof(char)*SIZE);
	}
	num = 2; //num is 2 as only two keys are provided by user
	for (int j=0;j<2;j++)
		{
			printf("Enter the key(Key must be exisitng in dictionary): ");
			scanf("%s",input_string);	
			
			strncpy(search_array[j],input_string,SIZE);
			
		}

		int *index_array = (int*)malloc(sizeof(int)*2);
		//TO store indices of elements
		int *index_d;
		cudaMalloc((void**)&index_d,sizeof(int)*2);
		char **search_d_array;
		char **search_h_array = (char**)malloc(sizeof(char*)*num);
		cudaMalloc((void**)&search_d_array,sizeof(char*)*num);
		clock_t initial_time,finish_time;
		initial_time = clock();
		cudaMemcpy(search_h_array,search_d_array,sizeof(char*)*num,cudaMemcpyDeviceToHost);
		for (int i=0;i<num;i++)
		{
			cudaMalloc((void**)&search_h_array[i],sizeof(char)*SIZE);
			cudaMemset(search_h_array[i],'\0',sizeof(char)*SIZE);
			cudaMemcpy(search_h_array[i],search_array[i],sizeof(char)*SIZE,cudaMemcpyHostToDevice);
		}
		cudaMemcpy(search_d_array,search_h_array,sizeof(char*)*num,cudaMemcpyHostToDevice);
		cudaMemset(index_d,-1,sizeof(int)*num);
		searchElements<<<1,2>>>(gpu_output_dict,index_d,search_d_array,num,numofelements);
		cudaDeviceSynchronize();
		finish_time = clock();
		runtime = finish_time - initial_time;
		cudaMemcpy(index_array,index_d,sizeof(int)*num,cudaMemcpyDeviceToHost);
		
		
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
		printf("Time taken for Range Query on GPU: %fs.\n",(float)runtime/CLOCKS_PER_SEC);
		

}

int main()
{
	cudaError_t errors;
	
	char user_input[50];
	memset(user_input,'\0',50);
	errors = cudaMalloc((void**)&gpu_output_dict,maxelements*sizeof(Dictionary));
	//float runtime=0.0;
	//clock_t initial_time,finish_time;
	if(errors!=cudaSuccess)
	{
		fprintf(stderr,"cudaMalloc failed for gpu_output_dict: %s\n",cudaGetErrorString(errors));
		return 0;
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
			
		if (strncmp(user_input,"insert",6)==0)
		{
			printf("Insert operation. \n");
			//initial_time = clock();
			insertData();
			//finish_time = clock();
			//runtime = finish_time - initial_time;
			//printf("Time taken for Insertion on GPU: %fs.\n",(float)runtime/CLOCKS_PER_SEC);
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
				//initial_time = clock();
				deleteDictionary();
				//finish_time = clock();
				//runtime = finish_time - initial_time;
				//printf("Time taken for Deletion on GPU: %fs.\n",(float)runtime/CLOCKS_PER_SEC);		
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
				//initial_time = clock();		
				searchDictionary();
				//finish_time = clock();
				//runtime = finish_time - initial_time;
				//printf("Time taken for Lookup operation on GPU: %fs.\n",(float)runtime/CLOCKS_PER_SEC);
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
				//initial_time = clock();		
				rangeQuery();
				//finish_time = clock();
				//runtime = finish_time - initial_time;
				//printf("Time taken for Range search/Count operation on GPU: %fs.\n",(float)runtime/CLOCKS_PER_SEC);
				
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
