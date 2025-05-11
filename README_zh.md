# NVIDIA Isaac Sim ROS 2 Docker

简体中文 | [English](README.md)

一个完整的Docker镜像，集成了NVIDIA Isaac Sim 4.5.0、ROS 2 Humble、MobilityGen和IsaacLab。

## 功能特性

- **基础：NVIDIA Isaac Sim 4.5.0** - NVIDIA先进的物理仿真平台
- **ROS 2 Humble** - 与Isaac Sim完全集成的机器人操作系统
- **MobilityGen** - 路径规划和移动仿真框架
- **IsaacLab** - 机器人仿真与开发环境
- **Miniconda3** - Python环境管理工具

## 系统要求

- NVIDIA GPU与兼容驱动（推荐：525.x或更新版本）
- 已安装Docker和NVIDIA Container Toolkit
- 支持X11图形界面

## 预置功能

- 配置清华大学镜像源，加速在中国境内的软件下载
- 针对性能优化的GPU配置
- 预装开发工具（git、vim、build-essential等）
- ROS 2环境自动加载配置
- 预配置的IsaacLab conda环境

## 使用方法

### 构建镜像

首先，从Dockerfile构建Docker镜像：

```bash
# 进入Dockerfile所在目录
cd /path/to/dockerfile/directory

# 构建镜像
docker build -t isaac-sim-ros2 .
```

### Docker Compose部署

1. 创建`docker-compose.yml`文件，内容如下：

```yaml
version: '3.8'

services:
  isaac-sim:
    container_name: isaac_sim
    image: isaac-sim-ros2
    entrypoint: bash
    stdin_open: true
    tty: true
    restart: always
    environment:
      - ACCEPT_EULA=Y
      - PRIVACY_CONSENT=Y
      - OMNI_KIT_ALLOW_ROOT=1
      - DISPLAY=:1  # 需匹配宿主机显示设置
      - XAUTHORITY=/root/.Xauthority
      - QT_X11_NO_MITSHM=1
      - NVIDIA_DRIVER_CAPABILITIES=all,display,graphics,utility
      - NVIDIA_VISIBLE_DEVICES=all  # 可指定特定GPU，如 "0,1"
      - __GLX_VENDOR_LIBRARY_NAME=nvidia
      - __GL_SHADER_DISK_CACHE=1
      - LIBGL_ALWAYS_INDIRECT=0
    network_mode: host
    runtime: nvidia
    devices:
      - "/dev/input:/dev/input:rwm"
      - "/dev/dri:/dev/dri:rwm"
    volumes:
      - /tmp/.X11-unix:/tmp/.X11-unix:rw
      - ${HOME}/.Xauthority:/root/.Xauthority:rw
```

2. 使用Docker Compose启动：

```bash
# 确保镜像已构建
docker build -t isaac-sim-ros2 .

# 启动容器
docker-compose up -d

# 进入容器shell
docker exec -it isaac_sim bash

# 停止容器
docker-compose down
```

3. GPU选择说明：
   - 使用`NVIDIA_VISIBLE_DEVICES=all`启用所有GPU
   - 使用特定GPU，如`NVIDIA_VISIBLE_DEVICES=0,1`指定使用GPU 0和1

4. 关于DISPLAY环境变量：
   - `DISPLAY=:1`表示连接到宿主机的X服务器显示1
   - 查看宿主机当前显示编号：`echo $DISPLAY`
   - 请修改docker-compose.yml中的值以匹配您的宿主机显示设置（通常主显示为`:0`）
   - 若使用远程连接或VNC，可能需要不同的显示编号设置

## 用户信息

- 用户名：`isaac`
- 密码：`dyy520`
- 拥有完整sudo权限（无需密码）

## 目录路径

- Isaac Sim：`/home/isaac/isaac-sim`
- MobilityGen：`/home/isaac/MobilityGen`
- IsaacLab：`/home/isaac/IsaacLab`

## 组件使用指南

### Isaac Sim

```bash
# 以无头模式启动Isaac Sim
cd /home/isaac/isaac-sim
./runheadless.sh

# 以图形界面模式启动Isaac Sim
cd /home/isaac/isaac-sim
./isaac-sim.sh
```

### MobilityGen

```bash
# 进入MobilityGen路径规划目录
cd /home/isaac/MobilityGen/path_planner

# 运行示例
../app/python.sh run_path_planning.py
```

### IsaacLab

```bash
# 激活IsaacLab的conda环境
cd /home/isaac/IsaacLab
source ~/miniconda3/bin/activate env_isaaclab

# 运行IsaacLab
./isaaclab.sh
```

### ROS 2

ROS 2环境已自动配置加载。

```bash
# 验证ROS 2安装
ros2 --help

# 列出可用的ROS 2软件包
ros2 pkg list
```

## 开发环境

容器包含以下开发工具：
- C/C++构建工具链
- Python开发环境与pip
- IsaacLab专用Conda环境
- ROS 2 Humble基础安装

## 注意事项

- 已启用GPU内存池化与多GPU支持
- 自定义GPU配置存储在`/home/isaac/.nvidia-omniverse/kit/Isaac-sim/user.config.json`

## 常见问题解决

### X11显示问题

如果遇到图形界面显示问题：

```bash
# 在宿主机上允许Docker容器连接X服务器
xhost +local:docker

# 确认正确的DISPLAY值
echo $DISPLAY

# 相应更新docker-compose.yml中的DISPLAY环境变量
```

### GPU问题

如果GPU加速功能不正常：

```bash
# 检查容器内GPU状态
nvidia-smi

# 验证NVIDIA驱动兼容性
cat /proc/driver/nvidia/version
```

### 容器访问问题

如果无法访问容器：

```bash
# 检查容器运行状态
docker ps

# 查看容器日志
docker logs isaac_sim

# 如需要，强制重启容器
docker-compose down
docker-compose up -d
``` 