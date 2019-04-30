//MT18145(Shubham Kumar)
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <algorithm>
#include<ctime>
#define NUM 16
#define SIZE 16
#define MAXE 10000000
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
//while executing on CPU. So it is dynamic dictionary on CPU.
//However, batch size during insertion/deletion should be less than maxelements,
//otherwise risizing would become frequent and performance would degrade.
//Key value pairs are stored in lexicographically sorted order.

typedef struct
{
	char key[SIZE];
	char value[SIZE];
	
}Dictionary;

Dictionary *cpu_output_dict;
	//desired Array of Structures on CPU of type Dictionary
	//to store key value pairs on CPU 	

void printDictionaryOnCPU(Dictionary *host_dictionary, int start, int end)
{
	for (int i=start;i<=end;i++)
	{
		printf("Key: %s \tValue: %s \n",host_dictionary[i].key,host_dictionary[i].value);
	}
}

void searchElementsOnCPU(Dictionary *temp, int *index_array, char** search_arr, int num, int numofelements)
{
	
	int flag[num];
		for (int k=0;k<num;k++) 
			{
				for (int i=0;i<numofelements;i++)
				{
					flag[k] = 0;
				
					for (int j=0;search_arr[k][j]!='\0';j++)
					
					{
						
						if (search_arr[k][j]!=temp[i].key[j])
							{	
								flag[k] = 1;
								break;
							}
						
					}
					if (flag[k]==0)
					{
						index_array[k]=i;
						
					}
				
				}
				
				
			}

}

void deleteElementsOnCPU(Dictionary *temp, int *index_array, int num)
{
	
	for (int i=0;i<num;i++)
		{
			int temp_index = index_array[i];

			if (temp_index!=-1)
			{
				temp[temp_index].key[0]='{';
				temp[temp_index].value[0]='$';
			}
		}
	

}


bool compareElements(const Dictionary &cpu_first_dictionary, const Dictionary &cpu_second_dictionary)
{
	//if (strncmp(*gpu_first_dictionary.value,*gpu_second_dictionary.value)!=0)
	//int comparebits = 15;
	int compared_value = 0;
	for (int k=0;k<SIZE;k++)
	{
		if (cpu_first_dictionary.key[k]<cpu_second_dictionary.key[k])
		{
			compared_value  = -1;
			break;
		}
		else if (cpu_first_dictionary.key[k]>cpu_second_dictionary.key[k])
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
	//unsigned int blocksize, numofblocks; //blocksize, numofblocks are used for kernel launch
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
			Dictionary *cpu_temp_dict = (Dictionary*)malloc(maxelements*sizeof(Dictionary));
			//Array of Structures of type Dictionary
			//to store elements temporarily so that 
			//gpu_output_dict can be resized
			
			//errors = cudaMalloc((void**)&gpu_temp_dict,maxelements*sizeof(Dictionary));
			/*if(errors!=cudaSuccess)
			{
				fprintf(stderr,"cudaMalloc failed for gpu_temp_dict: %s\n",cudaGetErrorString(errors));
			}
			*/
			for (int j=0;j<maxelements;j++)
			{
			//limit on word length of key and value <= 100 characters
				memset(cpu_temp_dict[j].key,'\0',sizeof(cpu_temp_dict[j].key));
				memset(cpu_temp_dict[j].value,'\0',sizeof(cpu_temp_dict[j].value));
			 
			}
			for (int j=0;j<numofelements;j++)
			{
				//cpu_temp_dict[j] = cpu_output_dict[j];
				memcpy(cpu_temp_dict[j].key,cpu_output_dict[j].key,sizeof(cpu_temp_dict[j].key));
				memcpy(cpu_temp_dict[j].value,cpu_output_dict[j].value,sizeof(cpu_temp_dict[j].value));
				
			}
			//copyongpu<<<numofblocks2,blocksize2>>>((Dictionary*)gpu_temp_dict,(Dictionary*)gpu_output_dict,numofelements);
			
			free(cpu_output_dict);
			cpu_output_dict = (Dictionary*)malloc(sizeof(Dictionary)*maxelements);
			for (int j=0;j<maxelements;j++)
			{
			//limit on word length of key and value <= 100 characters
				memset(cpu_output_dict[j].key,'\0',sizeof(cpu_output_dict[j].key));
				memset(cpu_output_dict[j].value,'\0',sizeof(cpu_output_dict[j].value));
			 
			}
			for (int j=0;j<numofelements;j++)
			{
				memcpy(cpu_output_dict[j].key,cpu_temp_dict[j].key,sizeof(cpu_output_dict[j].key));
				memcpy(cpu_output_dict[j].value,cpu_temp_dict[j].value,sizeof(cpu_output_dict[j].value));
				//cpu_output_dict[j] = cpu_temp_dict[j];
				//memcpy((void*)cpu_output_dict[j],(void*)cpu_temp_dict[j],sizeof(Dictionary));
			}
			free(cpu_temp_dict);

		}
		
		Dictionary *dict = (Dictionary*)malloc(num*sizeof(Dictionary));
		for (int j=0;j<num;j++)
		{//limit on word length of key and value <= 100 characters
		//	printf("Enter key and value separated by - : ");
			
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
			
		}
		int k = 0;
		for (int j=0;j<num;j++)
		{
			k = j+numofelements;
			//cpu_output_dict[k]=dict[j];
			memcpy(cpu_output_dict[k].key,dict[j].key,sizeof(cpu_output_dict[k].key));
			memcpy(cpu_output_dict[k].value,dict[j].value,sizeof(cpu_output_dict[k].value));
			//memcpy((void*)cpu_output_dict[k],(void*)dict[j],sizeof(Dictionary));
		}
		/*printf("Elements in dictionary: \n");
		for (int j=0;j<size;j++)
		{
			//printf("Key: %s, Value: %s\n",dict[j].key,cpu_output_dict[j].value);
			printf("Key: %s, Value: %s\n",dict[j].key,cpu_output_dict[j].value);
		}*/
		free(dict);
		numofelements+=num;
		std::sort(cpu_output_dict,cpu_output_dict+numofelements,compareElements);

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
		
		//unsigned int blocksize = 0, numofblocks = 0;
		//blocksize = BLOCKSIZE;
		//numofblocks = (num%BLOCKSIZE==0)?(num/BLOCKSIZE):(num/BLOCKSIZE+1);
		//locksize = 1, numofblocks = 1;
		//for (int element = 0;element<num;element++)
		memset(index_array,-1,sizeof(int)*num);
		
		searchElementsOnCPU(cpu_output_dict,index_array,search_array,num,numofelements);
		//errors = 
		
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
				memcpy(keystring,cpu_output_dict[index_array[i]].key,sizeof(char)*SIZE);
				memcpy(valuestring,cpu_output_dict[index_array[i]].value,sizeof(char)*SIZE);
				printf("Key: %s, Value: %s\n",keystring,valuestring);
			
			}
			else
			{
				memcpy(keystring,search_array[i],sizeof(char)*SIZE);
				printf("Key-Value does not exist for Queried Key: %s\n",keystring);
			}
		}
		for (int i=0;i<num;i++)
			free(search_array[i]);
		free(search_array);
		free(index_array);
		loop2+=1;
}

void deleteDictionary()
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
		
		//unsigned int blocksize = 0, numofblocks = 0;
		//blocksize = BLOCKSIZE;
		//numofblocks = (num%BLOCKSIZE==0)?(num/BLOCKSIZE):(num/BLOCKSIZE+1);
		//locksize = 1, numofblocks = 1;
		//for (int element = 0;element<num;element++)
		memset(index_array,-1,sizeof(int)*num);
		
		searchElementsOnCPU(cpu_output_dict,index_array,search_array,num,numofelements);
		//errors = 

		int count = 0;
		for (int i=0;i<num;i++)
		{
			if (index_array[i]!=-1)
				count++;
		}

		deleteElementsOnCPU(cpu_output_dict,index_array,num);
		for (int i=0;i<num;i++)
			free(search_array[i]);
		free(search_array);
		free(index_array);
		loop2+=1;

		std::sort(cpu_output_dict,cpu_output_dict+numofelements,compareElements);
		
		printf("Found key-value pairs Deleted. \n");
		numofelements = numofelements - count;
		size = size - count;

		loop2+=1;
}

void rangeQuery()
{
	int num=NUM;
	num = 2;
	char input_string[SIZE];
	char **search_array = (char**)malloc(sizeof(char*)*num);
	for (int i=0;i<num;i++)
	{
		search_array[i] = (char*)malloc	(sizeof(char)*SIZE);
		memset(search_array[i],'\0',sizeof(char)*SIZE);
	}
	//memset(search_array,'\0',sizeof(char)*num*SIZE);
		
	
		int *index_array = (int*)malloc(sizeof(int)*num);
		//TO store indices of elements
		
		//unsigned int blocksize = 0, numofblocks = 0;
		//blocksize = BLOCKSIZE;
		//numofblocks = (num%BLOCKSIZE==0)?(num/BLOCKSIZE):(num/BLOCKSIZE+1);
		//locksize = 1, numofblocks = 1;
		//for (int element = 0;element<num;element++)
		memset(index_array,-1,sizeof(int)*num);

		for (int j=0;j<2;j++)
		{
			printf("Enter the key(Key must be exisitng in dictionary): ");
			scanf("%s",input_string);	
			
			strncpy(search_array[j],input_string,SIZE);
			//printf("Search array: %s. \n",search_array[j]);
		}	
		
		searchElementsOnCPU(cpu_output_dict,index_array,search_array,num,numofelements);
		//errors = 
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
		int start = index_array[0],end = index_array[1];

		printDictionaryOnCPU(cpu_output_dict,start,end);
		//char keystring[SIZE];
		//char valuestring[SIZE];
		//cudaError_t errors;
		//printDictionary<<<numofblocks,blocksize>>>(gpu_output_dict,index_d,num);
		
		for (int i=0;i<num;i++)
			free(search_array[i]);
		free(search_array);
		free(index_array);
		
}

int main()
{
	//int num = NUM;
	//num represents number of elements user wants to enter
	//in any iteration
	char user_input[50];
	memset(user_input,'\0',50);
	float runtime=0.0;
	clock_t initial_time,finish_time;
	cpu_output_dict = (Dictionary*)malloc(sizeof(Dictionary)*maxelements);
	if (cpu_output_dict==NULL)
	{
		printf("Allocation failed for cpu_output_dict.\n");
		return 0;
	}
	for (int j=0;j<maxelements;j++)
	{
		memset(cpu_output_dict[j].key,'\0',sizeof(cpu_output_dict[j].key));
		memset(cpu_output_dict[j].value,'\0',sizeof(cpu_output_dict[j].value));
		
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
			initial_time = clock();
			insertData();
			finish_time = clock();
			runtime = finish_time - initial_time;
			printf("Time taken for Insertion on CPU: %fs.\n",(float)runtime/CLOCKS_PER_SEC);
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
				initial_time = clock();
				deleteDictionary();
				finish_time = clock();
				runtime = finish_time - initial_time;
				printf("Time taken for Deletion on CPU: %fs.\n",(float)runtime/CLOCKS_PER_SEC);		
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
				
				printDictionaryOnCPU(cpu_output_dict,j,size-1);
				
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
				printDictionaryOnCPU(cpu_output_dict,start,end);
				
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
				initial_time = clock();		
				searchDictionary();
				finish_time = clock();
				runtime = finish_time - initial_time;
				printf("Time taken for Lookup operation on CPU: %fs.\n",(float)runtime/CLOCKS_PER_SEC);
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
				initial_time = clock();		
				rangeQuery();
				finish_time = clock();
				runtime = finish_time - initial_time;
				printf("Time taken for Range search/Count operation on CPU: %fs.\n",(float)runtime/CLOCKS_PER_SEC);
				
			}
			
		}
		else if (strncmp(user_input,"exit",4)!=0)
		{
			printf("Invalid input. Enter valid input. \n");
			
		}	 

	
	}while(strncmp(user_input,"exit",4)!=0);
	
	free(cpu_output_dict);

	
	return 0;
	
}
