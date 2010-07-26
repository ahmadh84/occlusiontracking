% The make utility for all the C and MEX code

function make(command)

if (nargin > 0 && strcmp(command,'clean'))
    delete('*.mexglx');
    delete('*.mexw32');
    delete('lsmlib/*.mexglx');
    delete('lsmlib/*.mexw32');
    return;
end
mex CC=g++ DT.cpp
mex CC=g++ height_function_der.cpp
mex CC=g++ height_function_grad.cpp
mex CC=g++ local_min.cpp
mex CC=g++ zero_crossing.cpp
mex CC=g++ -lm get_full_speed.cpp
mex CC=gcc corrDn.c wrap.c convolve.c edges.c
mex CC=gcc upConv.c wrap.c convolve.c edges.c

cd lsmlib
mex CC=g++ computeDistanceFunction2d.cpp FMM_Core.cpp FMM_Heap.cpp lsm_FMM_field_extension2d.cpp
mex CC=g++ computeExtensionFields2d.cpp FMM_Core.cpp FMM_Heap.cpp lsm_FMM_field_extension2d.cpp
mex CC=g++ doHomotopicThinning.cpp FMM_Core.cpp FMM_Heap.cpp lsm_FMM_field_extension2d.cpp
cd ..