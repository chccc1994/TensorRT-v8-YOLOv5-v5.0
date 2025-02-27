# TensorRT v8.2 加速部署 YOLOv5-v5.0

## 项目简介

- 使用 `TensorRT` 原生`API`构建 `YOLO` 网络，将 `PyTorch` 模型转为`.plan` 序列化文件，加速模型推理；
- 基于 `TensorRT 8.2.4` 版本，具体环境见下方的环境构建部分；
- 主要参考 [tensorrtx](https://github.com/wang-xinyu/tensorrtx) 项目，但作者本人根据自己编程习惯，做了大量改动；
- 未使用Cuda加速图像预处理的项目链接：[no_cuda_preproc](https://github.com/emptysoal/TensorRT-v8-YOLOv5-v5.0/tree/cpp-preproc)

![](samples/_002.jpeg)

## 项目特点

- 这里对比和 `tensorrtx` 项目中 `YOLOv5-v5.0` 的不同，并不是说孰优孰劣，只是有些地方更符合作者个人习惯

|      | tensorrtx                                       | 本项目                                   | 备注                                         |
| ---- | ----------------------------------------------- | ---------------------------------------- | -------------------------------------------- |
| 1    | implicit（隐式 batch）                          | explicit（显式 batch）                   | 此不同为最大的不同，代码中很多的差异都源于此 |
| 2    | Detect Plugin 继承自 IPluginV2IOExt             | Detect Plugin 继承自 IPluginV2DynamicExt |                                              |
| 3    | Detect Plugin 被编译为动态链接库                | Detect Plugin 直接编译到最终的可执行文件 |                                              |
| 4    | 异步推理（context.enqueue）                     | 同步推理（context.executeV2）            | 作者亲测在速度方面无差别，同步写法更简便     |
| 5    | INT8量化时，采用OpenCV的dnn模块将图像转换为张量 | INT8量化时，自定义的方法将图像转换为张量 |                                            |
| 6    | C++加opencv实现预处理                           | cuda编程实现预处理加速                   | v5.0之后的版本也有，两种不同的实现           |

除上述外，还有很多其他编码上的不同，不一一赘述。

## 推理速度

- 基于GPU：GeForce RTX 2080 Ti

| FP32  | FP16 | INT8 |
| :---: | :--: | :--: |
| 6 ms | 3 ms | 3 ms |

备注：本项目的推理时间包括：预处理、前向传播、后处理，tensorrtx 项目仅计算了前向传播时间。

## 环境构建

### 宿主机基础环境

- Ubuntu 16.04
- GPU：GeForce RTX 2080 Ti
- docker，nvidia-docker

### 基础镜像拉取

```bash
docker pull nvcr.io/nvidia/tensorrt:22.04-py3
```

- 该镜像中各种环境版本如下：

|  CUDA  |  cuDNN   | TensorRT | python |
| :----: | :------: | :------: | :----: |
| 11.6.2 | 8.4.0.27 | 8.2.4.2  | 3.8.10 |

### 安装其他库

1. 创建 docker 容器

   ```bash
   docker run -it --gpus device=0 --shm-size 32G -v /home:/workspace nvcr.io/nvidia/tensorrt:22.04-py3 bash
   ```

   其中`-v /home:/workspace`将宿主机的`/home`目录挂载到容器中，方便一些文件的交互，也可以选择其他目录

   - 将容器的源换成国内源

   ```bash
   cd /etc/apt
   rm sources.list
   vim sources.list
   ```

   - 将下面内容拷贝到文件sources.list

   ```bash
   deb http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse
   deb http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse
   deb http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse
   deb http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse
   deb http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
   deb-src http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse
   deb-src http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse
   deb-src http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse
   deb-src http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse
   deb-src http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
   ```

   - 更新源

   ```bash
   apt update
   ```

2. 安装 OpenCV-4.5.0

   - OpenCV-4.5.0源码链接如下，下载 zip 包，解压后放到宿主机`/home`目录下，即容器的`/workspace`目录下

   ```bash
   https://github.com/opencv/opencv
   ```

   - 下面操作均在容器中

   ```bash
   # 安装依赖
   apt install build-essential
   apt install libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev
   apt install libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libdc1394-22-dev
   # 开始安装 OpenCV
   cd /workspace/opencv-4.5.0
   mkdir build
   cd build
   cmake -D CMAKE_INSTALL_PREFIX=/usr/local -D CMAKE_BUILD_TYPE=Release -D OPENCV_GENERATE_PKGCONFIG=ON -D OPENCV_ENABLE_NONFREE=True ..
   make -j6
   make install
   ```

## 运行项目

1. 获取 `.wts` 文件

- 主要过程为：把本项目的`pth2wts.py`文件复制到官方`yolov5-v5.0`目录下，在官方`yolov5-v5.0`目录下运行 `python pth2wts.py`，得到`para.wts`文件
- 具体过程可参考下面步骤

```bash
# 下载YOLOv5
# git clone -b v5.0 https://github.com/ultralytics/yolov5.git 分支不存在
# windows平台
wget https://github.com/ultralytics/yolov5/archive/refs/tags/v5.0.zip
# Linux 平台
# wget https://github.com/ultralytics/yolov5/archive/refs/tags/v5.0.tar.gz

# 下载项目TensorRT-v8-YOLOv5-v5.0
git clone https://github.com/emptysoal/TensorRT-v8-YOLOv5-v5.0.git

# 下载yolov5s.pt 需要注意yolov5s.pt来源 一定是/v5.0/yolov5s.pt
# download https://github.com/ultralytics/yolov5/releases/download/v5.0/yolov5s.pt
# 文件目录
# ├─ TensorRT-v8-YOLOv5-v5.0
# └─ yolov5

cp ./TensorRT-v8-YOLOv5-v5.0/pth2wts.py ./yolov5
cd yolov5
python pth2wts.py
# a file 'para.wts' will be generated.
```

2. 构建 `.plan` 序列化文件并推理
> 在执行完 ./trt_infer 自动生成`model.plan`.


- 主要过程为：把上一步生成的`para.wts`文件复制到本项目目录下，在本项目中依次运行`make`和`./trt_infer`，自动生成`model.plan`
- 具体过程可参考下面步骤

```bash
cp ./yolov5/para.wts ./TensorRT-v8-YOLOv5-v5.0/
cd TensorRT-v8-YOLOv5-v5.0/
mkdir images  # and put some images in it
# update CLASS_NUM in yololayer.h if your model is trained on custom dataset
# you can also update INPUT_H、INPUT_W in yololayer.h, update NET(s/m/l/x) in trt_infer.cpp
# 执行编译
make 
# 运行
./trt_infer
# result images will be generated in present dir
```

