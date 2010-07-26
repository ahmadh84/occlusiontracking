1. demo program

a) estimate_flow_demo.m can be run without arguments.  It estimates the optical flow for "RubberWhale" sequence using default parameter setting.
    uv = estimate_flow_demo;

The AAE of the estimated flow field on the gray "RubberWhale" should be around 5.94.

You can download training data files other-color-twoframes.zip,  other-gray-twoframes.zip, and other-gt-flow.zip from http://vision.middlebury.edu/flow/data/ and extract within the directory 'data'. Then you can change iSequence from 1 to 12 to select the following sequences 'Venus', 'Dimetrodon',   'Hydrangea',    'RubberWhale', 'Grove2', 'Grove3', 'Urban2', 'Urban3', 'Walking', 'Beanbags',     'DogDance',     'MiniCooper'

You can change the parameter setting by providing the parameters you want to change and their values like
    uv = estimate_flow_demo(iSequence, isColor, 'lambda', 0.05, 'sigma_d', 6);
You can change the following parameters
    iSequence               number of the sequence you want to process (1-11)  {'Venus', 'Dimetrodon',   'Hydrangea',    'RubberWhale',...
                                'Grove2', 'Grove3', 'Urban2', 'Urban3', 'Walking', 'Beanbags',     'DogDance',     'MiniCooper'};
    isColor                 0 - gray image otheriwse - color image

    'lambda'                trade-off (regularization) parameter for the B&A formulation; default is 0.1, larger produces smoother flow fields
    'lambda_q'              trade-off (regularization) parameter for the quadratic formulation used in the GNC optimization; default is 0.05
    'sigma_d'               parameter of the Lorentzian robust penalty function for the spatial term
    'sigma_s'               parameter of the Lorentzian robust penalty function for the data term
    'pyramid_levels'        pyramid levels for the quadratic formulation; default is 4
    'pyramid_spacing'       reduction ratio up each pyramid level for the quadratic formulation; default is 2
    'gnc_pyramid_levels'    pyramid levels for the B&A formulation; default is 2
    'gnc_pyramid_spacing'   reduction ratio up each pyramid level for the B&A formulation; default is 1.25

output UV is an M*N*2 matrix. UV(:,:,1) is the horizontal flow and UV(:,:,2) is the vertical flow.

b) estimate_flow_ba.m computes the flow field between two input images im1 and im2 using default or input parameters.
    uv = estimate_flow_ba(im1, im2);

You can change the parameter setting by providing the parameters you want to change and their values like
    uv = estimate_flow_ba(im1, im2, 'lambda', 0.05, 'sigma_d', 6);
You can change the following parameters
    'lambda'                trade-off (regularization) parameter for the B&A formulation; default is 0.1, larger produces smoother flow fields
    'lambda_q'              trade-off (regularization) parameter for the quadratic formulation used in the GNC optimization; default is 0.05
    'sigma_d'               parameter of the Lorentzian robust penalty function for the spatial term
    'sigma_s'               parameter of the Lorentzian robust penalty function for the data term
    'pyramid_levels'        pyramid levels for the quadratic formulation; default is 4
    'pyramid_spacing'       reduction ratio up each pyramid level for the quadratic formulation; default is 2
    'gnc_pyramid_levels'    pyramid levels for the B&A formulation; default is 2
    'gnc_pyramid_spacing'   reduction ratio up each pyramid level for the B&A formulation; default is 1.25


2. Display, save, and load estimated flow field.

You can 
display the flow field using the color encoding scheme used at the middlebury website using
    imshow(uint8(flowToColor(uv)));  

write the computed flow to .flo files using 
    fn  = sprintf('estimated_flow.flo');
    writeFlowFile(uv, fn);  

read saved flow field (.flo) file using
    uv = readFlowFile(fn);

3. Some problems that may occur
a) 

Error using ==> \
Out of memory. Type HELP MEMORY for your option.

Uncomment this line in estimate_flow_demo.m
%ope.solver    = 'pcg';  

b) 

Error using ==> interp2
Error in    ==> utils\partial_deriv.m

Go to line 99 and 107 at utils\partial_deriv.m and follow the instructions there.

Please send other problems you encounter to dqsun@cs.brown.edu 

Have fun!

Acknowledgment:
Thanks to Feng Li and Jackie Wang for pointing out problems with integer and color input images in the previous version.

Reference: 
1. The robust estimation of multiple motions: Parametric and piecewise-smooth flow fields, Black, M. J. and Anandan, P., Computer Vision and Image Understanding, CVIU, 63(1), pp. 75-104, Jan. 1996. (http://www.cs.brown.edu/~black/Papers/cviu.63.1.1996.html)
2. A database and evaluation methodology for optical flow, Baker, S., Scharstien, D., Lewis, J. P., Roth, S., Black, M. J., Szeliski, R., Int. Conf. on Computer Vision, ICCV,  Rio de Janeiro, Brazil, October 2007. (http://vision.middlebury.edu/flow/flowEval-iccv07.pdf)
3. Learning Optical Flow, Deqing Sun, Stefan Roth, J.P. Lewis, and Michael J. Black  In Proc. of the European Conference on Computer Vision (ECCV), Oct. 2008. (http://www.cs.brown.edu/~dqsun/pubs/eccv2008.pdf). The Graduated non-convexity (GNC) scheme used in this implementation is described in section 5.