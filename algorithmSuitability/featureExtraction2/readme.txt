The algorithms folder contains the different flow algorithms. you might have trouble with FlowLib, let me know if there are any problems. FlowLib only works with .pgm files. 

Utils contains contains some functions for reading the .flo files and computing the end point error. 

1. calcflows.m computes the flow for each image
2. generateFeatureVector.m computes the feature vector
3. writeFVToTextBinary.m writes the feature vector to a text file so you can use it with the random forest classifier. 
4. readForestPredictionsBinary.m readds the results of the classifier. 