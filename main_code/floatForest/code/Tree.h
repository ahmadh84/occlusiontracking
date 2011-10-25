#ifndef TREE_H
#define TREE_H

#include "utils.h"
#include <fstream>
#include <iostream>

class Tree
{
public:
    int depth;
    int noTests;
	int noClasses;
	int dim;
	int noNodes;
	int leafNodes;
	int noNodesInTree;
	
	Node root;

    Tree() { };
	~Tree();
    Tree(int depth_, int dim_, int noClasses_);
	Tree(int noClasses_, int noNodesInTree_);

    void train(Matrix2df& data, Matrix2df& labels, int numDimTrials, int numThreshTrials, bool bag[], int minNoOFExsAtNode);
	int test(Matrix2df& X, Matrix2df& res);
	int test(Matrix2df& X, Matrix2df& res, int classId);	
	void preOrderTraverse(Node* node, std::ofstream& opFile);
	void addNode(Node* node);

private:
	int countNodes(Node* node, int& cnt);
	void addNodeToTree(Node* node, Node* nodeToAdd);
	void calcBestNode(Matrix2df& X, Matrix2df& Y, bool bag[], int numDimTrials, int numThreshTrials, Node& curNode, int minNoOFExsAtNode);
	void preorderCreate(Node* node, Matrix2df& X, Matrix2df& Y, bool bag[], int numDimTrials, int numThreshTrials, int minNoOFExsAtNode);
};

#endif