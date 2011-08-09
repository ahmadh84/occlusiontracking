#ifndef ENSEMBLE_H
#define ENSEMBLE_H

#include "Tree.h"
#include "utils.h"

using namespace std;

class Ensemble
{
private:
	vector<Tree> trees; // would it be better if this was vector of pointers
	
public:
	int noExperts;
	int dim;
	int noClasses;
	int expertDepth;

	Ensemble(int noExperts_, int size_, int dim_, int noClasses_);	
	Ensemble();
	void setParams(int noExperts_, int size_, int dim_, int noClasses_);
	void train(Matrix2df& data, Matrix2df& labels, int numDimTrials, int numThreshTrials, float bagProb, int minNoOFExsAtNode);
	void test(Matrix2df& data, Matrix2df& res);
	void writeEnsemble(string fileName);
	void loadEnsemble(string fileName);
};


#endif