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
	root.initialiseNode(0, noClasses);
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


void Tree::calcBestNode(Matrix2df& X, Matrix2df& Y, bool bag[], int numDimTrials, int numThreshTrials, Node& curNode, int minNoOFExsAtNode) {
	
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
			// TODO: perhaps we could cache all this, depends on how many nodes we are using, 
			//       just delete the cached values for the nodes we have already built
			bool validEx = false;
			if (curNode.nodeId == 0 && !root.grown) { // root node not grown yet
				validEx = true;		
			}
			else {

				Node* node = &root;
				while (!node->isLeaf && node->grown) { // exit if it hits a leaf or ungrown node
										
					if(X(xIt, node->dimId) > node->thresh) {
						node = node->right; // go right ie 1						
					}else { 
						node = node->left; // go left ie 0
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
						int dec = (int)(X(xIt, test_id(idIt)) > test_thresh(idIt, thIt));

						// count the number of examples going left and right
						numExsAtNode(idIt, thIt, dec) ++;
						test_post(idIt, thIt, curClass, dec)++;

					}
				}

			}
		}

	}


	// special case for root - calc entropy
	if (curNode.nodeId == 0) {
		float entropy = 0.0;
		for (int cIt = 0; cIt < noClasses; cIt++) {
			float noExamples = test_post(0, 0, cIt, 0) + test_post(0, 0, cIt, 1);
			entropy -= (noExamples/totalExs)*log2(noExamples/totalExs);
		}
		curNode.entropy = entropy;
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
			infoGainCur = curNode.entropy - infoGainCur;

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
	curNode.infoGain = infoGainBest;
	curNode.totalExs = totalExs;
	curNode.grown = true;
		

	// cleanup the following
	// decide if to split node 
	bool splitNode = true;
	// special case for root 
	if (curNode.nodeId == 0) {
		// save posteriors
		for (int cIt = 0; cIt < noClasses; cIt++) 
			curNode.posterior[cIt] = (test_post(bestId, bestThresh, cIt, 0) + test_post(bestId, bestThresh, cIt, 1) ) / totalExs;
		
		splitNode = true;
	} 
	/*// dont create children unless info gain better than parents - entropy already taking care of this
	else if (curNode.infoGain >= curNode.parent->infoGain) { // should be info gain
		// make this node a leaf and dont split		
		splitNode = false;
		curNode.isLeaf = true;
	} 
	*/

	if (splitNode) {
		curNode.left = new Node(2*(curNode.nodeId)+1, noClasses);
		curNode.right = new Node(2*(curNode.nodeId)+2, noClasses);
		curNode.left->parent = &curNode;
		curNode.right->parent = &curNode;
		curNode.left->totalExs = numExsAtNode(bestId, bestThresh, 0);
		curNode.right->totalExs = numExsAtNode(bestId, bestThresh, 1);

		// calc child entropy
		curNode.left->entropy = 0;
		curNode.right->entropy = 0;
		for (int cIt = 0; cIt < noClasses; cIt++) {
			curNode.left->entropy -= (test_post(bestId, bestThresh, cIt, 0)/numExsAtNode(bestId, bestThresh, 0))*log2(test_post(bestId, bestThresh, cIt, 0)/numExsAtNode(bestId, bestThresh, 0));
			curNode.right->entropy -= (test_post(bestId, bestThresh, cIt, 1)/numExsAtNode(bestId, bestThresh, 1))*log2(test_post(bestId, bestThresh, cIt, 1)/numExsAtNode(bestId, bestThresh, 1));
		}

		// conditions to make a leaf: 
		if ((curNode.left->totalExs < minNoOFExsAtNode) || (curNode.left->nodeId > leafNodes) ||  (curNode.left->entropy == 0))
			curNode.left->isLeaf = true;
		if ((curNode.right->totalExs < minNoOFExsAtNode) || (curNode.right->nodeId > leafNodes) || (curNode.right->entropy == 0))
			curNode.right->isLeaf = true;

		// set posteriors of leaf nodes
		for (int cIt = 0; cIt < noClasses; cIt++) {
			if (numExsAtNode(bestId, bestThresh, 0) > 0) 
				curNode.left->posterior[cIt] = test_post(bestId, bestThresh, cIt, 0)  / numExsAtNode(bestId, bestThresh, 0);
			if (numExsAtNode(bestId, bestThresh, 1) > 0) 
				curNode.right->posterior[cIt] = test_post(bestId, bestThresh, cIt, 1)  / numExsAtNode(bestId, bestThresh, 1);
		}	
	}
}


void Tree::preorderCreate(Node* node, Matrix2df& X, Matrix2df& Y, bool bag[], int numDimTrials, int numThreshTrials, int minNoOFExsAtNode) {

	if (!node->isLeaf) {
		if ((!node->left->isLeaf)) {	// need to create a leaf node and leave it at that		

			calcBestNode(X, Y, bag, numDimTrials, numThreshTrials, *node->left, minNoOFExsAtNode); 
			preorderCreate( node->left, X, Y, bag, numDimTrials, numThreshTrials, minNoOFExsAtNode); 
		}
		if ((!node->right->isLeaf)) {

			calcBestNode(X, Y, bag, numDimTrials, numThreshTrials, *node->right, minNoOFExsAtNode);		
			preorderCreate( node->right, X, Y, bag, numDimTrials, numThreshTrials, minNoOFExsAtNode); 
		}
	}
}


void Tree::train(Matrix2df& data, Matrix2df& labels, int numDimTrials, int numThreshTrials, bool bag[], int minNoOFExsAtNode) {
	
	calcBestNode(data, labels, bag, numDimTrials, numThreshTrials, root, minNoOFExsAtNode);
		
	preorderCreate(&root, data, labels, bag, numDimTrials, numThreshTrials, minNoOFExsAtNode);

	// count num of nodes in tree - could do this in preorderCreate
	countNodes(&root, noNodesInTree);
}


int Tree::countNodes(Node* node, int& cnt) {
	cnt = cnt++;
	if (!node->isLeaf) {		
		countNodes(node->left, cnt);		
		countNodes(node->right, cnt);
	}
	return cnt;
}

void Tree::addNodeToTree(Node* node, Node* nodeToAdd) {

	if (2*(node->nodeId)+1 == nodeToAdd->nodeId) {
		node->left = nodeToAdd;
		node->isLeaf = false;
	}
	else if (2*(node->nodeId)+2 == nodeToAdd->nodeId) {
		node->right = nodeToAdd;
		node->isLeaf = false;
	}
	else {
		if (node->left !=0)	
			addNodeToTree(node->left, nodeToAdd);
		if (node->right !=0)	
			addNodeToTree(node->right, nodeToAdd);
	}
}

void Tree::addNode(Node* node) {

	node->isLeaf = true;
	if (node->nodeId == 0) {
		root.initialiseNode(0, noClasses);
		root.dimId = node->dimId;
		root.thresh = node->thresh;
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

		while (!node->isLeaf) { // exit if it hits a leaf	

			if(X(xIt, node->dimId) > node->thresh) {
				node = node->right; // go right, 1

			}else { 
				node = node->left; // go left, 0
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

	// remove
	//opFile << node->infoGain << " ";
	//opFile << node->entropy << " ";
	//

	opFile << "\n";

	// traverse
	if (!node->isLeaf) {		
		preOrderTraverse(node->left, opFile);	
		preOrderTraverse(node->right, opFile);	
	}
}

Tree::~Tree() {
	//TODO delete all the memory allocated in the nodes
}