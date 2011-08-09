#include "omp.h"
#include "time.h"
#include <math.h>
#include <vector>
#include <iostream>
#include <fstream>
#include <sstream>

#include "Ensemble.h"	

using namespace std;

#define PI (3.141592653589793)
#define verbose

Ensemble::Ensemble(int noExperts_, int size_, int dim_, int noClasses_) {

	noExperts = noExperts_;
	dim = dim_;
	noClasses = noClasses_;
	expertDepth = size_;
}

Ensemble::Ensemble() {}

void Ensemble::setParams(int noExperts_, int size_, int dim_, int noClasses_) {

	noExperts = noExperts_;
	dim = dim_;
	noClasses = noClasses_;
	expertDepth = size_;
}

void Ensemble::train(Matrix2df& data, Matrix2df& labels, int numDimTrials, int numThreshTrials, float bagProb, int minNoOFExsAtNode) {

	#pragma omp parallel for
	for (int eIt=0; eIt< noExperts; eIt++) {

		//TODO this isnt really working, need some global var
		cout << "\r" << ((float)eIt/(float)noExperts)*100 << "% complete";

		// initialise bagging
		bool* bag = new bool[data.rows];
		for (int bIt =0; bIt < data.rows; bIt++) {
			if (((float)rand() / (float)RAND_MAX) < bagProb)
				bag[bIt] = true;
			else
				bag[bIt] = false;
		}

		// initialise new tree and train
		Tree tr(expertDepth, data.cols, noClasses);
		tr.train(data, labels, numDimTrials, numThreshTrials, bag, minNoOFExsAtNode);
		trees.push_back(tr);

		delete [] bag;
	}
}


// make sure this is as fast as it can be
void Ensemble::test(Matrix2df& data, Matrix2df& op) {

	vector<Matrix2df> res(trees.size()); 
	for (int tIt = 0; tIt < trees.size(); tIt ++) {

		// initialse matrix num exs X num classes
		res[tIt].create(data.rows, noClasses); 
	}

	#pragma omp parallel for
	for (int tIt = 0; tIt < trees.size(); tIt ++) {
		trees[tIt].test(data,res[tIt]);
	}	

	// getting average of all the classes
	op.create(data.rows, noClasses, 0.0);
	for (int tIt = 0; tIt < trees.size(); tIt ++) {
		op = op + res[tIt];
	}

	op = op / trees.size();
}



void Ensemble::writeEnsemble(string fileName) {
	
	ofstream opFile;
	opFile.open(fileName);	
	
	opFile << noClasses << " NumClasses"  << endl;
	opFile << noExperts << " NumTrees"  << endl;
	opFile << dim  << " Dimensionality" << endl;


	for (int tIt = 0; tIt < trees.size(); tIt ++) {
		opFile << "Tree " << tIt << endl;		
		opFile << trees[tIt].noNodesInTree << " Nodes" << endl;
		trees[tIt].preOrderTraverse(&trees[tIt].root, opFile);
	}	
	opFile.close();
}

void Ensemble::loadEnsemble(string fileName) {

	ifstream  infile;	
	infile.open(fileName.c_str() ,ios::in);	
	string line;

	// delete current trees if there are any
	trees.clear();

	// read in the ensemble params
	vector <int> readVals(3);
	for (int i=0; i< 3; i++) {
		getline(infile,line);
		istringstream is1(line.substr(0,line.find(" ")));		
		is1 >> readVals[i];
	}
	int numClasses_ = readVals[0];
	int numTrees_ = readVals[1];
	int dim_ = readVals[2];

	// global vars for this class
	noExperts = numTrees_;
	dim = dim_;
	noClasses = numClasses_;
	
	// read in the trees
	for(int tIt = 0; tIt < numTrees_; tIt++) {
		
		getline(infile,line);
		getline(infile,line);
		
		// determine the num of nodes
		string numNodes_s = line.substr(0, line.find(" "));
		int numNodes_;				
		stringstream(numNodes_s) >> numNodes_;
		
		// create new tree
		Tree tr(numClasses_, numNodes_);

		// read in node vals
		for (int j=0; j < numNodes_; j++) {
			getline(infile,line);
			vector<float> readVals(numClasses_+3);
			for (int i=0; i < numClasses_+3; i++) {

				string val_s = line.substr(0, line.find(" "));
				line = line.substr(line.find(" ")+1, line.size());				
				stringstream(val_s) >> readVals[i];
			}

			// create new node
			Node* node = new Node();
			node->nodeId = (int)readVals[0];
			node->dimId = (int)readVals[1];
			node->thresh = readVals[2];
			node->posterior = new float[numClasses_];
			node->left = 0;
			node->right = 0;
			for (int pIt = 0; pIt < numClasses_; pIt++)
				node->posterior[pIt] = readVals[pIt+3];

			tr.addNode(node);
		}
		trees.push_back(tr);
	}
}