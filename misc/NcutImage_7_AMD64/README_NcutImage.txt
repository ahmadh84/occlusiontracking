%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%	       Normalized Cut Image Segmentation Code               %
%						                    %	
%  Timothee Cour (UPENN), Stella Yu (Berkeley), Jianbo Shi (UPENN)  %
%     						                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



Installation Notes :

1) After you unzipped the files to mydir, 
   put the Current Directory in Matlab to mydir

2) In the matlab command prompt,

	type demoNcutImage to see a demo

		or...
 
 	type main to initialize the paths to subfolders

3) You can now try any of the functions

The files were tested under matlab 6.5

Top level functions:

NcutImage.m: given image "I", segment it into "nbSegments" segments
    [SegLabel,NcutDiscrete,NcutEigenvectors,NcutEigenvalues,W]= NcutImage(I,nbSegments);
    
ICgraph.m: compute Intervening Contour based pixel similarity matrix W
    W = ICgraph(I);
    
ncutW.m: segmentation given similarity matrix W
    [NcutDiscrete,NcutEigenvectors,NcutEigenvalues] = ncutW(W,nbSegments);
    