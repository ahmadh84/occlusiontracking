#include <tchar.h>
#include "math.h"
#include <iostream>
#include <cstdlib> 
#include <fstream>
#include <sstream>
#include <vector>
#include "time.h"

#include "Ensemble.h"
#include "utils.h"


using namespace std;


//TODO: currently im reading the file once to see how big it is and then 
//reading it again to store the data. Need to make this more efficient. 
void loadData(string ipFile, Matrix2df& data) {

	ifstream  infile;		
	infile.open(ipFile.c_str() ,ios::in);
	string line;

	// count number of cols
	getline(infile,line);
	int numCols = 0;
	for (int cIt = 0; cIt < line.length(); cIt ++) {
		if( line[cIt] == ',')
			numCols++;
	}

	// count number of rows
	int numRows = 0;
	while(!getline(infile,line).eof())	
		numRows++;
	infile.close();

	// read data
	infile.open(ipFile.c_str() ,ios::in);
	data.create(numRows+1, numCols+1);

	int rIt = 0;
	int dIt = 0;
	stringstream iss;
	while(!getline(infile,line).eof() & !(rIt > numRows))
	{			
		string token;
		iss << line;

		int dIt = 0;
		float val = 0.0;
		while ( getline(iss, token, ',') )
		{
			istringstream is(token);		
			is >> val;
			data(rIt, dIt) = val;
			dIt++;
		}
		iss.clear();

		rIt++;
	}	

	infile.close();
	cout << "\rRead " << ipFile << ", rows = " << numRows+1 << ", cols = " << numCols+1 << endl;
	// calculate the min and max of each col
	data.calColMinMax();


}


void writeMatrix(string opFileName, Matrix2df& data, bool writeToScreen) {

	// write to screen
	if (writeToScreen) {
		for (int rIt = 0; rIt < data.rows; rIt++) {
			cout << rIt << "\t ";
			for (int cIt = 0; cIt < data.cols; cIt++)
				cout << data(rIt, cIt) << " ";
			cout << endl;
		}
	}

	// write to file
	ofstream opFile;
	opFile.open(opFileName);

	for (int rIt = 0; rIt < data.rows; rIt ++) {
		for (int cIt = 0; cIt < data.cols; cIt ++) 
			opFile << data(rIt, cIt) << ",";
		opFile << "\n";
	}

	opFile.close();
}

void displayUsage() {

	cout << "Usage 1: Training new forest" << endl << endl;
	cout << "floatForest.exe numTrees maxDepth numDimTests numThreshTest bagSize minExsAtNode ipData ipLabels testFile opFile treeFile" << endl << endl;
	cout << "numTrees - the number of trees, > 0" << endl;
	cout << "maxDepth - the maximum depth to grow the trees, 20" << endl;
	cout << "numDimTests - the num of different dimensions to try tests at, larger = more accurate, < dim of data" << endl;
	cout << "numThreshTest - the num of different thresholds to try at each dim, larger = more accurate, 100" << endl;
	cout << "bagSize - the persentage of data points randomly given to each tree, >0 <100,  25" << endl;
	cout << "minExsAtNode - create leaf node if less than this many examples reach node, 10" << endl;
	cout << "ipData - path of file containing training examples, C:\\TMP\\X.data" << endl;
	cout << "ipLabels - path of file containing training labels, C:\\TMP\\Y.data" << endl;
	cout << "testData - path of file containing data to classify, C:\\TMP\\Y.data" << endl;
	cout << "opFile - path to save results file, C:\\TMP\\results.data" << endl;
	cout << "treeFile - path of forest to save, C:\\TMP\\forest.data" << endl << endl << endl;

	cout << "Usage 2: Loading an existing forest" << endl << endl;
	cout << "floatForest.exe testData opFile treeFile" << endl << endl;
	cout << "testData - path of file containing data to classify, C:\\TMP\\Y.data" << endl;
	cout << "opFile - path to save results file, C:\\TMP\\results.data" << endl;
	cout << "treeFile - path of forest to load, C:\\TMP\\forest.data" << endl;

}

int main(int argc, char* argv[]) {

	/*********************
	** Parameters
	*********************/	
	string ipData;	
	string ipLabels;
	string ensembleFile;
	string testData;
	string opFileName;

	// training parameters
	int numTrees;
	int treeDepth; // 0 = 1 node, 1 = 3 nodes, 2 = 7 ...
	int numDimTrials;//num of dims to try < dim
	int numThreshTrials; // num of thresholds at each dimension to try
	float bagProb; // probability of sample landing in bag
	int minNoOFExsAtNode; // stop growing tree if num of examples at node equals this value

	srand ( time(NULL) );
	clock_t init;
	Ensemble trees;	


	/*********************
	** Set up parameters
	*********************/	
	bool trainingNew = false;
	if (argc == 12) {// training new forest
		
		trainingNew = true;
		numTrees = atoi(argv[1]);
		treeDepth = atoi(argv[2]);
		numDimTrials = atoi(argv[3]);
		numThreshTrials = atoi(argv[4]);
		bagProb = (float)atoi(argv[5])/100.0;
		minNoOFExsAtNode = atoi(argv[6]);

		cout << "** " << bagProb << " " << treeDepth << endl; 
		ipData = argv[7];
		ipLabels = argv[8];
		testData = argv[9];
		opFileName =  argv[10];
		ensembleFile =  argv[11];

	}
	else if (argc == 4) {// loading existing forest

		testData = argv[1];
		opFileName =  argv[2];
		ensembleFile =  argv[3];

	}
	else {// exit if invalid number of agruments passed

		displayUsage();
		return 0;
	}
	

	/*********************
	** Training
	*********************/
	if (trainingNew) {

		/*********************
		** Load training data
		*********************/		
		init=clock();
		cout << endl << "***************************" << endl << "Loading data" << endl << endl;			
		Matrix2df data;
		loadData(ipData, data);	
		Matrix2df labels;
		loadData(ipLabels, labels);
		cout << "loading data time " << (double)(clock()-init) / ((double)CLOCKS_PER_SEC) << " sec" << endl;
		

		/*********************
		** Training
		*********************/
		init=clock();
		cout << endl << "***************************" << endl << "Training" << endl;	
		trees.setParams(numTrees, treeDepth, data.cols, labels.cols);		
		trees.train(data, labels, numDimTrials, numThreshTrials, bagProb, minNoOFExsAtNode);
		cout << "\r                                      " << endl;
		cout << "training time " << (double)(clock()-init) / ((double)CLOCKS_PER_SEC) << " sec" << endl;

		/*********************
		** Save forest
		*********************/	
		trees.writeEnsemble(ensembleFile);
	}
	else {

		/*********************
		** Load forest
		*********************/		
		trees.loadEnsemble(ensembleFile);
	}


	/*********************
	** Testing
	*********************/	
	cout << endl << "***************************" << endl << "Testing" << endl << endl;
	cout << "reading test data";	
	Matrix2df test;	
	loadData(testData, test);	
	Matrix2df op;	
	init=clock();
	trees.test(test, op);
	cout << "\rtesting time " << (double)(clock()-init) / ((double)CLOCKS_PER_SEC) << " sec" << endl;


	/*********************
	** Save results
	*********************/
	writeMatrix(opFileName, op, false);

	return 0;
}

