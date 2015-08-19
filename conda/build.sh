#!/bin/bash
mkdir build
cd build

CMAKE_GENERATOR="Unix Makefiles"
CMAKE_ARCH="-m"$ARCH

if [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
  export CFLAGS="$CFLAGS $CMAKE_ARCH"
  export LDLAGS="$LDLAGS $CMAKE_ARCH"
  DYNAMIC_EXT="so"
  TBB=""
  OPENMP="-DWITH_OPENMP=1"
  IS_OSX=0
fi
if [ "$(uname -s)" == "Darwin" ]; then
  IS_OSX=1
  DYNAMIC_EXT="dylib"
  OPENMP=""
  TBB="-DWITH_TBB=1 -DTBB_LIB_DIR=$LIBRARY_PATH -DTBB_INCLUDE_DIRS=$INCLUDE_PATH -DTBB_STDDEF_PATH=$INCLUDE_PATH/tbb/tbb_stddef.h"
fi

export CFLAGS="-I$PREFIX/include -fPIC $CFLAGS"
export LDFLAGS="-L$PREFIX/lib $LDFLAGS"

cmake .. -G"$CMAKE_GENERATOR"                                            \
    $TBB                                                                 \
    $OPENMP                                                              \
    -DWITH_EIGEN=1                                                       \
    -DBUILD_opencv_apps=0                                                \
    -DBUILD_TESTS=0                                                      \
    -DBUILD_DOCS=0                                                       \
    -DBUILD_PERF_TESTS=0                                                 \
    -DBUILD_ZLIB=1                                                       \
    -DBUILD_TIFF=1                                                       \
    -DBUILD_PNG=1                                                        \
    -DBUILD_OPENEXR=1                                                    \
    -DBUILD_JASPER=1                                                     \
    -DBUILD_JPEG=1                                                       \
    -DPYTHON_EXECUTABLE=$PREFIX/bin/python${PY_VER}                      \
    -DPYTHON_INCLUDE_PATH=$PREFIX/include/python${PY_VER}                \
    -DPYTHON_LIBRARY=$PREFIX/lib/libpython${PY_VER}.$DYNAMIC_EXT         \
    -DPYTHON_PACKAGES_PATH=$SP_DIR                                       \
    -DWITH_CUDA=0                                                        \
    -DWITH_OPENCL=0                                                      \
    -DWITH_OPENNI=0                                                      \
    -DWITH_FFMPEG=0                                                      \
    -DCMAKE_INSTALL_PREFIX=$PREFIX
make -j${CPU_COUNT}
make install

if [ $IS_OSX -eq 1 ]; then
    # Fix the lib prefix for the libraries
    # Borrowed from
    # http://answers.opencv.org/question/4134/cmake-install_name_tool-absolute-path-for-library-on-mac-osx/
    CV_LIB_PATH=$PREFIX/lib
    find ${CV_LIB_PATH} -type f -name "libopencv*.dylib" -print0 | while IFS="" read -r -d "" dylibpath; do
        echo install_name_tool -id "$dylibpath" "$dylibpath"
        install_name_tool -id "$dylibpath" "$dylibpath"
        otool -L $dylibpath | grep libopencv | tr -d ':' | while read -a libs ; do
            [ "${file}" != "${libs[0]}" ] && install_name_tool -change ${libs[0]} `basename ${libs[0]}` $dylibpath
        done
    done

    # Fix the lib prefix for the cv2.so
    # Borrowed from
    # http://answers.opencv.org/question/4134/cmake-install_name_tool-absolute-path-for-library-on-mac-osx/
    find ${SP_DIR} -type f -name "cv2.so" -print0 | while IFS="" read -r -d "" dylibpath; do
    echo install_name_tool -id "$dylibpath" "$dylibpath"
        install_name_tool -id "$dylibpath" "$dylibpath"
        otool -L $dylibpath | grep libopencv | tr -d ':' | while read -a libs ; do
            [ "${file}" != "${libs[0]}" ] && install_name_tool -change ${libs[0]} `basename ${libs[0]}` $dylibpath
        done
    done

    # Fix the lib prefix for the binaries
    # Borrowed from
    # http://answers.opencv.org/question/4134/cmake-install_name_tool-absolute-path-for-library-on-mac-osx/
    CV_BIN_PATH=$PREFIX/bin
    find ${CV_BIN_PATH} -type f -name "opencv*" -print0 | while IFS="" read -r -d "" dylibpath; do
        echo install_name_tool -id "$dylibpath" "$dylibpath"
        install_name_tool -id "$dylibpath" "$dylibpath"
        otool -L $dylibpath | grep libopencv | tr -d ':' | while read -a libs ; do
            [ "${file}" != "${libs[0]}" ] && install_name_tool -change ${libs[0]} `basename ${libs[0]}` $dylibpath
        done
    done
fi

