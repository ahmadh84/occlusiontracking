Implementation of Extremely Random Trees ver 1.0
************************************************

To compile with openmp (for multi core) in Visual Studio go to:
Properties -> Config Properties -> C/C++ -> Language
and set Open MP Suport to Yes (/openmp)


************************************************
Input data is seperated by a ',' each data point is on a new line. Currently, the training labels are specified as seperate rows with a 1 in the location of the associated class and a 0 everywhere else (seperated by commas).


************************************************
Two ways to run it
1) Train
e.g. 
floatForest.exe numTrees maxDepth numDimTests numThreshTest bagSize minExsAtNode ipData ipLabels testData opProb ensembleFile
floatForest.exe 10 10 10 200 25 5 C:\\TMP\\X.data C:\\TMP\\Y.data C:\\TMP\\test.data C:\\TMP\\results.data C:\\TMP\\trees.data

2) Test
floatForest.exe testData opProb ensembleFile
floatForest.exe C:\\TMP\\test.data C:\\TMP\\results.data C:\\TMP\\trees.data


************************************************
Currently very brittle, no error checking really performed. Report any bugs to:
omacaodh@cs.ucl.ac.uk