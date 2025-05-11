# NVIDIA Isaac Sim ROS 2 Docker

[简体中文](README_zh.md) | English

A comprehensive Docker image integrating NVIDIA Isaac Sim 4.5.0 with ROS 2 Humble, MobilityGen, and IsaacLab.

## Features

- **Base: NVIDIA Isaac Sim 4.5.0** - NVIDIA's advanced physics simulation platform
- **ROS 2 Humble** - Fully integrated with Isaac Sim
- **MobilityGen** - Path planning and mobility simulation frameworks
- **IsaacLab** - Robotics simulation and development environment
- **Miniconda3** - For managing Python environments

## Prerequisites

- NVIDIA GPU with compatible drivers (recommended: 525.x or newer)
- Docker and NVIDIA Container Toolkit installed
- X11 for GUI applications

## Pre-configured Elements

- Chinese package mirrors (Tsinghua) for faster downloads in China
- Custom GPU configuration for optimal performance
- Pre-installed development tools (git, vim, build essentials)
- ROS 2 environment auto-sourcing
- IsaacLab with conda environment set up

## Usage

### Building the Image

First, build the Docker image from the Dockerfile:

```bash
# Navigate to the directory containing the Dockerfile
cd /path/to/dockerfile/directory

# Build the image
docker build -t isaac-sim-ros2 .
```

### Docker Compose Deployment

1. Create a `docker-compose.yml` file with the following content:

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
      - DISPLAY=:1  # Match your host display
      - XAUTHORITY=/root/.Xauthority
      - QT_X11_NO_MITSHM=1
      - NVIDIA_DRIVER_CAPABILITIES=all,display,graphics,utility
      - NVIDIA_VISIBLE_DEVICES=all  # Or specify GPU IDs like "0,1"
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

2. Deploy with Docker Compose:

```bash
# Make sure the image is built first (if not already done)
docker build -t isaac-sim-ros2 .

# Start the container
docker-compose up -d

# Access the container shell
docker exec -it isaac_sim bash

# Stop the container
docker-compose down
```

3. For GPU selection:
   - Use `NVIDIA_VISIBLE_DEVICES=all` for all GPUs
   - Specify GPU IDs (e.g., `NVIDIA_VISIBLE_DEVICES=0,1`) to use specific GPUs

4. About the DISPLAY setting:
   - `DISPLAY=:1` connects to the host's X server display number 1
   - To find your current display number on the host, run: `echo $DISPLAY`
   - Modify the value in docker-compose.yml to match your host's display (often `:0` for primary display)
   - For remote sessions or VNC, you may need a different display number

## User Access

- Username: `isaac`
- Password: `dyy520`
- Full sudo privileges (passwordless)

## Paths

- Isaac Sim: `/home/isaac/isaac-sim`
- MobilityGen: `/home/isaac/MobilityGen`
- IsaacLab: `/home/isaac/IsaacLab`

## Using the Components

### Isaac Sim

```bash
# Start Isaac Sim in headless mode
cd /home/isaac/isaac-sim
./runheadless.sh

# Launch Isaac Sim with GUI
cd /home/isaac/isaac-sim
./isaac-sim.sh
```

### MobilityGen

```bash
# Navigate to MobilityGen path planner directory
cd /home/isaac/MobilityGen/path_planner

# Run an example
../app/python.sh run_path_planning.py
```

### IsaacLab

```bash
# Activate the IsaacLab conda environment
cd /home/isaac/IsaacLab
source ~/miniconda3/bin/activate env_isaaclab

# Run IsaacLab
./isaaclab.sh
```

### ROS 2

ROS 2 environment is automatically sourced for you.

```bash
# Verify ROS 2 installation
ros2 --help

# List available ROS 2 packages
ros2 pkg list
```

## Development Environment

The container comes with:
- C/C++ build tools
- Python development setup with pip
- Conda environment for IsaacLab
- ROS 2 Humble base installation

## Notes

- GPU memory pooling and multi-GPU support are enabled
- Custom GPU configurations are stored at `/home/isaac/.nvidia-omniverse/kit/Isaac-sim/user.config.json`

## Troubleshooting

### X11 Display Issues

If you encounter problems with the graphical interface:

```bash
# On host, allow X connections
xhost +local:docker

# Verify the correct DISPLAY value
echo $DISPLAY

# Update the DISPLAY value in docker-compose.yml accordingly
```

### GPU Problems

If GPU acceleration isn't working:

```bash
# Check GPU status inside container
nvidia-smi

# Verify NVIDIA driver compatibility
cat /proc/driver/nvidia/version
```

### Container Access Issues

If you can't access the container:

```bash
# Check container status
docker ps

# View container logs
docker logs isaac_sim

# Force restart if needed
docker-compose down
docker-compose up -d
``` 