#!/bin/bash
# License: MIT. See license file in root directory
# Copyright(c) JetsonHacks (2017-2018)
# https://gist.github.com/YashasSamaga/6d37bc403c0934329b078b4bad98c7f2

OPENCV_VERSION=4.2.0
# Jetson TX2
ARCH_BIN=6.2
# Jetson TX1
# ARCH_BIN=5.3
CMAKE_VERSION=v3.16.2
INSTALL_DIR=/usr/local
# Download the opencv_extras repository
# If you are installing the opencv testdata, ie
#  OPENCV_TEST_DATA_PATH=../opencv_extra/testdata
# Make sure that you set this to YES
# Value should be YES or NO
DOWNLOAD_OPENCV_EXTRAS=YES
DOWNLOAD_OPENCV_CONTRIB=YES
# Source code directory
OPENCV_SOURCE_DIR=$HOME
WHEREAMI=$PWD

CLEANUP=true
# can turn on
PACKAGE_OPENCV=""

function usage() {
  echo "usage: ./buildOpenCV.sh [[-s sourcedir ] | [-h]]"
  echo "-s | --sourcedir   Directory in which to place the opencv sources (default $HOME)"
  echo "-i | --installdir  Directory in which to install opencv libraries (default /usr/local)"
  echo "--package  Do not package OpenCV as .deb file (default is false)"
  echo "-h | --help  This message"
}

# Iterate through command line inputs
while [ "$1" != "" ]; do
  case $1 in
  -s | --sourcedir)
    shift
    OPENCV_SOURCE_DIR=$1
    ;;
  -i | --installdir)
    shift
    INSTALL_DIR=$1
    ;;
  --package)
    PACKAGE_OPENCV="-D CPACK_BINARY_DEB=ON"
    ;;
  -h | --help)
    usage
    exit
    ;;
  *)
    usage
    exit 1
    ;;
  esac
  shift
done

CMAKE_INSTALL_PREFIX=$INSTALL_DIR

source scripts/jetson_variables.sh

# Print out the current configuration
echo -e "\033[40;31mNOTICE : Only work under bash \033[0m"
echo -e "\033[40;31mNOTICE : 国内用户请恢复官方源，加速源不含arm64 \033[0m"
echo -e "\033[40;31mNOTICE : 同时需确保可以访问raw.githubusercontent.com，网络搜索github加速 \033[0m"
echo "Build configuration: "
echo " NVIDIA Jetson $JETSON_BOARD"
echo " Operating System: $JETSON_L4T_STRING [Jetpack $JETSON_JETPACK]"
echo " Current OpenCV Installation: $JETSON_OPENCV"
echo " OpenCV binaries will be installed in: $CMAKE_INSTALL_PREFIX"
echo " OpenCV Source will be installed in: $OPENCV_SOURCE_DIR"
if [ "$PACKAGE_OPENCV" = "" ]; then
  echo " NOT Packaging OpenCV"
else
  echo " Packaging OpenCV"
fi

if [ $DOWNLOAD_OPENCV_EXTRAS == "YES" ]; then
  echo "Also installing opencv_extras"
fi

if [ $DOWNLOAD_OPENCV_CONTRIB == "YES" ]; then
  echo "Also installing opencv_contrib"
fi
read -s -n1 -p "any key to continue... "

# remove installed
echo "** Remove other OpenCV first"
sudo apt autoremove *libopencv*

# update cmake over 3.12
echo "** Remove repository cmake first for it under 3.12"
sudo apt-get autoremove cmake
# Repository setup
sudo apt-add-repository universe
sudo apt-get update

# Download dependencies for the desired configuration
cd $WHEREAMI
sudo apt-get install -y build-essential git libgtk2.0-dev libgtk-3-dev libeigen3-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev libavutil-dev libeigen3-dev libglew-dev
sudo apt-get install -y libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
sudo apt-get install -y python2.7-dev python3.6-dev python-dev python-numpy python3-numpy
sudo apt-get install -y libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libdc1394-22-dev libpostproc-dev libtiff5-dev libxvidcore-dev libx264-dev
sudo apt-get install -y libv4l-dev v4l-utils qv4l2 v4l2ucp
sudo apt-get install -y qt5-default zlib1g-dev
sudo apt-get install -y curl

# https://devtalk.nvidia.com/default/topic/1007290/jetson-tx2/building-opencv-with-opengl-support-/post/5141945/#5141945
cd /usr/local/cuda/include
sudo patch -N cuda_gl_interop.h $WHEREAMI'/patches/OpenGLHeader.patch'
# Clean up the OpenGL tegra libs that usually get crushed
# cd /usr/lib/aarch64-linux-gnu/
# sudo ln -sf tegra/libGL.so libGL.so

# Python 2.7
sudo apt-get install -y python-dev python-numpy python-py python-pytest
# Python 3.5
sudo apt-get install -y python3-dev python3-numpy python3-py python3-pytest

# GStreamer support
sudo apt-get install -y libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev

#FIX No rule to make target '/usr/lib/aarch64-linux-gnu/libGL.so
sudo apt-get --reinstall install libglvnd-dev

cmake -version
if [ $? -eq 0 ]; then
  INSTALLED_CMAKE_VERSION=$(echo $(cmake -version) | cut -f 3 -d ' ' | xargs -I {} echo -e {}"\n3.10" | sort -V | head -n 1)
  if [ "$INSTALLED_CMAKE_VERSION" != "3.10" ]; then
    INSTALL_CMAKE="true"
  else
    INSTALL_CMAKE="false"
  fi
else
  INSTALL_CMAKE="true"
fi

if [ "$INSTALL_CMAKE" = true ]; then
  cd $OPENCV_SOURCE_DIR
  wget https://git.codingcafe.org/Mirrors/Kitware/CMake/-/archive/$CMAKE_VERSION/CMake-$CMAKE_VERSION.tar.gz
  tar zxf CMake-$CMAKE_VERSION.tar.gz
  cd CMake-$CMAKE_VERSION
  ./bootstrap
  make
  make install
fi

cd $OPENCV_SOURCE_DIR
if [ ! -f "opencv-$OPENCV_VERSION.tar.gz" ]; then
  wget https://git.codingcafe.org/Mirrors/opencv/opencv/-/archive/$OPENCV_VERSION/opencv-$OPENCV_VERSION.tar.gz
fi
tar zxf opencv-$OPENCV_VERSION.tar.gz
OPENCV_DIR=opencv-$OPENCV_VERSION

if [ $DOWNLOAD_OPENCV_EXTRAS == "YES" ]; then
  echo "Installing opencv_extras"
  # This is for the test data
  cd $OPENCV_SOURCE_DIR"/"$OPENCV_DIR
  if [ ! -f "opencv_extra-$OPENCV_VERSION.tar.gz" ]; then
    wget https://git.codingcafe.org/Mirrors/opencv/opencv_extra/-/archive/$OPENCV_VERSION/opencv_extra-$OPENCV_VERSION.tar.gz
  fi
  tar zxf opencv_extra-$OPENCV_VERSION.tar.gz
fi

if [ $DOWNLOAD_OPENCV_CONTRIB == "YES" ]; then
  echo "Installing opencv_contrib"
  # This is for the test data
  cd $OPENCV_SOURCE_DIR"/"$OPENCV_DIR
  if [ ! -f "opencv_contrib-$OPENCV_VERSION.tar.gz" ]; then
    wget https://git.codingcafe.org/Mirrors/opencv/opencv_contrib/-/archive/$OPENCV_VERSION/opencv_contrib-$OPENCV_VERSION.tar.gz
  fi
  tar zxf opencv_contrib-$OPENCV_VERSION.tar.gz
fi

# Patch the Eigen library issue ...
cd $OPENCV_SOURCE_DIR"/"$OPENCV_DIR
sed -i 's/include <Eigen\/Core>/include <eigen3\/Eigen\/Core>/g' modules/core/include/opencv2/core/private.hpp

cd $OPENCV_SOURCE_DIR"/"$OPENCV_DIR
mkdir -p build
cd build

# Here are some options to install source examples and tests
#     -D INSTALL_TESTS=ON \
#     -D OPENCV_TEST_DATA_PATH=../opencv_extra/testdata \
#     -D INSTALL_C_EXAMPLES=ON \
#     -D INSTALL_PYTHON_EXAMPLES=ON \
# There are also switches which tell CMAKE to build the samples and tests
# Check OpenCV documentation for details
echo $PWD

time cmake -D CMAKE_BUILD_TYPE=RELEASE \
  -D CMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX} \
  -D WITH_CUDA=ON \
  -D CUDA_ARCH_BIN=${ARCH_BIN} \
  -D CUDA_ARCH_PTX="" \
  -D ENABLE_FAST_MATH=ON \
  -D CUDA_FAST_MATH=ON \
  -D WITH_CUBLAS=ON \
  -D WITH_LIBV4L=ON \
  -D WITH_V4L=ON \
  -D WITH_GSTREAMER=ON \
  -D WITH_GSTREAMER_0_10=OFF \
  -D WITH_QT=ON \
  -D WITH_OPENGL=ON \
  -D OPENCV_DNN_CUDA=ON \
  -D BUILD_opencv_python2=ON \
  -D BUILD_opencv_python3=ON \
  -D BUILD_TESTS=OFF \
  -D BUILD_PERF_TESTS=OFF \
  -D WITH_TBB=ON \
  -D INSTALL_TESTS=ON \
  -D INSTALL_C_EXAMPLES=ON \
  -D INSTALL_PYTHON_EXAMPLES=ON \
  -D OPENCV_EXTRA_MODULES_PATH=../opencv_contrib-$OPENCV_VERSION/modules \
  -D OPENCV_ENABLE_NONFREE=YES \
  "$PACKAGE_OPENCV" \
  ../

if [ $? -eq 0 ]; then
  echo "CMake configuration make successful"
else
  # Try to make again
  echo "CMake issues " >&2
  echo "Please check the configuration being used"
  exit 1
fi

# Consider $ sudo nvpmodel -m 2 or $ sudo nvpmodel -m 0
NUM_CPU=$(nproc)
time make -j$(($NUM_CPU - 1))
if [ $? -eq 0 ]; then
  echo "OpenCV make successful"
else
  # Try to make again; Sometimes there are issues with the build
  # because of lack of resources or concurrency issues
  echo "Make did not build " >&2
  echo "Retrying ... "
  # Single thread this time
  make
  if [ $? -eq 0 ]; then
    echo "OpenCV make successful"
  else
    # Try to make again
    echo "Make did not successfully build" >&2
    echo "Please fix issues and retry build"
    exit 1
  fi
fi

echo "Installing ... "
sudo make install
sudo ldconfig
if [ $? -eq 0 ]; then
  echo "OpenCV installed in: $CMAKE_INSTALL_PREFIX"
else
  echo "There was an issue with the final installation"
  exit 1
fi

# If PACKAGE_OPENCV is on, pack 'er up and get ready to go!
# We should still be in the build directory ...
if [ "$PACKAGE_OPENCV" != "" ]; then
  echo "Starting Packaging"
  sudo ldconfig
  time sudo make package -j$NUM_JOBS
  if [ $? -eq 0 ]; then
    echo "OpenCV make package successful"
  else
    # Try to make again; Sometimes there are issues with the build
    # because of lack of resources or concurrency issues
    echo "Make package did not build " >&2
    echo "Retrying ... "
    # Single thread this time
    sudo make package
    if [ $? -eq 0 ]; then
      echo "OpenCV make package successful"
    else
      # Try to make again
      echo "Make package did not successfully build" >&2
      echo "Please fix issues and retry build"
      exit 1
    fi
  fi
fi

# check installation
IMPORT_CHECK="$(python -c "import cv2 ; print cv2.__version__")"
if [[ $IMPORT_CHECK != *$OPENCV_VERSION* ]]; then
  echo "There was an error loading OpenCV in the Python sanity test."
  echo "The loaded version does not match the version built here."
  echo "Please check the installation."
  echo "The first check should be the PYTHONPATH environment variable."
fi

# echo 'export PYTHONPATH=$PYTHONPATH:'$PWD'/python_loader/' >> ~/.bashrc
# source ~/.bashrc
