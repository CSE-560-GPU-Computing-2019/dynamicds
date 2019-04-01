//Krishna Bagaria MT18128
//Serial code implementation for Hashed Array Tree
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
int main () {
	int ** HAT;
	int n = sqrt(size);
	HAT = malloc(sizeof(int *) * n);

	int inputsize;
	printf("Enter no. of elements to be inserted: ");
	scanf("%d",&inputsize);
	
	int * input = malloc(sizeof(int) * inputsize);
	printf("Enter the elements: ");
	
	for (int i =0; i<inputsize; i++) {
		scanf("%d", &input[i]);
	}
	
	insert_tree(HAT, n , input, inputsize);
	print_tree(HAT,n);
	
	return 0;
}
