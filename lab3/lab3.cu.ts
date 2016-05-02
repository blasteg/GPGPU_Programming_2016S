#include "lab3.h"
#include <cstdio>

__device__ __host__ int CeilDiv(int a, int b) { return (a-1)/b + 1; }
__device__ __host__ int CeilAlign(int a, int b) { return CeilDiv(a, b) * b; }

__global__ void SimpleClone(
	const float *background,
	const float *target,
	const float *mask,
	float *output,
	const int wb, const int hb, const int wt, const int ht,
	const int oy, const int ox
)
{
	const int yt = blockIdx.y * blockDim.y + threadIdx.y;
	const int xt = blockIdx.x * blockDim.x + threadIdx.x;
	const int curt = wt*yt+xt;
	if (yt < ht and xt < wt and mask[curt] > 127.0f) {
		const int yb = oy+yt, xb = ox+xt;
		const int curb = wb*yb+xb;
		if (0 <= yb and yb < hb and 0 <= xb and xb < wb) {
			output[curb*3+0] = target[curt*3+0];
			output[curb*3+1] = target[curt*3+1];
			output[curb*3+2] = target[curt*3+2];
		}
	}
}



__global__ void PoissonClone(const float* background,const float* target,const float* mask,float* input,float* output,int wt,int ht,int wb,int hb,int oy, int ox,float omega)
{
int thread2Dpx = blockIdx.x * blockDim.x + threadIdx.x;
  int thread2Dpy = blockIdx.y * blockDim.y + threadIdx.y;
  if (thread2Dpx >= wt || thread2Dpy >= ht)
    return;
  int thread1Dp = wt*thread2Dpy+thread2Dpx;
  output[thread1Dp*3+0]=0;
  output[thread1Dp*3+1]=0;
  output[thread1Dp*3+2]=0;
  int yb = oy+thread2Dpy, xb = ox+thread2Dpx;
  int curb = wb*yb+xb;
  if ( mask[thread1Dp] > 127.0f)
  {
  	if (thread2Dpx!=0)
  	{

  		output[thread1Dp*3+0]+=(target[thread1Dp*3+0]-target[(thread1Dp-1)*3+0]);
  		output[thread1Dp*3+1]+=(target[thread1Dp*3+1]-target[(thread1Dp-1)*3+1]);
  		output[thread1Dp*3+2]+=(target[thread1Dp*3+2]-target[(thread1Dp-1)*3+2]);
  		if ( mask[thread1Dp-1] > 127.0f)
  		{
  			output[thread1Dp*3+0]+=input[(thread1Dp-1)*3+0];
  			output[thread1Dp*3+1]+=input[(thread1Dp-1)*3+1];
  			output[thread1Dp*3+2]+=input[(thread1Dp-1)*3+2];
  		}
  		else
  		{
  			output[thread1Dp*3+0]+=background[(curb-1)*3+0];
  			output[thread1Dp*3+1]+=background[(curb-1)*3+1];
  			output[thread1Dp*3+2]+=background[(curb-1)*3+2];
  		}
  	}
  	else
  	{
  		output[thread1Dp*3+0]+=background[(curb-1)*3+0];
  		output[thread1Dp*3+1]+=background[(curb-1)*3+1];
  		output[thread1Dp*3+2]+=background[(curb-1)*3+2];
  	}
  	if (thread2Dpx!=(wt-1))
  	{

  		output[thread1Dp*3+0]+=(target[thread1Dp*3+0]-target[(thread1Dp+1)*3+0]);
  		output[thread1Dp*3+1]+=(target[thread1Dp*3+1]-target[(thread1Dp+1)*3+1]);
  		output[thread1Dp*3+2]+=(target[thread1Dp*3+2]-target[(thread1Dp+1)*3+2]);
  		if ( mask[thread1Dp+1] > 127.0f)
  		{
  			output[thread1Dp*3+0]+=input[(thread1Dp+1)*3+0];
  			output[thread1Dp*3+1]+=input[(thread1Dp+1)*3+1];
  			output[thread1Dp*3+2]+=input[(thread1Dp+1)*3+2];
  		}
  		else
  		{
  			output[thread1Dp*3+0]+=background[(curb+1)*3+0];
  			output[thread1Dp*3+1]+=background[(curb+1)*3+1];
  			output[thread1Dp*3+2]+=background[(curb+1)*3+2];
  		}
  	}
  	else
  	{
  		output[thread1Dp*3+0]+=background[(curb+1)*3+0];
  		output[thread1Dp*3+1]+=background[(curb+1)*3+1];
  		output[thread1Dp*3+2]+=background[(curb+1)*3+2];
  	}
  	if (thread2Dpy!=0)
  	{

  		output[thread1Dp*3+0]+=(target[thread1Dp*3+0]-target[(thread1Dp-wt)*3+0]);
  		output[thread1Dp*3+1]+=(target[thread1Dp*3+1]-target[(thread1Dp-wt)*3+1]);
  		output[thread1Dp*3+2]+=(target[thread1Dp*3+2]-target[(thread1Dp-wt)*3+2]);
  		if ( mask[thread1Dp-wt] > 127.0f)
  		{
  			output[thread1Dp*3+0]+=input[(thread1Dp-wt)*3+0];
  			output[thread1Dp*3+1]+=input[(thread1Dp-wt)*3+1];
  			output[thread1Dp*3+2]+=input[(thread1Dp-wt)*3+2];
  		}
  		else
  		{
  			output[thread1Dp*3+0]+=background[(curb-wb)*3+0];
  			output[thread1Dp*3+1]+=background[(curb-wb)*3+1];
  			output[thread1Dp*3+2]+=background[(curb-wb)*3+2];
  		}
  	}
  	else
  	{
  		output[thread1Dp*3+0]+=background[(curb-wb)*3+0];
  		output[thread1Dp*3+1]+=background[(curb-wb)*3+1];
  		output[thread1Dp*3+2]+=background[(curb-wb)*3+2];
  	}
  	if (thread2Dpy!=(ht-1))
  	{

  		output[thread1Dp*3+0]+=(target[thread1Dp*3+0]-target[(thread1Dp+wt)*3+0]);
  		output[thread1Dp*3+1]+=(target[thread1Dp*3+1]-target[(thread1Dp+wt)*3+1]);
  		output[thread1Dp*3+2]+=(target[thread1Dp*3+2]-target[(thread1Dp+wt)*3+2]);
  		if ( mask[thread1Dp+wt] > 127.0f)
  		{
  			output[thread1Dp*3+0]+=input[(thread1Dp+wt)*3+0];
  			output[thread1Dp*3+1]+=input[(thread1Dp+wt)*3+1];
  			output[thread1Dp*3+2]+=input[(thread1Dp+wt)*3+2];
  		}
  		else
  		{
  			output[thread1Dp*3+0]+=background[(curb+wb)*3+0];
  			output[thread1Dp*3+1]+=background[(curb+wb)*3+1];
  			output[thread1Dp*3+2]+=background[(curb+wb)*3+2];
  		}
  	}
  	else
  	{
  		output[thread1Dp*3+0]+=background[(curb+wb)*3+0];
  		output[thread1Dp*3+1]+=background[(curb+wb)*3+1];
  		output[thread1Dp*3+2]+=background[(curb+wb)*3+2];
  	}
  	output[thread1Dp*3+0]=output[thread1Dp*3+0]/(float)4;
  	output[thread1Dp*3+1]=output[thread1Dp*3+1]/(float)4;
  	output[thread1Dp*3+2]=output[thread1Dp*3+2]/(float)4;

  	output[thread1Dp*3+0]=omega*output[thread1Dp*3+0]-(1-omega)*input[thread1Dp*3+0];
  	output[thread1Dp*3+1]=omega*output[thread1Dp*3+1]-(1-omega)*input[thread1Dp*3+1];
  	output[thread1Dp*3+2]=omega*output[thread1Dp*3+2]-(1-omega)*input[thread1Dp*3+2];
  }
}

void PoissonImageCloning(
	const float *background,
	const float *target,
	const float *mask,
	float *output,
	const int wb, const int hb, const int wt, const int ht,
	const int oy, const int ox
)
{
	cudaMemcpy(output, background, wb*hb*sizeof(float)*3, cudaMemcpyDeviceToDevice);
	const dim3 blockSize(32, 32, 1);
    const dim3 gridSize ((wt + blockSize.x - 1) / blockSize.x, (ht + blockSize.y - 1) / blockSize.y, 1);
   float *buffer1, *buffer2;

    cudaMalloc(&buffer1, 3*wt*ht*sizeof(float));
    cudaMalloc(&buffer2, 3*wt*ht*sizeof(float));
    cudaMemcpy(buffer1, target, sizeof(float)*3*wt*ht, cudaMemcpyDeviceToDevice);
   
    //cudaMemcpy(buffer1, target, sizeof(float)*3*wt*ht, cudaMemcpyDeviceToDevice);

    for (int i=0;i<10000;i++)
    {
    	PoissonClone<<<gridSize,blockSize>>>(background,target,mask,buffer1,buffer2,wt,ht, wb, hb, oy,  ox,1.1);
    	PoissonClone<<<gridSize,blockSize>>>(background,target,mask,buffer2,buffer1,wt,ht, wb, hb, oy,  ox,1.1);
    }
    cudaMemcpy(output, background, wb*hb*sizeof(float)*3, cudaMemcpyDeviceToDevice);
	SimpleClone<<<dim3(CeilDiv(wt,32), CeilDiv(ht,16)), dim3(32,16)>>>(
		background, buffer1, mask, output,
		wb, hb, wt, ht, oy, ox
	);

	cudaFree(buffer1);
	cudaFree(buffer2);
}
