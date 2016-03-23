#include "counting.h"
#include <cstdio>
#include <cassert>
#include <thrust/scan.h>
#include <thrust/transform.h>
#include <thrust/functional.h>
#include <thrust/device_ptr.h>
#include <thrust/device_vector.h>
#include <vector>
#include <thrust/execution_policy.h>

__device__ __host__ int CeilDiv(int a, int b) { return (a-1)/b + 1; }
__device__ __host__ int CeilAlign(int a, int b) { return CeilDiv(a, b) * b; }

__global__ void first_step(const char* text, int* count, int text_size)
{
	int idx = blockIdx.x * blockDim.x + threadIdx.x;

	if (idx>=text_size)
		return;
	if (text[idx]>='a' && text[idx]<= 'z')
		count[idx]=1;
	else if (text[idx]>='A' && text[idx]<= 'Z')
		count[idx]=1;
	else
		count[idx]=0;
}

__global__ void count_up(int* input, int* output,int text_size,int IntendedValue,char* d_did_thing)
{
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	if (idx>=text_size)
		return;
	if (idx<IntendedValue || input[idx]<IntendedValue)
		output[idx]=input[idx];
	else
	{
		output[idx]=input[idx]+input[idx-IntendedValue];
		*d_did_thing=(bool)1;
	}

}

__global__ void count_which_word(int* input,int* output,int text_size,int* head, int now_checking)
{
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	if (idx>=text_size)
		return;
	if (idx<head[now_checking])
		output[idx]=input[idx];
	else
		output[idx]=input[idx]+1;
}

__global__ void Caesar_shift(char* text,int* pos,int* at_which_word,int text_size,int base_offset,int extra_offset_per_position,int extra_offset_per_word)
{
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	int letter,capital;
	if (idx>=text_size)
		return;
	if (text[idx]>='a' && text[idx]<= 'z')
	{
		letter=text[idx]-'a';
		capital=1;
	}
	else if (text[idx]>='A' && text[idx]<= 'Z')
	{
		letter=text[idx]-'A';
		capital=2;
	}
	else
		return;
	letter=letter+base_offset+pos[idx]*extra_offset_per_position;
	letter=letter%26;
	letter=letter++at_which_word[idx]*extra_offset_per_word;
	letter=letter%26;
	if (capital==1)
		text[idx]=letter+'a';
	if (capital==2)
		text[idx]=;etter+'A';
}

void CountPosition(const char *text, int *pos, int text_size)
{
	int gridSize=((text_size-1)/1024)+1;

	int i;
	int IntnededValue=1;
	first_step<<<gridSize, 1024>>>(text,pos,text_size);//first step: decide which are letter which are not
	char did_thing;
	char *d_did_thing;
	int *pos2;
	cudaMalloc(&d_did_thing,sizeof(char));
	cudaMalloc(&pos2,sizeof(int)*text_size);
	did_thing=1;
	i=0;
	while (did_thing)
	{
		i=i+1;
		did_thing=0;
		cudaMemcpy(d_did_thing,&did_thing,sizeof(char),cudaMemcpyHostToDevice);

		if (i%2)
			count_up<<<gridSize, 1024>>>(pos,pos2,text_size,IntnededValue,d_did_thing);
		else
			count_up<<<gridSize, 1024>>>(pos2,pos,text_size,IntnededValue,d_did_thing);
		IntnededValue=IntnededValue*2;
		
		cudaMemcpy(&did_thing,d_did_thing,sizeof(char),cudaMemcpyDeviceToHost);
		
	}
	if (i%2)
		cudaMemcpy(pos,pos2,text_size*sizeof(int),cudaMemcpyDeviceToDevice);
	cudaFree(pos2);
	cudaFree(d_did_thing);

	
}

int ExtractHead(const int *pos, int *head, int text_size)
{
	int *buffer;
	int nhead;
	cudaMalloc(&buffer, sizeof(int)*text_size*2); // this is enough
	thrust::device_ptr<const int> pos_d(pos);
	thrust::device_ptr<int> head_d(head), flag_d(buffer), cumsum_d(buffer+text_size);
	std::vector<int> heads;

	// TODO
	thrust::device_ptr<const int> iter;
	int now=-1;
	while(now != (text_size-1))
	{
	iter= thrust::find ( pos_d+now+1,pos_d+text_size-1,1);
	now=iter-pos_d;
	if (*(pos_d+now) == 1)
	heads.push_back(now);
	//printf("%d/%d\n",now,text_size);
	}
	nhead=heads.size();
	//printf("%d\n",nhead);
	cudaFree(buffer);
	cudaMemcpy(head,heads.data(),nhead*sizeof(int),cudaMemcpyHostToDevice);
	return nhead;
}

void Part3(char *text, int *pos, int *head, int text_size, int n_head)
{
	int *at_which_word, *at_which_word_buffer,i;
	cudaMalloc(&at_which_word, sizeof(int)*text_size);
	cudaMalloc(&at_which_word_buffer, sizeof(int)*text_size);
	cudaMemset (at_which_word, 0, sizeof(int)*text_size );
	cudaMemset (at_which_word_buffer, 0, sizeof(int)*text_size );

	int gridSize=((text_size-1)/1024)+1;
	//counting the belonging of which word
	for (i=0;i<n_head;i++)
	{
		if (i%2==0)
			count_which_word<<<gridSize, 1024>>>(at_which_word,at_which_word_buffer,text_size,head,i);
		else
			count_which_word<<<gridSize, 1024>>>(at_which_word_buffer,at_which_word,text_size,head,i);
	}
	if(i%2)
		cudaMemcpy(at_which_word,at_which_word_buffer,text_size*sizeof(int),cudaMemcpyDeviceToDevice);
	cudaFree(at_which_word_buffer);
	//My work : position-in-word andat-which-word dependent Caesar encoding.
	int base_offset=3;
	int extra_offset_per_position=1;
	int extra_offset_per_word=7;
	Caesar_shift<<<gridSize, 1024>>>(text,pos,at_which_word,text_size,base_offset,extra_offset_per_position,extra_offset_per_word);
}
