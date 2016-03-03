#include <cstdio>
#include <cstdlib>
#include "SyncedMemory.h"

#define CHECK {\
	auto e = cudaDeviceSynchronize();\
	if (e != cudaSuccess) {\
		printf("At " __FILE__ ":%d, %s\n", __LINE__, cudaGetErrorString(e));\
		abort();\
	}\
}

__global__ void SomeTransform(char *input_gpu, int fsize) {
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	int otheridx=fsize-1-idx;
	char buffer;
	if (idx>otheridx)
		return;
	if (input_gpu[idx] == '\n' || input_gpu[otheridx] != '\n')
		return;
	
	buffer=	input_gpu[idx];
	input_gpu[idx]=input_gpu[otheridx];
	input_gpu[otheridx]=buffer;
	
}

int main(int argc, char **argv)
{
	// init, and check
	if (argc != 2) {
		printf("Usage %s <input text file>\n", argv[0]);
		abort();
	}
	FILE *fp = fopen(argv[1], "r");
	if (not fp) {
		printf("Cannot open %s", argv[1]);
		abort();
	}
	// get file size
	fseek(fp, 0, SEEK_END);
	size_t fsize = ftell(fp);
	fseek(fp, 0, SEEK_SET);

	// read files
	MemoryBuffer<char> text(fsize+1);
	auto text_smem = text.CreateSync(fsize);
	CHECK;
	fread(text_smem.get_cpu_wo(), 1, fsize, fp);
	text_smem.get_cpu_wo()[fsize] = '\0';
	fclose(fp);

	// TODO: do your transform here
	char *input_gpu = text_smem.get_gpu_rw();
	int Nthreads=((fsize-1)/2)+1;
	int gridSize=((Nthreads-1)/32)+1;
	// My transform: flip the input text, except when one meets a changeline
	// Don't transform over the tail
	// And don't transform the line breaks
	SomeTransform<<<gridSize, 32>>>(input_gpu, fsize);

	puts(text_smem.get_cpu_ro());
	return 0;
}
