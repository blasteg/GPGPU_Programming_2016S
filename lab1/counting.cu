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

void CountPosition(const char *text, int *pos, int text_size)
{
	int gridSize=((text_size-1)/32)+1;
	int i;
	int IntnededValue=1;
	first_step<<<gridSize, 32>>>(text,pos,text_size);//first step: decide which are letter which are not
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
			count_up<<<gridSize, 32>>>(pos,pos2,text_size,IntnededValue,d_did_thing);
		else
			count_up<<<gridSize, 32>>>(pos2,pos,text_size,IntnededValue,d_did_thing);
		IntnededValue=IntnededValue*2;
		cudaMemcpy(&did_thing,d_did_thing,sizeof(char),cudaMemcpyDeviceToHost);
	}
	if (i%2)
		cudaMemcpy(pos,pos2,sizeof(char),cudaMemcpyDeviceToDevice);
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
	int now=0;
	while(now != text_size)
	{
	iter= thrust::find ( pos_d+now,pos_d+text_size,1);
	now=iter-pos_d;
	if (*(pos_d+now) == 1)
	heads.push_back(now);

	}
	nhead=heads.size();
	cudaFree(buffer);
	cudaMemcpy(head,heads.data(),nhead*sizeof(int),cudaMemcpyHostToDevice);
	return nhead;
}

void Part3(char *text, int *pos, int *head, int text_size, int n_head)
{
}
