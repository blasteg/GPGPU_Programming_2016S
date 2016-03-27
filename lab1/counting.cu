#include "counting.h"
#include <cstdio>
#include <cassert>
#include <thrust/scan.h>
#include <thrust/transform.h>
#include <thrust/functional.h>
#include <thrust/device_ptr.h>
#include <thrust/device_vector.h>
#include <thrust/sequence.h>
#include <thrust/copy.h>
#include <vector>
#include <thrust/execution_policy.h>
#include <thrust/scan.h>

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

__global__ void count_up(int* input, int* output,int text_size,int IntendedValue)
{
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	if (idx>=text_size)
		return;
	if (idx<IntendedValue || input[idx]<IntendedValue)
		output[idx]=input[idx];
	else
	{
		output[idx]=input[idx]+input[idx-IntendedValue];
	}

}

__global__ void count_which_word(int* output,int text_size,int* pos)
{
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	if (idx>=text_size)
		return;
	if (pos[idx]==1)
		output[idx]=1;
	else
		output[idx]=0;
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
	letter=letter+at_which_word[idx]*extra_offset_per_word;
	letter=letter%26;
	if (capital==1)
		text[idx]=letter+'a';
	if (capital==2)
		text[idx]=letter+'A';
}

void CountPosition(const char *text, int *pos, int text_size)
{
	int gridSize=((text_size-1)/1024)+1;

	int i;
	int IntnededValue=1;
	first_step<<<gridSize, 1024>>>(text,pos,text_size);//first step: decide which are letter which are not
	
	int *pos2;
	cudaMalloc(&pos2,sizeof(int)*text_size);
	thrust::device_ptr<int> com_pos(pos), com_pos2(pos2);
	i=0;
	while (!(thrust::equal(thrust::device,com_pos,com_pos+text_size-1,com_pos2)))
	{
		i=i+1;
		
		if (i%2)
			count_up<<<gridSize, 1024>>>(pos,pos2,text_size,IntnededValue);
		else
			count_up<<<gridSize, 1024>>>(pos2,pos,text_size,IntnededValue);
		IntnededValue=IntnededValue*2;
		
	}
	if (i%2)
		cudaMemcpy(pos,pos2,text_size*sizeof(int),cudaMemcpyDeviceToDevice);
	cudaFree(pos2);


	
}

int ExtractHead(const int *pos, int *head, int text_size)
{
	int *buffer;
	int nhead;
	cudaMalloc(&buffer, sizeof(int)*text_size*2); // this is enough
	thrust::device_ptr<const int> pos_d(pos);
	thrust::device_ptr<int> head_d(head), flag_d(buffer), cumsum_d(buffer+text_size);

	// TODO
	cudaMemcpy(buffer,pos,text_size*sizeof(int),cudaMemcpyDeviceToDevice);
	thrust::device_vector<int> indices(text_size);
	thrust::sequence(indices.begin(), indices.end());
	nhead=thrust::count(pos_d,pos_d+text_size,1);
	int nzeros=thrust::count(pos_d,pos_d+text_size,0);
	thrust::sort_by_key(flag_d, flag_d+text_size, indices.begin());
	thrust::sort(indices.begin()+nzeros, indices.begin()+nzeros+nhead);
	thrust::copy(indices.begin()+nzeros, indices.begin()+nzeros+nhead, head_d);
	//printf("%d\n",nhead);
	cudaFree(buffer);
	
	return nhead;
}

void Part3(char *text, int *pos, int *head, int text_size, int n_head)
{
	int *at_which_word;
	cudaMalloc(&at_which_word, sizeof(int)*text_size);
	thrust::device_ptr<int> at_which_word_d(at_which_word);
	int gridSize=((text_size-1)/1024)+1;
	//counting the belonging of which word
	count_which_word<<<gridSize, 1024>>>(at_which_word,text_size,pos);
	//My work : position-in-word andat-which-word dependent Caesar encoding.
	thrust::inclusive_scan(at_which_word_d, at_which_word_d+text_size, at_which_word_d);
	int base_offset=3;
	int extra_offset_per_position=1;
	int extra_offset_per_word=7;
	Caesar_shift<<<gridSize, 1024>>>(text,pos,at_which_word,text_size,base_offset,extra_offset_per_position,extra_offset_per_word);
	cudaFree(at_which_word);
}
