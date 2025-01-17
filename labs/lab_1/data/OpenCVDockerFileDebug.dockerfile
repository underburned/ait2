ARG ubuntu_ver=22.04
FROM ubuntu:$ubuntu_ver AS prep-stage
# Turn off interactive input for country selection
ENV DEBIAN_FRONTEND=noninteractive
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
WORKDIR /
# Update and upgrade
RUN apt update && apt -y upgrade

# Create dir
RUN mkdir /usr/local/Dev

# Python 3
RUN apt install -y curl python3-testresources python3-dev wget gnupg2 software-properties-common
WORKDIR /usr/local/Dev/
# Valid till 22.04
RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && python3 get-pip.py

# CUDA installation

ARG cuda_ver
ARG cuda_distro
ARG cuda_arch

RUN apt -y install linux-headers-$(uname -r) build-essential
# Remove old Nvidia repo key
RUN apt-key del 7fa2af80
# Replace repo sources with mirrors
COPY ubuntu_2204_mirrors.sources /usr/local/Dev
RUN cat ubuntu_2204_mirrors.sources > /etc/apt/sources.list
# Download and install keyring from mirror
RUN wget http://mirror.yandex.ru/mirrors/developer.download.nvidia.com/compute/cuda/repos/$cuda_distro/$cuda_arch/cuda-keyring_1.1-1_all.deb
RUN dpkg -i cuda-keyring_1.1-1_all.deb
# Replace Nvidia repo source with the mirrored one
RUN echo "deb [signed-by=/usr/share/keyrings/cuda-archive-keyring.gpg] http://mirror.yandex.ru/mirrors/developer.download.nvidia.com/compute/cuda/repos/$cuda_distro/$cuda_arch/ /" > /etc/apt/sources.list.d/cuda-${cuda_distro}-x86_64.list
# Remove fectched lists from sources
RUN rm -rf /var/lib/apt/lists/*
# Get new lists
RUN apt update
# Install CUDA from mirror
RUN apt install cuda-$cuda_ver -y

# OpenCV x.x.x with non free modules

RUN echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections

# To prevent interactive configuration of tzdata
ENV TZ=Europe/Samara
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

## GStreamer

RUN apt -y install libgstreamer1.0-0 gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly gstreamer1.0-libav gstreamer1.0-tools gstreamer1.0-x gstreamer1.0-alsa \
    gstreamer1.0-gl gstreamer1.0-gtk3 gstreamer1.0-qt5 gstreamer1.0-pulseaudio && \
    apt -y install ubuntu-restricted-extras libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
    libgstreamer-plugins-bad1.0-dev libgstreamer-plugins-bad1.0-0 libgstreamer-plugins-base1.0-0 \
    libgstreamer-plugins-base1.0-dev

## OpenCV build dependencies

RUN apt -y install build-essential cmake unzip git pkg-config libgtk2.0-dev libavcodec-dev libavformat-dev \
                   libswscale-dev libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libv4l-dev \
                   libxvidcore-dev libx264-dev libgtk-3-dev libatlas-base-dev gfortran \
                   python3-dev python3-pip python3-numpy

## OpenCV

ARG ocv_ver

RUN wget -O opencv.zip https://github.com/opencv/opencv/archive/${ocv_ver}.zip
RUN wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/${ocv_ver}.zip
RUN unzip opencv.zip
RUN unzip opencv_contrib.zip

RUN apt -y install mlocate && updatedb

COPY build_env.sh /usr/local/Dev
RUN chmod +x /usr/local/Dev/build_env.sh
RUN cd /usr/local/Dev/ && ./build_env.sh

WORKDIR /usr/local/Dev/opencv-${ocv_ver}
RUN mkdir build
WORKDIR /usr/local/Dev/opencv-${ocv_ver}/build

### Update numpy
# Invalid
#RUN pip3 install -U numpy

ARG build_thread_count
ARG cmake_command

# For debug purpose
RUN echo $(apt-cache show cuda) > apt_cache_cuda.txt

RUN ln -s ${py3_np_inc_dirs}/numpy /usr/include/numpy

RUN . /usr/local/Dev/build_env.sh && cmake_command="-D CMAKE_BUILD_TYPE=RELEASE \
-D CMAKE_EXPORT_COMPILE_COMMANDS=on \
-D CMAKE_INSTALL_PREFIX=/usr/local/OpenCV-${ocv_ver} \
-D OPENCV_SKIP_PYTHON_LOADER=OFF \
-D OPENCV_PYTHON3_INSTALL_PATH=/usr/local/OpenCV-${ocv_ver}/lib/python${py3_ver_mm}/site-packages \
-D OPENCV_PYTHON3_VERSION=${py3_ver_mmm} \
-D BUILD_opencv_python2=OFF \
-D BUILD_opencv_python3=ON \
-D BUILD_opencv_python_bindings_generator=ON \
-D PYTHON_DEFAULT_EXECUTABLE=$(which python3) \
-D PYTHON3_EXECUTABLE=$(which python3) \
-D PYTHON3_INCLUDE_DIR=${py3_inc_dir} \
-D PYTHON3_PACKAGES_PATH=${py3_lib_dir} \
-D PYTHON3_LIBRARY=${py3_lib_path} \
-D PYTHON3_NUMPY_INCLUDE_DIRS=${py3_np_inc_dirs} \
-D WITH_OPENCL=ON \
-D WITH_OPENMP=ON \
-D WITH_CUDA=ON \
-D WITH_CUDNN=OFF \
-D WITH_NVCUVID=OFF \
-D WITH_CUBLAS=ON \
-D WITH_GSTREAMER=ON \
-D ENABLE_FAST_MATH=1 \
-D CUDA_FAST_MATH=1 \
-D BUILD_opencv_cudacodec=OFF \
-D INSTALL_PYTHON_EXAMPLES=ON \
-D INSTALL_C_EXAMPLES=ON \
-D OPENCV_ENABLE_NONFREE=ON \
-D OPENCV_EXTRA_MODULES_PATH=/usr/local/Dev/opencv_contrib-${ocv_ver}/modules \
-D BUILD_EXAMPLES=ON .." && echo ${cmake_command} && echo ${cmake_command} > cmake_command.txt && cmake ${cmake_command}

RUN echo $(cmake -LA .) > cmake_vars.txt
RUN echo $(sed 's/-D /\\n-D /g' cmake_command.txt) > cmake_command_splitted.txt
RUN echo $(sed 's/ /\\n/g' cmake_vars.txt) > cmake_vars_splitted.txt

FROM prep-stage AS build-stage
ARG ocv_ver
ARG ocv_build_dir=/usr/local/Dev/opencv-${ocv_ver}/build/
ARG build_thread_count
ARG py3_ver_mm

RUN make -j${build_thread_count}
# If compilation errors are present
#RUN make -j${build_thread_count}; exit 0

# test-stage is needed if build-stage failed to compile OpenCV without errors
# Modify commands to recompile OpenCV from previous stage
FROM build-stage AS test-stage
ARG ocv_build_dir=/usr/local/Dev/opencv-${ocv_ver}/build/
ARG ocv_ver
ARG py3_ver_mm
# Bogus string for NOT skipping this build stage
COPY --from=prep-stage ${ocv_build_dir}cmake_command.txt .
WORKDIR /usr/local/Dev/opencv-${ocv_ver}/build
#RUN cmake .
RUN make -j${build_thread_count}
RUN make install
RUN ldconfig
RUN . /usr/local/Dev/build_env.sh && ln -sf /usr/local/OpenCV-${ocv_ver}/lib/python${py3_ver_mm}/site-packages/cv2/python-${py3_ver_mm}/$(ls /usr/local/OpenCV-${ocv_ver}/lib/python${py3_ver_mm}/site-packages/cv2/python-${py3_ver_mm}/) /usr/local/lib/python${py3_ver_mm}/dist-packages/cv2.so
RUN echo $(python3 -c "import cv2 as cv; print(f'Compiled OpenCV version: {cv.__version__}')") > opencv_version.txt
RUN echo $(pip3 list | grep numpy) > pip3_numpy_version.txt

# WIP: small example in-place compilation with numpy include
#ARG test_code="#include <numpy/ndarrayobject.h>; int main() {return 0;}"
#ARG test_code="int main() {return 0;}"
#RUN gcc -x c++ -o tst - <<EOF
#${test_code}
#EOF

# Use only for debug with --output for files retrieving
FROM scratch AS export-stage
ARG ocv_ver
ARG ocv_build_dir=/usr/local/Dev/opencv-${ocv_ver}/build/
COPY --from=test-stage ${ocv_build_dir}cmake_command.txt .
COPY --from=prep-stage ${ocv_build_dir}cmake_command_splitted.txt .
COPY --from=prep-stage ${ocv_build_dir}cmake_vars.txt .
COPY --from=prep-stage ${ocv_build_dir}cmake_vars_splitted.txt .
COPY --from=prep-stage ${ocv_build_dir}apt_cache_cuda.txt .
COPY --from=build-stage ${ocv_build_dir}compile_commands.json .
COPY --from=test-stage ${ocv_build_dir}opencv_version.txt .
COPY --from=test-stage ${ocv_build_dir}pip3_numpy_version.txt .