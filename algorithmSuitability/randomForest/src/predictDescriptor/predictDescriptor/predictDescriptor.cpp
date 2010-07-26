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

int main(int argc, char *argv[])
{
	CvRTrees rtrees;
    CvERTrees ertrees;

    CvMLData traindata;
	CvMLData testdata;

	char* trainfilename = "";
	char* testfilename = "";
	char* opfilename = "";
	char* filename_to_save = 0;
    char* filename_to_load = 0;

	int nTrees = 100;
	int nActiveVars = 4;
	int maxDepth = 30;
	int minSampCount = 25;
	int maxCategories = 30;
	bool printImportance = false;

	//load params
	int noArgs = 12;
	int i = 7;

	nTrees = atoi(argv[1]);
	nActiveVars = atoi(argv[2]);
	maxDepth = atoi(argv[3]);
	minSampCount = atoi(argv[4]);
	maxCategories = atoi(argv[5]);		
	printImportance = bool(atoi(argv[6]));
		
	if( strcmp(argv[7],"-l") == 0 ) {
		filename_to_load = argv[8];
		i = i+2;
	}
	else if( strcmp(argv[7],"-s") == 0 ) {
		filename_to_save = argv[8];
		i = i+2;
	}
	
	trainfilename = argv[i];
	testfilename = argv[i+1];
	opfilename = argv[i+2];
	
	// do training
    if ( traindata.read_csv( trainfilename ) == 0 | testdata.read_csv( testfilename ) == 0)
    {			
		traindata.set_response_idx( 0 );     
		traindata.change_var_type( 0 , CV_VAR_CATEGORICAL );

		// parameters
		CvMat sample;
		cvGetRow( traindata.get_values(), &sample, 1 ); 			
		if (nActiveVars > sample.cols)
			nActiveVars = (int)sample.cols-1;
	
		//Load Random Trees classifier
		if( filename_to_load )
		{
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
			rtrees.train( &traindata, CvRTParams(maxDepth,minSampCount,0,false,maxCategories,0,printImportance,nActiveVars,nTrees,0.0001f,CV_TERMCRIT_ITER));
			//Prams: maxdepth, min sample count, regression acc, use surrogates, max categories, priors, calc var importance, nactive vars, 
			//max no trees, forest accuracy, termcrit type
		}

		testdata.set_response_idx( 0 );     
		testdata.change_var_type( 0 , CV_VAR_CATEGORICAL );
		
		// Binary op or not
		float test_error;
		if( argc-1 >= i+3 && strcmp(argv[i+3],"-b") == 0 )
			test_error = write_predRTBinary( &testdata , &rtrees, opfilename);
		else
			test_error = write_predRT( &testdata , &rtrees, opfilename);
		


		print_result( rtrees.calc_error( &traindata, CV_TRAIN_ERROR), test_error, rtrees.get_var_importance());

		// Save Random Trees classifier to file if needed
		if( filename_to_save )
			rtrees.save( filename_to_save );
        
    }
	else {
        printf("One of the files cannot be read or not enough arguments\n\n");
		printf("predictDescriptor noTrees noActiveVars maxDepth  minSampCount maxCategories printVarImportance trainfilename testfilename\n\n");
		printf("save classififer with -s filename flag, -l for loading\n");
		printf("e.g. predictDescriptor 100 4 30 30 25 0 -s class.xml train.data test.data prediction.data\n");

	}

    return 0;
}