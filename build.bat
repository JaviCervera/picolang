@echo off

echo Creating library wrapper...
cd interpreter
g++ -o a.exe gencorelib.cc core.cpp ../src/definitions.cpp ../src/generator.cpp ../src/lib.cpp ../src/parser.cpp ../src/token.cpp
a.exe
del a.exe
cd ..

echo Creating folder for CMake...
mkdir _CMAKE

echo Building...
cd _CMAKE
cmake -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE=Release ..
mingw32-make
cd ..

echo Moving to _build/bin dir...
mkdir _build\bin
move "_CMAKE\pico.exe" "_build/bin/pico.exe"

pause
