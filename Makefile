# CUDA_PATH       = C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v11.2
# TRT_INC_PATH    = D:/Programs/TensorRT-8.4.3.1/include
# TRT_LIB_PATH    = D:/Programs/TensorRT-8.4.3.1/lib
# OPENCV_INC_PATH = D:/opencv4.10
# OPENCV_LIB_PATH = D:/opencv4.10/x64/vc16/lib
# INCLUDE         = -I$(CUDA_PATH)/include -I$(TRT_INC_PATH) -I$(OPENCV_INC_PATH)
# LDFLAG          = -L$(CUDA_PATH)/lib64 -lcudart -L$(TRT_LIB_PATH) -lnvinfer
# LDFLAG         += -L$(OPENCV_LIB_PATH) -lopencv_core -lopencv_imgcodecs -lopencv_imgproc

# CC = nvcc

# all: trt_infer

# trt_infer: trt_infer.cpp yololayer.cu preprocess.cu calibrator.cpp
# 	$(CC) -std=c++17 trt_infer.cpp yololayer.cu preprocess.cu calibrator.cpp -o trt_infer $(INCLUDE) $(LDFLAG) -lz

# clean:
# 	rm -rf ./trt_infer ./*.plan ./*.cache


CUDA_PATH       = C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v11.8
TRT_INC_PATH    = D:/Programs/TensorRT-8.6.1.6/include 
TRT_LIB_PATH    = D:/Programs/TensorRT-8.6.1.6/lib 
OPENCV_INC_PATH = D:/Program/opencv3.4.16/build/include 
OPENCV_LIB_PATH = D:/Program/opencv3.4.16/build/x64/vc15/lib 
 
INCLUDE         = -I"$(CUDA_PATH)/include" -I"$(TRT_INC_PATH)" -I"$(OPENCV_INC_PATH)"
LDFLAG          = -L"$(CUDA_PATH)/lib64" -lcudart -L"$(TRT_LIB_PATH)" -lnvinfer 
# LDFLAG         += -L"$(OPENCV_LIB_PATH)" -lopencv_core -lopencv_imgcodecs -lopencv_imgproc 
LDFLAG         += -L"$(OPENCV_LIB_PATH)" -lopencv_world3416 
 
CC = nvcc 
 
all: trt_infer 
 
trt_infer: trt_infer.cpp  yololayer.cu  preprocess.cu  calibrator.cpp  
	$(CC) -std=c++11 $^ -o $@ $(INCLUDE) $(LDFLAG) -lz 
 
clean:
	del /f /q trt_infer.exe  *.plan *.cache 