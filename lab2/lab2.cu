#include "lab2.h"
#include "time.h"
#include <stdlib.h>

static const unsigned W = 640;
static const unsigned H = 480;
static const unsigned NFRAME = 10800;

int sign(int x) {
    return (x > 0) - (x < 0);
}
void init_board(int* sx, int* sy,int* x, int* y,int* lb, int* rb, int cei, int flr);
void show_boarder(uint8_t *yuv,int up, int down)
{
	cudaMemset(yuv+W*up,255,W);
	cudaMemset(yuv+W*down,255,W);
}
void show_ball(uint8_t *yuv,int x, int y)
{
	cudaMemset(yuv+W*(y-1)+x-1,255,3);
	cudaMemset(yuv+W*y+x-1,255,3);
	cudaMemset(yuv+W*(y+1)+x-1,255,3);
}
void show_bouncer(uint8_t *yuv,int left_bar_xc,int left_bar_yc,int right_bar_xc,int right_bar_yc,int bar_length_perside,int bar_thickness)
{
	int i;
	for (i=0;i<H;i++)
	{
		if (i>=left_bar_yc-bar_length_perside && i<=left_bar_yc+bar_length_perside)
			cudaMemset(yuv+W*i+left_bar_xc-bar_thickness,255,bar_thickness);
		if (i>=right_bar_yc-bar_length_perside && i<=right_bar_yc+bar_length_perside)
			cudaMemset(yuv+W*i+right_bar_xc,255,bar_thickness);
	}
}
void ball_speed_up(int* vx,int*vy)
{
	int sgnx=sign(*vx);
	int sgny=sign(*vy);
	if (rand()%4>0)
		(*vx)=(*vx)+1*sgnx;
	if (sgny!=0)
	{
		if (rand()%4>2)
			(*vy)=(*vy)+1*sgny;
	}
	else
	{
		if (rand()%4>2)
			(*vy)=(*vy)+((rand()%2)*2-1);
	}

}
void print_number(uint8_t* yuv,int print_locationx,int print_locationy,int digit) /*20x30 digit*/
{
	int i;
	switch (digit)
	{
		case 0:
		for (i=0;i<30;i++)
		{
			if (i==0 || i==1 || i==28 || i==29)
			cudaMemset(yuv+W*(print_locationy+i)+print_locationx,255,20);
			else
			{
				cudaMemset(yuv+W*(print_locationy+i)+print_locationx,255,3);
				cudaMemset(yuv+W*(print_locationy+i)+print_locationx+17,255,3);
			}
		}
		break;
		case 1:
		for (i=0;i<30;i++)
		{
				cudaMemset(yuv+W*(print_locationy+i)+print_locationx+9,255,3);	
		}
		break;
		case 2:
		for (i=0;i<30;i++)
		{
			if (i==0 || i==1 || i==28 || i==29 || i==14 || i==15)
			cudaMemset(yuv+W*(print_locationy+i)+print_locationx,255,20);
			else if (i<14)
			cudaMemset(yuv+W*(print_locationy+i)+print_locationx+17,255,3);
			else
			cudaMemset(yuv+W*(print_locationy+i)+print_locationx,255,3);
		}
		break;
		case 3:
		for (i=0;i<30;i++)
		{
			if (i==0 || i==1 || i==28 || i==29 || i==14 || i==15)
			cudaMemset(yuv+W*(print_locationy+i)+print_locationx,255,20);
			else
			cudaMemset(yuv+W*(print_locationy+i)+print_locationx+17,255,3);
		}
		break;
		case 4:
		for (i=0;i<30;i++)
		{
			if (i==14 || i==15)
			cudaMemset(yuv+W*(print_locationy+i)+print_locationx,255,20);
			else if (i<14)
			{
				cudaMemset(yuv+W*(print_locationy+i)+print_locationx,255,3);
				cudaMemset(yuv+W*(print_locationy+i)+print_locationx+17,255,3);
			}
			else
				cudaMemset(yuv+W*(print_locationy+i)+print_locationx+17,255,3);
		}
		break;
		case 5:
		for (i=0;i<30;i++)
		{
			if (i==0 || i==1 || i==28 || i==29 || i==14 || i==15)
			cudaMemset(yuv+W*(print_locationy+i)+print_locationx,255,20);
			else if (i<14)
			cudaMemset(yuv+W*(print_locationy+i)+print_locationx,255,3);
			else
			cudaMemset(yuv+W*(print_locationy+i)+print_locationx+17,255,3);
		}
		break;
		case 6:
		for (i=0;i<30;i++)
		{
			if (i==0 || i==1 || i==28 || i==29 || i==14 || i==15)
			cudaMemset(yuv+W*(print_locationy+i)+print_locationx,255,20);
			else if (i<14)
			cudaMemset(yuv+W*(print_locationy+i)+print_locationx,255,3);
			else
			{
				cudaMemset(yuv+W*(print_locationy+i)+print_locationx,255,3);
				cudaMemset(yuv+W*(print_locationy+i)+print_locationx+17,255,3);
			}
		}
		break;
		case 7:
		for (i=0;i<30;i++)
		{
			if (i==0 || i==1)
			cudaMemset(yuv+W*(print_locationy+i)+print_locationx,255,20);
			else
			cudaMemset(yuv+W*(print_locationy+i)+print_locationx+17,255,3);
		}
		break;
		case 8:
		for (i=0;i<30;i++)
		{
			if (i==0 || i==1 || i==28 || i==29|| i==14 || i==15)
			cudaMemset(yuv+W*(print_locationy+i)+print_locationx,255,20);
			else
			{
				cudaMemset(yuv+W*(print_locationy+i)+print_locationx,255,3);
				cudaMemset(yuv+W*(print_locationy+i)+print_locationx+17,255,3);
			}
		}
		break;
		case 9:
		for (i=0;i<30;i++)
		{
			if (i==0 || i==1 || i==28 || i==29|| i==14 || i==15)
			cudaMemset(yuv+W*(print_locationy+i)+print_locationx,255,20);
			else if (i<14)
			{
				cudaMemset(yuv+W*(print_locationy+i)+print_locationx,255,3);
				cudaMemset(yuv+W*(print_locationy+i)+print_locationx+17,255,3);
			}
			else
			cudaMemset(yuv+W*(print_locationy+i)+print_locationx+17,255,3);
		}
		break;
		default:
		break;
	}
}

void show_score(uint8_t *yuv,int cei, int left_score, int right_score)
{
	int print_locationx=10;
	int print_locationy=cei+5;
	int temp=left_score;
	int digit_count=1;
	while(temp/10)
	{
		digit_count+=1;
		temp/=10;
	}
	temp=left_score;
	for (int i=digit_count;i>0;i--)
	{
		print_number(yuv,print_locationx,print_locationy,temp/(pow(10,i-1)));
		temp=temp%((int)(pow(10,i-1)));
		print_locationx+=22;
	}
	temp=right_score;
	print_locationx=W-10-22;
	digit_count=1;
	while(temp/10)
	{
		digit_count+=1;
		temp/=10;
	}
	temp=right_score;
	for (int i=digit_count;i>0;i--)
	{
		print_number(yuv,print_locationx,print_locationy,temp%10);
		temp=temp/10;
		print_locationx-=22;
	}
}



struct Lab2VideoGenerator::Impl {
	int left_bar_xc=10;
	int right_bar_xc=W-10;

	int bar_length_perside=15;
	int bar_thickness=2;
	int left_score=0;
	int right_score=0;
	int ball_x=W/2;
	
	int ball_xv=0;
	int ball_yv=0;
	int ceiling=10;
	int flor=H-40;
	int left_bar_yc=(flor+ceiling)/2;
	int right_bar_yc=(flor+ceiling)/2;
	int ball_y=(flor+ceiling)/2;
	int t=0;
	int bar_max_speed=3;
	char phase='i';
};

Lab2VideoGenerator::Lab2VideoGenerator(): impl(new Impl) {
}

Lab2VideoGenerator::~Lab2VideoGenerator() {}

void Lab2VideoGenerator::get_info(Lab2VideoInfo &info) {
	info.w = W;
	info.h = H;
	info.n_frame = NFRAME;
	// fps = 24/1 = 24
	info.fps_n = 60;
	info.fps_d = 1;
};


void Lab2VideoGenerator::Generate(uint8_t *yuv) {
	cudaMemset(yuv, 0, W*H);
	cudaMemset(yuv+W*H, 128, W*H/2);
	if ((impl->phase)=='i')
	{
		init_board(&(impl->ball_xv),&(impl->ball_yv),&(impl->ball_x),&(impl->ball_y),&(impl->left_bar_yc),&(impl->right_bar_yc),(impl->ceiling),(impl->flor));
		(impl->phase)='r';
	}
	else if ((impl->phase)=='r')
	{
		if ((impl->ball_xv)>0)
		{
			int to_move=(impl->ball_y)-(impl->right_bar_yc);
			if (std::abs(to_move)>(impl->bar_max_speed))
				to_move=sign(to_move)*(impl->bar_max_speed);
			if (to_move>0 && ((impl->right_bar_yc)+(impl->bar_length_perside)+to_move)>(impl->flor))
				to_move=(impl->flor)-((impl->right_bar_yc)+(impl->bar_length_perside));
			if (to_move<0 && ((impl->right_bar_yc)-(impl->bar_length_perside)+to_move)<(impl->ceiling))
				to_move=(impl->ceiling)-((impl->right_bar_yc)-(impl->bar_length_perside));
			(impl->right_bar_yc)+=to_move;
		}
		else
		{
			int to_move=(impl->ball_y)-(impl->left_bar_yc);
			if (std::abs(to_move)>(impl->bar_max_speed))
				to_move=sign(to_move)*(impl->bar_max_speed);
			if (to_move>0 && ((impl->left_bar_yc)+(impl->bar_length_perside)+to_move)>(impl->flor))
				to_move=(impl->flor)-((impl->left_bar_yc)+(impl->bar_length_perside));
			if (to_move<0 && ((impl->left_bar_yc)-(impl->bar_length_perside)+to_move)<(impl->ceiling))
				to_move=(impl->ceiling)-((impl->left_bar_yc)-(impl->bar_length_perside));
			(impl->left_bar_yc)+=to_move;
		}
		(impl->ball_x)+=(impl->ball_xv);
		(impl->ball_y)+=(impl->ball_yv);
		if((impl->ball_y)<=(impl->ceiling))
		{
			(impl->ball_y)=(impl->ceiling)+((impl->ceiling)-(impl->ball_y))+1;
			(impl->ball_yv)=(-1)*(impl->ball_yv);
		}
		if((impl->ball_y)>=(impl->flor))
		{
			(impl->ball_y)=(impl->flor)-((impl->ball_y)-(impl->flor))-1;
			(impl->ball_yv)=(-1)*(impl->ball_yv);
		}
		if((impl->ball_x)<=(impl->left_bar_xc) && (impl->ball_y)>=(impl->left_bar_yc)-(impl->bar_length_perside) && (impl->ball_y)<=(impl->left_bar_yc)+(impl->bar_length_perside))
		{
			(impl->ball_x)=(impl->left_bar_xc)+((impl->left_bar_xc)-(impl->ball_x))+1;
			(impl->ball_xv)=(-1)*(impl->ball_xv);
			ball_speed_up(&(impl->ball_xv),&(impl->ball_yv));
		}
		if((impl->ball_x)>=(impl->right_bar_xc) && (impl->ball_y)>=(impl->right_bar_yc)-(impl->bar_length_perside) && (impl->ball_y)<=(impl->right_bar_yc)+(impl->bar_length_perside))
		{
			(impl->ball_x)=(impl->right_bar_xc)-((impl->ball_x)-(impl->right_bar_xc))-1;
			(impl->ball_xv)=(-1)*(impl->ball_xv);
			ball_speed_up(&(impl->ball_xv),&(impl->ball_yv));
		}
		if ((impl->ball_x)<=1)
		{
			(impl->ball_x)=1;
			(impl->phase)='g';
			(impl->t)=0;
		}
		if ((impl->ball_x)>=W-1)
		{
			(impl->ball_x)=W-1;
			(impl->phase)='g';
			(impl->t)=0;
		}
	}
	else if ((impl->phase)=='g')
	{
		if ((impl->t)==0)
		{
			if ((impl->ball_x)==1)
				(impl->right_score)+=1;
			if ((impl->ball_x)==(W-1))
				(impl->left_score)+=1;
		}
		if ((impl->t)%2)
		{
		cudaMemset(yuv, 255, W*H);
		cudaMemset(yuv+W*H, 128, W*H/2);
		}
		if((impl->t)==10)
			(impl->phase)='i';
		(impl->t)++;
	}
	
	show_boarder(yuv,(impl->ceiling),(impl->flor));
	show_score(yuv,(impl->flor),(impl->left_score),(impl->right_score));
	show_ball(yuv,(impl->ball_x),(impl->ball_y));
	show_bouncer(yuv,(impl->left_bar_xc),(impl->left_bar_yc),(impl->right_bar_xc),(impl->right_bar_yc),(impl->bar_length_perside),(impl->bar_thickness));
	
}




void init_board(int* sx, int* sy,int* x, int* y,int* lb, int* rb, int cei, int flr)
{
	srand(time(NULL));
	*sx=(rand()%2+1)*((rand()%2)*2-1);
	*sy=rand()%3-1;
	*x=W/2;
	*y=(flr+cei)/2;
	*lb=(flr+cei)/2;
	*rb=(flr+cei)/2;
}

