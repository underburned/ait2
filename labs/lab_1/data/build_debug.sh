#!/bin/sh
echo Setting env vars


export ubuntu_ver=22.04 # For docker image pulling
export cuda_ver=12-2
export cuda_distro=ubuntu2204
export cuda_arch=x86_64
export ocv_ver=4.8.0 # OpenCV version for wget, cmake configuration, install and post-install commands
export build_thread_count=14 # for make command
export image_tag=u2204_ocv480_cu122
export dockerfile=OpenCVDockerFileDebug.dockerfile

# Check if image is existed before pulling
if docker image inspect ubuntu:$ubuntu_ver 1>/dev/null; then
  echo "Docker image ubuntu:$ubuntu_ver is found."
else
  echo "Pulling docker image ubuntu:$ubuntu_ver..."
  docker pull ubuntu:$ubuntu_ver
fi

echo Building docker
docker build --no-cache-filter export-stage,test-stage --progress=plain --tag $image_tag \
             --build-arg ubuntu_ver=$ubuntu_ver \
    		 --build-arg cuda_ver=$cuda_ver \
    		 --build-arg cuda_distro=$cuda_distro \
    		 --build-arg cuda_arch=$cuda_arch \
    		 --build-arg ocv_ver=$ocv_ver \
    		 --build-arg build_thread_count=$build_thread_count \
    		 -f $dockerfile --output out .
#    		 -f $dockerfile --output out .