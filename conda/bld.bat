@echo off

mkdir build
cd build

rem Need to handle Python 3.x case at some point (Visual Studio 2010)
if %ARCH%==32 (
  if %PY_VER% LSS 3 (
    set CMAKE_GENERATOR="Visual Studio 9 2008"
    set CMAKE_CONFIG="Release|Win32"
	set OPENCV_ARCH=x86
	set OPENCV_VC=vc9
  )
)
if %ARCH%==64 (
  if %PY_VER% LSS 3 (
    set CMAKE_GENERATOR="Visual Studio 9 2008 Win64"
    set CMAKE_CONFIG="Release|x64"
	set OPENCV_ARCH=x64
	set OPENCV_VC=vc9
  )
)

rem I had to take out the PNG_LIBRARY because it included
rem a Windows path which caused it to be wrongly escaped
rem and thus an error. Somehow though, CMAKE still finds
rem the correct png library...
cmake .. -G%CMAKE_GENERATOR%                        ^
    -DBUILD_TESTS=0                                 ^
    -DBUILD_DOCS=0                                  ^
    -DBUILD_PERF_TESTS=0                            ^
    -DBUILD_ZLIB=0                                  ^
    -DBUILD_TIFF=1                                  ^
    -DBUILD_PNG=0                                   ^
    -DBUILD_OPENEXR=0                               ^
    -DBUILD_JASPER=0                                ^
    -DBUILD_JPEG=0                                  ^
    -DJPEG_INCLUDE_DIR="%LIBRARY_INC%"                ^
    -DJPEG_LIBRARY="%LIBRARY_LIB%\libjpeg.lib"        ^
    -DPNG_PNG_INCLUDE_DIR="%LIBRARY_INC%"             ^
    -DZLIB_INCLUDE_DIR="%LIBRARY_INC%"                ^
    -DZLIB_LIBRARY="%LIBRARY_LIB%\zlib.lib"           ^
    -DPYTHON_EXECUTABLE="%PREFIX%\python.exe"         ^
    -DPYTHON_INCLUDE_PATH="%PREFIX%\include"          ^
    -DPYTHON_LIBRARY="%PREFIX%\libs\python27.lib"     ^
    -DPYTHON_PACKAGES_PATH="%SP_DIR%"                 ^
    -DWITH_CUDA=0                                   ^
    -DWITH_OPENCL=0                                 ^
    -DWITH_OPENNI=0                                 ^
    -DWITH_FFMPEG=0                                 ^
    -DCMAKE_INSTALL_PREFIX="%LIBRARY_PREFIX%"

cmake --build . --config %CMAKE_CONFIG% --target ALL_BUILD
cmake --build . --config %CMAKE_CONFIG% --target INSTALL

rem Let's just move the files around to a more sane structure (flat)
move "%LIBRARY_PREFIX%\%OPENCV_ARCH%\%OPENCV_VC%\bin\*.dll" "%LIBRARY_LIB%"
move "%LIBRARY_PREFIX%\%OPENCV_ARCH%\%OPENCV_VC%\bin\*.exe" "%LIBRARY_BIN%"
move "%LIBRARY_PREFIX%\%OPENCV_ARCH%\%OPENCV_VC%\lib\*.lib" "%LIBRARY_LIB%"
rmdir "%LIBRARY_PREFIX%\%OPENCV_ARCH%" /S /Q

rem By default cv.py is installed directly in site-packages
rem Therefore, we have to copy all of the dlls directly into it!
xcopy "%LIBRARY_LIB%\opencv*.dll" "%SP_DIR%"

rem We have to copy libpng.dll and zlib.dll for runtime
rem dependencies, similar to copying opencv above.
xcopy "%LIBRARY_BIN%\libpng15.dll" "%SP_DIR%"
xcopy "%LIBRARY_BIN%\zlib.dll" "%SP_DIR%"