CUDALIB = $(CUDAROOT)/lib64
CUDAINC = $(CUDAROOT)/include

lab1 : main.cu counting.o
	nvcc  -L$(CUDALIB) -I$(CUDAINC) -c main.cu -arch=sm_30 -ccbin=/usr/local/bin/g++-4.8 -std=c++11 -O2 -o main.o
	g++-4.8 -L$(CUDALIB) -I$(CUDAINC) main.o counting.o -std=c++11 -O2 -lcudart -o lab1 -lrt

counting.o : counting.cu
	nvcc  -L$(CUDALIB) -I$(CUDAINC) -c  counting.cu -arch=sm_30 -O2 -ccbin=/usr/local/bin/g++-4.8 -std=c++11 -o counting.o

lab2 : main_2.cu lab2.o
	nvcc  -L$(CUDALIB) -I$(CUDAINC) main_2.cu lab2.o -arch=sm_30 -ccbin=/usr/local/bin/g++-4.8 -std=c++11 -O2 -o lab2

lab2.o : lab2.cu
	nvcc  -L$(CUDALIB) -I$(CUDAINC) -c lab2.cu -arch=sm_30 -ccbin=/usr/local/bin/g++-4.8 -std=c++11 -O2 -o lab2.o

lab3 : main_3.cu lab3.o pgm.o
	nvcc  -L$(CUDALIB) -I$(CUDAINC) main_3.cu lab3.o pgm.o -arch=sm_30 -ccbin=/usr/local/bin/g++-4.8 -std=c++11 -O2 -o lab3

lab3.o : lab3.cu
	nvcc  -L$(CUDALIB) -I$(CUDAINC) -c lab3.cu -arch=sm_30 -ccbin=/usr/local/bin/g++-4.8 -std=c++11 -O2 -o lab3.o
pgm.o : pgm.cpp
	nvcc  -L$(CUDALIB) -I$(CUDAINC) -c pgm.cpp -arch=sm_30 -ccbin=/usr/local/bin/g++-4.8 -std=c++11 -O2 -o pgm.o