#!/bin/bash
# switch opencv version
function usage() {
	echo "usage: sudo ./switchOpenCV.sh [[-v Version ] | [-h]]"
	echo "-v | --version  The version switch to"
	echo "-h | --help  This message"
}

case $1 in
-v | --version)
	shift
	OPENCV_VERSION=$1
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

INSTALL_DIR=/usr/local/opencv/$OPENCV_VERSION
CMAKE_INSTALL_PREFIX=$INSTALL_DIR
OPENCV_SOURCE_DIR=$HOME
cd $OPENCV_SOURCE_DIR"/""opencv-"$OPENCV_VERSION"/build"
if [ ${OPENCV_VERSION:0:1} = 4 ]; then
	# copy .pc file
	sudo cp unix-install/opencv4.pc $CMAKE_INSTALL_PREFIX"/lib/pkgconfig/"
	export PKG_CONFIG_PATH=$CMAKE_INSTALL_PREFIX"/lib/pkgconfig"
	export LD_LIBRARY_PATH=$CMAKE_INSTALL_PREFIX"/lib"
	pkg-config --modversion opencv4
	sudo ldconfig
	sudo rm -f /usr/local/lib/python2.7/dist-packages/cv2
	sudo rm -f /usr/local/lib/python3.6/dist-packages/cv2
	sudo ln -ds $CMAKE_INSTALL_PREFIX"/lib/python2.7/dist-packages/cv2" /usr/local/lib/python2.7/dist-packages/cv2
	sudo ln -ds $CMAKE_INSTALL_PREFIX"/lib/python3.6/dist-packages/cv2" /usr/local/lib/python3.6/dist-packages/cv2
elif [ ${OPENCV_VERSION:0:1} = 3 ]; then
	sudo cp unix-install/opencv.pc $CMAKE_INSTALL_PREFIX"/lib/pkgconfig/"
	export PKG_CONFIG_PATH=$CMAKE_INSTALL_PREFIX"/lib/pkgconfig"
	export LD_LIBRARY_PATH=$CMAKE_INSTALL_PREFIX"/lib"
	pkg-config --modversion opencv
	sudo ldconfig
	sudo rm -f /usr/local/lib/python2.7/dist-packages/cv2
	sudo rm -f /usr/local/lib/python3.6/dist-packages/cv2
	sudo cp $CMAKE_INSTALL_PREFIX/lib/python2.7/dist-packages/cv2.so /usr/local/lib/python2.7/dist-packages/
	sudo cp $CMAKE_INSTALL_PREFIX/lib/python3.6/dist-packages/cv2.cpython-36m-aarch64-linux-gnu.so /usr/local/lib/python3.6/dist-packages/
fi
