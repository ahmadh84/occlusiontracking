1. demo program

a) estimate_flow_demo.m can be run without arguments.  It estimates the optical flow for "RubberWhale" sequence using default parameter setting.
    uv = estimate_flow_demo;

The AAE of the estimated flow field on the gray "RubberWhale" should be around 7.2.

output UV is an M*N*2 matrix. UV(:,:,1) is the horizontal flow and UV(:,:,2) is the vertical flow.

You can download training data files other-color-twoframes.zip,  other-gray-twoframes.zip, and other-gt-flow.zip from http://vision.middlebury.edu/flow/data/ and extract within the directory 'data'. Then you can change iSequence from 1 to 12 to select the following sequences 'Venus', 'Dimetrodon',   'Hydrangea',    'RubberWhale', 'Grove2', 'Grove3', 'Urban2', 'Urban3', 'Walking', 'Beanbags',     'DogDance',     'MiniCooper'

You can change the parameter setting by providing the parameters you want to change and their values like
    uv = estimate_flow_demo(iSequence, isColor, 'lambda', 0.05, 'sigma_d', 6);
You can change the following parameters
    iSequence               number of the sequence you want to process (1-11)  {'Venus', 'Dimetrodon',   'Hydrangea',    'RubberWhale',...
                                'Grove2', 'Grove3', 'Urban2', 'Urban3', 'Walking', 'Beanbags',     'DogDance',     'MiniCooper'};
    isColor                 0 - gray image otheriwse - color image
    'lambda'                trade-off (regularization) parameter for the B&A formulation; default is 200, larger produces smoother flow fields
    'pyramid_levels'        pyramid levels for the quadratic formulation; default is 4
    'pyramid_spacing'       reduction ratio up each pyramid level for the quadratic formulation; default is 2

b) estimate_flow_hs.m computes the flow field between two input images im1 and im2 using default or input parameters.
    uv = estimate_flow_hs(im1, im2, lambda, nLevels, spacing)

You can change the parameter setting by providing the parameters you want to change and their values like
    uv = estimate_flow_ba(im1, im2, 'lambda', 200);
You can change the following parameters
    'lambda'                trade-off (regularization) parameter for the B&A formulation; default is 200, larger produces smoother flow fields
    'pyramid_levels'        pyramid levels for the quadratic formulation; default is 4
    'pyramid_spacing'       reduction ratio up each pyramid level for the quadratic formulation; default is 2


2. Display, save, and load estimated flow field.

You can 
    display the flow field using the color encoding scheme used at the middlebury website using
        imshow(uint8(flowToColor(uv))); to  

    write the computed flow to .flo files using 
        fn  = sprintf('estimated_flow.flo');
        writeFlowFile(uv, fn);

    read saved flow field (.flo) file using
        uv = readFlowFile(fn);


3. Some problems that may occur
a) Error using ==> \
Out of memory. Type HELP MEMORY for your option.

Uncomment this line in estimate_flow_demo.m
%ope.solver    = 'pcg';  

b) Error using ==> interp2
Error in    ==> utils\partial_deriv.m

Go to line 99 and 107 at utils\partial_deriv.m and follow the instructions there.

Please send other problems you encounter to dqsun@cs.brown.edu

Have fun!

Acknowledgment:
Thanks to Feng Li and Jackie Wang for pointing out problems with integer and color input images in the previous version.

Reference: 
1. Determining Optical Flow, Horn, B.K.P. & B.G. Schunck,   Artificial Intelligence, Vol. 17, No. 1-3, August 1981, pp. 185-203. (http://people.csail.mit.edu/bkph/papers/Optical_Flow_OPT.pdf)
2. A database and evaluation methodology for optical flow, Baker, S., Scharstien, D., Lewis, J. P., Roth, S., Black, M. J., Szeliski, R., Int. Conf. on Computer Vision, ICCV,  Rio de Janeiro, Brazil, October 2007. (http://vision.middlebury.edu/flow/flowEval-iccv07.pdf)