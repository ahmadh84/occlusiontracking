#include "Tree.h"	
#include <math.h>
#include <algorithm>
#include <math.h>
#include <time.h>
#include <vector>
#include <fstream>
#include <iostream>

using namespace std;


Tree::Tree(int depth_, int dim_, int noClasses_) {
	depth = depth_;
	dim = dim_; 
	noClasses = noClasses_;
	noNodes = pow(2,(float)depth+1) - 1;
	noNodesInTree = 0;
	leafNodes = pow(2.0, depth+1) - 2; // actually going one deeper here
}

Tree::Tree(int noClasses_, int noNodesInTree_) {
	noClasses = noClasses_;
	noNodesInTree = noNodesInTree_;
}

double log2( double n )  {  

	if(n == 0)
		return(-100000000.0); // hack
	else
		return log( n ) / log( 2.0 );  
}

void Tree::calcBestNode(Matrix2df& X, Matrix2df& Y, bool bag[], int numDimTrials, int numThreshTrials, Node& curNode) {
	
	//cout << "*id " << curNode.nodeId << "*" << endl;
	// initialise tests - currently not taking care of duplicates
	Matrix1di test_id(numDimTrials, 0, dim);
	if (numDimTrials > dim) { 
		numDimTrials = dim;
		// case where the dimensionality is small - exhaustive search
		for (int dIt = 0; dIt < dim; dIt ++) 
			test_id(dIt) = dIt;
	}

	// set up random threshold test values
	Matrix2df test_thresh(numDimTrials, numThreshTrials);
	for (int dIt =0; dIt < numDimTrials; dIt ++) {
		for (int tIt =0; tIt < numThreshTrials; tIt ++) {
			float dMin = X.colMins[test_id(dIt)];
			float dMax = X.colMaxes[test_id(dIt)];
			test_thresh(dIt, tIt) = dMin + (dMax - dMin) * ((float)rand() / (float)RAND_MAX);
		}
	}

	// store the tmp posteriors here
	Matrix4df test_post(numDimTrials,numThreshTrials,noClasses,2,0.0);
	Matrix3df numExsAtNode(numDimTrials, numThreshTrials, 2, 0.0); // change to integer matrix

	float totalExs = 0;

	for (int xIt = 0; xIt < X.rows; xIt++) { // loop though training data

		if (bag[xIt]) { // perform bagging

			// want to get the current class label
			// currently just taking max value in Y
			int curClass = 0;
			for (int dIt = 1; dIt < noClasses; dIt++) {
				if (Y(xIt, dIt) > Y(xIt, curClass))
					curClass = dIt;
			}
			
			// traverse current tree to make sure example lands at this node			
			bool validEx = false;
			if (root.left == 0 && root.right== 0) { // root node
				validEx = true;		
			}
			else {
				Node* node = &root;
				while (node->left !=0 || node->right != 0) { // exit if it hits a leaf, also if the nodeID is bigger we should exit

					//cout << (X(xIt, node->dimId) < node->thresh) << " " << node->nodeId << endl;
					if(X(xIt, node->dimId) < node->thresh) {
						if (node->left == 0)
							break;
						node = node->left; // go left ie 1
						
					}else { 
						if (node->right == 0)
							break;
						node = node->right; // go right ie 0
					}

					// if we have reached the correct node exit
					if (node->nodeId == curNode.nodeId) { // reached the current node
						validEx = true;
						break;
					}
				}

			}


			if (validEx) { 		

				totalExs++;

				for (int idIt = 0; idIt < numDimTrials; idIt++) { // loop through possible dims
					for (int thIt = 0; thIt < numThreshTrials; thIt++) { // try different threshes at this location 

						// returning: 0 to go left and 1 to go right
						int dec = (int)(X(xIt, test_id(idIt)) < test_thresh(idIt, thIt)); // is this working for binary conversion

						// count the number of examples going left and right
						numExsAtNode(idIt, thIt, dec) ++;
						test_post(idIt, thIt, curClass, dec)++;

					}
				}

			}
		}

	}

	// calc node with best info gain
	float infoGainBest = -3.40282e+38;
	int bestId = 0;
	int bestThresh = 0;

	for (int idIt = 0; idIt < numDimTrials; idIt++) { // loop through possible dims
		for (int thIt = 0; thIt < numThreshTrials; thIt++) { // try different threshes at this location 

			// calculate information gain
			float infoGainCur = 0.0;
			for (int eIt = 0; eIt < 2; eIt ++) {
				float entropy = 0.0;
				for (int cIt = 0; cIt < noClasses; cIt++) 
					entropy += (test_post(idIt, thIt, cIt, eIt)/numExsAtNode(idIt, thIt, eIt))*log2(test_post(idIt, thIt, cIt, eIt)/numExsAtNode(idIt, thIt, eIt));

				infoGainCur += -entropy*(numExsAtNode(idIt, thIt, eIt) / (numExsAtNode(idIt, thIt, 0) + numExsAtNode(idIt, thIt, 1)));
			}
			infoGainCur = -infoGainCur;

			if (infoGainCur > infoGainBest) {
				bestId = idIt;
				bestThresh = thIt;
				infoGainBest = infoGainCur;			
			}

			// wont get better energy than this - exit
			if (infoGainBest == 0) { 
				idIt = numDimTrials;
				thIt = numThreshTrials;
			}
		}
	}

		
	// normalize posteriors of best node
	curNode.dimId = test_id(bestId);
	curNode.thresh = test_thresh(bestId,bestThresh);
	curNode.posterior = new float[noClasses];
	curNode.entropy = infoGainBest;
	curNode.totalExs = totalExs;
	curNode.grown = true;
	curNode.leftSize = numExsAtNode(bestId, bestThresh, 1);
	curNode.rightSize = numExsAtNode(bestId, bestThresh, 0); 
	curNode.left = 0;
	curNode.right = 0;
	for (int cIt = 0; cIt < noClasses; cIt++) 
		curNode.posterior[cIt] = (test_post(bestId, bestThresh, cIt, 0) + test_post(bestId, bestThresh, cIt, 1) ) / totalExs;
	
}

// main problems in here
void Tree::preorderCreate(Node* node, Matrix2df& X, Matrix2df& Y, bool bag[], int numDimTrials, int numThreshTrials, int minNoOFExsAtNode) {
	
	
	//cout << "id " << node->nodeId << " l " << node->leftSize << " r " << node->rightSize << " ent " << node->entropy << " " << endl; 

	if ((node->leftSize > minNoOFExsAtNode)  &&  node->left ==0 & (2*(node->nodeId)+1) <= leafNodes) {	// need to create a leaf node and leave it at that		
		//cout << "left " << node->nodeId << endl;
		Node* leftN = new Node();
		node->left = leftN;
		leftN->nodeId = 2*(node->nodeId)+1;
		// are the following two lines getting the same pointers?
		calcBestNode(X, Y, bag, numDimTrials, numThreshTrials, *leftN); 
		preorderCreate( node->left, X, Y, bag, numDimTrials, numThreshTrials, minNoOFExsAtNode); 

		//cout << "LEFT id " << node->left->nodeId << " l " << node->left->leftSize << " r " << node->left->rightSize << " ent " << node->left->entropy << " " << endl; 

	}

	if ((node->rightSize > minNoOFExsAtNode) & node->right ==0 & (2*(node->nodeId)+2) <= leafNodes) {
		//cout << "right " << node->nodeId << endl;
		Node* rightN = new Node();
		node->right = rightN;
		rightN->nodeId = 2*(node->nodeId)+2;
		calcBestNode(X, Y, bag, numDimTrials, numThreshTrials, *rightN);
		preorderCreate( node->right, X, Y, bag, numDimTrials, numThreshTrials, minNoOFExsAtNode); 

		//cout << "RIGHT id " << node->right->nodeId << " l " << node->right->leftSize << " r " << node->right->rightSize << " ent " << node->right->entropy << " " << endl; 
	}
}


void Tree::train(Matrix2df& data, Matrix2df& labels, int numDimTrials, int numThreshTrials, bool bag[], int minNoOFExsAtNode) {

	int noNodes = pow(2.0, depth+1) - 1;
	int leafNodes = pow(2.0, depth) - 2;

	int largestValidNode = 0;
	int numNodesUsed = 0;
	int currentDepth = 0;

	root.nodeId = 0;
	root.left = 0;
	root.right = 0;

	calcBestNode(data, labels, bag, numDimTrials, numThreshTrials, root);
		
	preorderCreate(&root, data, labels, bag, numDimTrials, numThreshTrials, minNoOFExsAtNode); // maybe should make some params global

	// count num of nodes in tree
	countNodes(&root, noNodesInTree);
}


int Tree::countNodes(Node* node, int& cnt) {
	cnt = cnt++;
	if (node->left !=0)		
		countNodes(node->left, cnt);
	if (node->right !=0)		
		countNodes(node->right, cnt);

	return cnt;
}

void Tree::addNodeToTree(Node* node, Node* nodeToAdd) {
	
	if (2*(node->nodeId)+1 == nodeToAdd->nodeId)		
		node->left = nodeToAdd;
	else if (2*(node->nodeId)+2 == nodeToAdd->nodeId)		
		node->right = nodeToAdd;
	else {
		if (node->left !=0)	
			addNodeToTree(node->left, nodeToAdd);
		if (node->right !=0)	
			addNodeToTree(node->right, nodeToAdd);
	}
}

void Tree::addNode(Node* node) {

	if (node->nodeId == 0) {
		root.nodeId = 0;
		root.dimId = node->dimId;
		root.thresh = node->thresh;
		root.posterior = new float[noClasses];
		root.left = 0;
		root.right = 0;
		for (int cIt = 0; cIt < noClasses; cIt++)
			root.posterior[cIt] = node->posterior[cIt];
	}
	else
		addNodeToTree(&root, node);
}

// return all the posteriors
int Tree::test(Matrix2df& X, Matrix2df& res) {

	for (int xIt = 0; xIt < X.rows; xIt++) {		
		Node* node = &root;
		while (node->left !=0 || node->right != 0) { // exit if it hits a leaf	

			if(X(xIt, node->dimId) < node->thresh) {
				if (node->left == 0)
					break;
				node = node->left; // go left

			}else { 
				if (node->right == 0)
					break;
				node = node->right; // go right
			}

		}
		for (int cIt = 0; cIt <noClasses; cIt++)
			res.data[xIt][cIt] = node->posterior[cIt];					
	}
	return(0);
}

void Tree::preOrderTraverse(Node* node, ofstream& opFile) {
	
	// write data
	opFile << node->nodeId << " ";
	opFile << node->dimId << " ";
	opFile << node->thresh << " ";
	for (int cIt = 0; cIt < noClasses; cIt++)
		opFile << node->posterior[cIt] << " ";
	opFile << "\n";

	// traverse
	if (node->left !=0)		
		preOrderTraverse(node->left, opFile);
	if (node->right !=0)		
		preOrderTraverse(node->right, opFile);	
}

Tree::~Tree() {
	//TODO delete all the memory allocated in the nodes
}