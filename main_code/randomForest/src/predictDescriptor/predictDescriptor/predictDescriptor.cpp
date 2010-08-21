#include "ml.h"
#include <stdio.h>
#include <fstream>

using namespace std;

/*
The sample demonstrates how to use different decision trees.
*/
void print_result(float train_err, float test_err, const CvMat* var_imp)
{    
       
    if (var_imp)
    {
        bool is_flt = false;
        if ( CV_MAT_TYPE( var_imp->type ) == CV_32FC1)
            is_flt = true;
        printf( "variable importance\n" );
        for( int i = 0; i < var_imp->cols; i++)
        {
            printf( "%d     %f\n", i, is_flt ? var_imp->data.fl[i] : var_imp->data.db[i] );
        }
    }
    printf( "train err  %f %%\t", train_err );
    printf( "test err   %f %%\n", test_err );
}


float write_predRT( CvMLData* _data , CvRTrees* _rtrees, char* filename)
{
	
    float err = 0;
    const CvMat* values = _data->get_values();
    const CvMat* response = _data->get_responses();
    const CvMat* missing = _data->get_missing();
    const CvMat* sample_idx = _data->get_train_sample_idx();
    const CvMat* var_types = _data->get_var_types();
    int* sidx = sample_idx ? sample_idx->data.i : 0;
    int r_step = CV_IS_MAT_CONT(response->type) ? 1 : response->step / CV_ELEM_SIZE(response->type);

	string seq  = filename;	

    int sample_count = sample_idx ? sample_idx->cols : 0;
	
    sample_count = values->rows;
    float* pred_resp = 0;

	// write result to text file
	//char predictions_filename[200] = "results_";
	//strcat(predictions_filename, filename);
	//char predictions_filename[200] = "results.data";
	ofstream predictions;
	predictions.open(filename);

	int norm = 0;
	double epeTot = 0;
	for( int i = 0; i < sample_count; i++ )
    {
		CvMat sample, miss;
		int si = sidx ? sidx[i] : i;
        cvGetRow( values, &sample, si ); 
		if( missing ) 
			cvGetRow( missing, &miss, si );             
		float r = (float)_rtrees->predict( &sample, missing ? &miss : 0 );
		if( pred_resp )
			pred_resp[i] = r;
		int d = fabs((double)r - response->data.fl[si*r_step]) <= FLT_EPSILON ? 0 : 1;
        err += d;

		predictions << r << endl;

	}
    err = sample_count ? err / (float)sample_count * 100 : -FLT_MAX;
	predictions.close();
    return err;
}

float write_predRTBinary( CvMLData* _data , CvRTrees* _rtrees, char* filename)
{
	
    float err = 0;
    const CvMat* values = _data->get_values();
    const CvMat* response = _data->get_responses();
    const CvMat* missing = _data->get_missing();
    const CvMat* sample_idx = _data->get_train_sample_idx();
    const CvMat* var_types = _data->get_var_types();
    int* sidx = sample_idx ? sample_idx->data.i : 0;
    int r_step = CV_IS_MAT_CONT(response->type) ? 1 : response->step / CV_ELEM_SIZE(response->type);

	string seq  = filename;	

    int sample_count = sample_idx ? sample_idx->cols : 0;
	
    sample_count = values->rows;
    float* pred_resp = 0;

	// write result to text file
	//char predictions_filename[200] = "results_";
	//strcat(predictions_filename, filename);
	//char predictions_filename[200] = "results.data";
	ofstream predictions;
	predictions.open(filename);

	int norm = 0;
	double epeTot = 0;
	for( int i = 0; i < sample_count; i++ )
    {
		CvMat sample, miss;
		int si = sidx ? sidx[i] : i;
        cvGetRow( values, &sample, si ); 
		if( missing ) 
			cvGetRow( missing, &miss, si );             
		float r = (float)_rtrees->predict_prob( &sample, missing ? &miss : 0 );
		if( pred_resp )
			pred_resp[i] = cvRound(r);
		int d = fabs((double)cvRound(r) - response->data.fl[si*r_step]) <= FLT_EPSILON ? 0 : 1;
        err += d;

		predictions << r << endl;

	}
    err = sample_count ? err / (float)sample_count * 100 : -FLT_MAX;
	predictions.close();
    return err;
}

void printUsage()
{
	printf("Usage: \n");
	printf("Training + Testing:\n> predictDescriptor  t a d s c v  trainfpath testfpath outfpath\n\n");
	printf("Training + Testing + Saving classifier (XML):\n> predictDescriptor  t a d s c v  -s xmlfpath trainfpath testfpath outfpath\n\n");
	printf("Training + Testing + Saving classifier (XML) (binary labelling):\n> predictDescriptor  t a d s c v  -s xmlfpath trainfpath testfpath outfpath  -b\n\n");
	printf("Training + Saving classifier (XML):\n> predictDescriptor  t a d s c v  -s xmlfpath trainfpath\n\n");
	printf("Testing from saved classifier (XML):\n> predictDescriptor -l xmlfpath testfpath outfpath\n\n");
	printf("Testing from saved classifier (XML) (binary labelling):\n> predictDescriptor -l xmlfpath testfpath outfpath  -b\n\n");

	printf("t=noTrees, a=noActiveVars, d=maxDepth, s=minSampCount, c=maxCategories, v=computeVarImportance\n\n");

	printf("Flags: \n-s filename: save classifier output as XML\n");
	printf("-l filename: load XML classifier\n");
	printf("-b: indicate (at testing) that the labelling was binary\n");

	printf("\n\ne.g.\n(1) Train, Test, Save XML in one go\n> predictDescriptor 100 4 30 30 25 0 -s class.xml train.data tst.data pred.data\n");
	printf("\n(2) Train and Save XML; then Test using XML (binary labelling)\n> predictDescriptor 100 4 30 30 25 0 -s class.xml train.data\n");
	printf("> predictDescriptor  -l class.xml test.data prediction.data  -b\n");

	printf("\n\nNote:\n(1) All input *.data files given as CSVs with a row for each data point; 1st value is the label; all the rest are feature values.\n");
	printf("(2) If any filepath contains spaces, enclose the path in \"\".\n");
}


int main(int argc, char *argv[])
{
	CvRTrees rtrees;
    CvERTrees ertrees;

    CvMLData traindata;
	CvMLData testdata;

	char* trainfilename = 0;
	char* testfilename = 0;
	char* opfilename = 0;
	char* filename_to_save = 0;
    char* filename_to_load = 0;

	bool testing = false;
	bool training = false;
	bool labelling_binary = false;
	float test_error = -1.0;
	float train_error = -1.0;

	int nTrees = 100;
	int nActiveVars = 4;
	int maxDepth = 30;
	int minSampCount = 25;
	int maxCategories = 30;
	bool printImportance = false;

	//load params
	int i = 1;

	// Parsing arguments
	try
	{
		if( strcmp(argv[i],"-l") == 0 ) {
			i++;
			filename_to_load = argv[i++];

			testfilename = argv[i++];
			opfilename = argv[i++];
		}
		else
		{
			nTrees = atoi(argv[i++]);
			nActiveVars = atoi(argv[i++]);
			maxDepth = atoi(argv[i++]);
			minSampCount = atoi(argv[i++]);
			maxCategories = atoi(argv[i++]);		
			printImportance = bool(atoi(argv[i++]));

			if( strcmp(argv[i],"-s") == 0 ) {
				i++;
				filename_to_save = argv[i++];
			}
			else if(strcmp(argv[i],"-l") == 0) {
				throw("Can't load XML while training!");
			}

			trainfilename = argv[i++];

			if(argc-1 >= i && strcmp(argv[i],"-b") != 0)
				testfilename = argv[i++];
			if(argc-1 >= i && strcmp(argv[i],"-b") != 0)
				opfilename = argv[i++];
		}

		labelling_binary = argc-1 >= i && strcmp(argv[i],"-b") == 0;
	}
	catch(char* err_str)
	{
		cerr<<"Error while parsing arguments: "<<err_str<<endl<<endl<<endl;
		printUsage();
		return 2;
	}

	int train_out = 1;
	int test_out = 1;

	if( trainfilename )
		train_out = traindata.read_csv( trainfilename );
	if( testfilename )
		test_out = testdata.read_csv( testfilename );

	// (1) Train OR load XML
	// (2)

	// do training
    if(train_out == 0 || test_out == 0)
    {
		if( filename_to_load )
		{
			// Load Random Trees classifier

			// load classifier from the specified file
			rtrees.load( filename_to_load );
			if( rtrees.get_tree_count() == 0 )
			{
				printf("Could not read the classifier \n");
				return -1;
			}
		}
		else
		{
			// Use the data for Training the Random Forest

			traindata.set_response_idx( 0 );
			traindata.change_var_type( 0 , CV_VAR_CATEGORICAL );

			// parameters
			CvMat sample;
			cvGetRow( traindata.get_values(), &sample, 1 );
			if (nActiveVars > (int)sample.cols-2)
				nActiveVars = (int)sample.cols-2;

			rtrees.train( &traindata, CvRTParams(maxDepth,minSampCount,0,false,maxCategories,0,printImportance,nActiveVars,nTrees,0.0001f,CV_TERMCRIT_ITER));
			//Prams: maxdepth, min sample count, regression acc, use surrogates, max categories, priors, calc var importance, nactive vars, 
			//max no trees, forest accuracy, termcrit type

			train_error = rtrees.calc_error(&traindata, CV_TRAIN_ERROR);
		}

		// if there is data to test on
		if( opfilename )
		{
			testdata.set_response_idx( 0 );
			testdata.change_var_type( 0 , CV_VAR_CATEGORICAL );
			
			// Binary op or not
			if( labelling_binary )
				test_error = write_predRTBinary( &testdata , &rtrees, opfilename);
			else
				test_error = write_predRT( &testdata , &rtrees, opfilename);
		}
		
		print_result(train_error, test_error, rtrees.get_var_importance());

		// Save Random Trees classifier to file if needed
		if( filename_to_save )
			rtrees.save( filename_to_save );
        
    }
	else {
		cerr<<"OpenCV doesn't like one of yours files!"<<endl<<endl<<endl;
		printUsage();
		return 3;
	}

    return 0;
}