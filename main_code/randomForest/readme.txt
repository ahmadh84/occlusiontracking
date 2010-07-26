In the main of predictDescriptor.cpp there are two lines of code:

// Binary op or not	
float test_error  = write_predRT( &testdata , &rtrees, opfilename);
//float test_error  = write_predRTBinary( &testdata , &rtrees, opfilename);

Depending on which one you comment out it will do multiclass or binary prediction. 

see run.bat for example
predictDescriptor noTrees noActiveVars maxDepth  minSampCount maxCategories printVarImportance trainfilename testfilename
save classififer with -s filename flag, -l for loading
e.g. predictDescriptor 100 4 30 30 25 0 -s class.xml train.data test.data prediction.data