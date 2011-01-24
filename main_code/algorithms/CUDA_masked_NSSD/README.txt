Command for building (there might be some excessive flags, it was working so i didn't touch it): 

nvcc -IC:\cuda\include "-IC:\Program Files\MATLAB_R2007a\extern\include" "-LC:\cuda\lib" "-LC:\Program Files\MATLAB_R2007a\extern\lib\win32\microsoft" "-lcudart" "-llibmx" "-llibmex" "-llibmat" -Xcompiler "/Zi /c /Zp8 /GR /W0 /EHsc- /DMATLAB_MEX_FILE /nologo /MD /Oy- /MD /Zi /Fd" -Xlinker "/DEF:NSSD.def /OUT:NSSD.mexw32 /DLL /SUBSYSTEM:WINDOWS /MACHINE:X86 " NSSD.cu

Make sure to change the include paths and library paths (right after the "-I" and "-L" switches) for the CUDA and MATLAB files as appropriate.

You might also need to have NSSD.mexw64  instead of NSSD.mexw32 for the output file. 


nvcc -IC:\apps\CUDA\include "-IC:\Program Files\MATLAB\R2007b\extern\include" "-LC:\apps\CUDA\lib" "-LC:\Program Files\MATLAB\R2007b\extern\lib\win64\microsoft" "-lcudart" "-llibmx" "-llibmex" "-llibmat" -Xcompiler "/Zi /c /Zp8 /GR /W0 /EHsc- /DMATLAB_MEX_FILE /nologo /MD /Oy- /MD /Zi /Fd" -Xlinker "/DEF:NSSD.def /OUT:NSSD.mexw64 /DLL /SUBSYSTEM:WINDOWS /MACHINE:X64 " NSSD.cu


nvcc -IC:\apps\CUDA\include "-IC:\Program Files\MATLAB\R2007b\extern\include" "-DWIN64" "-LC:\apps\CUDA\lib" "-LC:\Program Files\MATLAB\R2007b\extern\lib\win64\microsoft" "-lcudart" "-llibmx" "-llibmex" "-llibmat" -Xcompiler "/Zi /c /Zp8 /GR /W0 /EHsc- /DMATLAB_MEX_FILE /nologo /MD /Oy- /MD /Zi /Fd" -Xlinker "/DEF:NSSD.def /OUT:NSSD.mexw64 /DLL /SUBSYSTEM:WINDOWS /MACHINE:X64 /verbose" NSSD.cu




If you need to run it with debug information : 

nvcc -g -IC:\cuda\include "-IC:\Program Files\MATLAB_R2007a\extern\include" "-LC:\cuda\lib" "-LC:\Program Files\MATLAB_R2007a\extern\lib\win32\microsoft" "-lcudart" "-llibmx" "-llibmex" "-llibmat" -Xcompiler "/Zi /c /Zp8 /GR /W0 /EHsc- /DMATLAB_MEX_FILE /nologo /MD /Oy- /MD /Zi /Fd" -Xlinker "/DEF:NSSD.def /OUT:NSSD.mexw32 /DLL /SUBSYSTEM:WINDOWS /MACHINE:X86 /DEBUG /PDB:NSSD.mexw32.pdb" NSSD.cu


Note that debug info is stored only for the non-GPU code (i.e. the pure C code). The only way to actually debug the GPU code is by using the emulation mode, 

nvcc -g -deviceemu -IC:\cuda\include "-IC:\Program Files\MATLAB_R2007a\extern\include" "-LC:\cuda\lib" "-LC:\Program Files\MATLAB_R2007a\extern\lib\win32\microsoft" "-lcudart" "-llibmx" "-llibmex" "-llibmat" -Xcompiler "/Zi /c /Zp8 /GR /W0 /EHsc- /DMATLAB_MEX_FILE /nologo /MD /Oy- /MD /Zi /Fd" -Xlinker "/DEF:NSSD.def /OUT:NSSD.mexw32 /DLL /SUBSYSTEM:WINDOWS /MACHINE:X86 /DEBUG /PDB:NSSD.mexw32.pdb" NSSD.cu


In this case, however, the (emulated) threads run *serially* in the CPU, therefore any errors caused by racing problems will not be obvious (i faced this a number of times..). This is only for the really basic stuff. 

