# 0.1 基础镜像
FROM nvcr.io/nvidia/isaac-sim:4.5.0

ENV DEBIAN_FRONTEND=noninteractive

# Replace with Tsinghua mirrors
RUN sed -i 's/archive.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list && \
    sed -i 's/security.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list

# Make apt more resilient
RUN echo "Acquire::Retries \"3\";" > /etc/apt/apt.conf.d/80retries && \
    echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes && \
    echo "Acquire::http::Timeout \"10\";" > /etc/apt/apt.conf.d/99timeout && \
    echo "Acquire::https::Timeout \"10\";" >> /etc/apt/apt.conf.d/99timeout

# Create user isaac with password dyy520
RUN apt-get update && apt-get install -y sudo
RUN useradd -m isaac && echo "isaac:dyy520" | chpasswd && adduser isaac sudo

# Set up locales
RUN apt-get update && apt-get install -y locales
RUN locale-gen en_US en_US.UTF-8
RUN update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8

# Install essential packages and add repositories
RUN apt-get update && apt-get install -y gnupg wget software-properties-common
RUN add-apt-repository universe

# Set timezone to avoid interactive prompt
RUN ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    apt-get update && apt-get install -y tzdata && \
    dpkg-reconfigure --frontend noninteractive tzdata

# Install curl and add ROS key
RUN apt-get update && apt-get install -y curl wget lsb-release
RUN wget -qO - https://isaac.download.nvidia.com/isaac-ros/repos.key | apt-key add -
RUN grep -qxF "deb https://isaac.download.nvidia.com/isaac-ros/release-3 $(lsb_release -cs) release-3.0" /etc/apt/sources.list || \
    echo "deb https://isaac.download.nvidia.com/isaac-ros/release-3 $(lsb_release -cs) release-3.0" | tee -a /etc/apt/sources.list

# Add ROS key
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg

# Add ROS 2 repository
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null
RUN apt-get update

# Install ROS 2 Humble
RUN apt-get install -y --fix-broken
RUN apt-get update && apt-get install -y ros-humble-ros-base

# Note: If dependency conflicts occur with Isaac Sim packages, 
# fallback to: apt-get install -y ros-humble-ros-base

# ROS2 environment setup
RUN echo "source /opt/ros/humble/setup.bash" >> /etc/bash.bashrc
RUN echo "source /opt/ros/humble/setup.bash" >> /home/isaac/.bashrc

# Move Isaac Sim content to user's home directory
RUN mkdir -p /home/isaac/isaac-sim
RUN cp -a /isaac-sim/. /home/isaac/isaac-sim/
# RUN chown -R isaac:isaac /home/isaac/isaac-sim
# RUN chmod -R 777 /home/isaac/isaac-sim
RUN rm -rf /isaac-sim

# Add GPU configuration to avoid resource issues
RUN mkdir -p /home/isaac/.nvidia-omniverse/kit/Isaac-sim/
RUN echo '{\n\
  "renderer": {\n\
    "multiGpu": {\n\
      "enabled": true\n\
    }\n\
  },\n\
  "gpu": {\n\
    "enable_memory_pooling": true,\n\
    "nvlink_bandwidth_ratio": 0.8\n\
  }\n\
}' > /home/isaac/.nvidia-omniverse/kit/Isaac-sim/user.config.json
RUN chown -R isaac:isaac /home/isaac/.nvidia-omniverse

# Set working directory and default user
WORKDIR /home/isaac

# Install git and vim
RUN apt-get update && apt-get install -y git vim

# Install build tools and verify versions
RUN apt-get update && apt-get install -y build-essential g++ && \
    gcc --version && \
    g++ --version

# Give isaac sudo privileges without password
RUN echo "isaac ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/isaac

USER isaac

# Clone MobilityGen repository
WORKDIR /home/isaac
RUN git clone https://github.com/NVlabs/MobilityGen.git

# Enter MobilityGen and link to isaac-sim
WORKDIR /home/isaac/MobilityGen
RUN chmod +x ./link_app.sh && ./link_app.sh --path /home/isaac/isaac-sim

# Set final working directory to path_planner
WORKDIR /home/isaac/MobilityGen/path_planner

# Set correct ownership for the python directory
USER root
RUN chown -R isaac:isaac /home/isaac/MobilityGen/app/kit/python && \
    chown -R isaac:isaac /home/isaac/isaac-sim/
USER isaac

# Download and install Miniconda3
RUN mkdir -p ~/miniconda3 && \
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh && \
    bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3 && \
    rm ~/miniconda3/miniconda.sh

# Make conda available in the PATH
RUN echo 'export PATH=~/miniconda3/bin:$PATH' >> ~/.bashrc

# Root user: Create symlink to conda in system path
USER root
RUN ln -s /home/isaac/miniconda3/bin/conda /usr/local/bin/conda
USER isaac

# Initialize conda for bash shell
RUN ~/miniconda3/bin/conda init bash && \
    . ~/.bashrc

# Create .condarc with Tsinghua mirrors
# RUN echo "channels:\n  - defaults\nshow_channel_urls: true\ndefault_channels:\n  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main\n  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/r\n  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/msys2\ncustom_channels:\n  conda-forge: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud\n  pytorch: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud" > ~/.condarc

# 安装基础插件
RUN ../app/python.sh -m pip config set global.index-url https://mirrors.aliyun.com/pypi/simple
RUN ../app/python.sh -m pip install --upgrade pip

# Install pybind11
RUN ../app/python.sh -m pip install pybind11

# Create pyproject.toml file
RUN echo '[build-system]\nrequires = ["setuptools>=64", "wheel", "pybind11"]\nbuild-backend = "setuptools.build_meta"' > /home/isaac/MobilityGen/path_planner/pyproject.toml

# Install the package in editable mode
RUN ../app/python.sh -m pip install -e . --use-pep517 --config-settings editable_mode=compat

# Install tqdm
RUN ../app/python.sh -m pip install tqdm

# Install gradio
RUN ../app/python.sh -m pip install gradio

WORKDIR /home/isaac

# 安装isaac lab - 第1步: 克隆代码库
RUN git clone https://github.com/isaac-sim/IsaacLab.git 

# 安装isaac lab - 第2步: 创建软链接
RUN cd IsaacLab && \
    ln -s /home/isaac/isaac-sim _isaac_sim && \
    chmod +x ./isaaclab.sh

# 安装isaac lab - 第3步: 运行conda安装
RUN cd IsaacLab && \
    export TERM=xterm && \
    export ISAACSIM_PATH="/home/isaac/isaac-sim" && \
    export ISAACSIM_PYTHON_EXE="${ISAACSIM_PATH}/python.sh" && \
    ./isaaclab.sh --conda

# 设置shell为bash
SHELL ["/bin/bash", "-c"]

# 安装isaac lab - 第4步: 安装rsl_rl
RUN cd IsaacLab && \
    export TERM=xterm && \
    export PATH=/home/isaac/miniconda3/bin:$PATH && \
    source /home/isaac/miniconda3/bin/activate env_isaaclab && \
    ./isaaclab.sh --install rsl_rl

WORKDIR /home/isaac

