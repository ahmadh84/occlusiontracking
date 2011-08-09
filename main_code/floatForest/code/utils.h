#ifndef UTILS_H
#define UTILS_H
#include <stdlib.h>


//TODO exception handling not working yet
typedef struct Node {
		int nodeId;
		int dimId;
		float thresh;
		float* posterior;
		int totalExs;
		float entropy;
		bool grown;
		int leftSize;
		int rightSize;
		struct Node *left;   // pointer to the left subtree
		struct Node *right;  // pointer to the right subtree
	};	

class Matrix2df{

public:
	int rows;
	int cols;
	float** data;
	float* colMins;
	float* colMaxes;

	Matrix2df() {
		rows = 0;
		cols = 0;
	}

	Matrix2df(int rows_, int cols_, float init) {
		rows  = rows_;
		cols = cols_;
		data = new float*[rows];		
		colMins = new float[cols];
		colMaxes = new float[cols];
		for (int i = 0; i < rows; ++i) {
			data[i] = new float[cols];

			for (int j = 0; j < cols; ++j)
				data[i][j] = init;
		}
	}

	Matrix2df(int rows_, int cols_) {
		rows  = rows_;
		cols = cols_;
		data = new float*[rows];		
		colMins = new float[cols];
		colMaxes = new float[cols];
		for (int i = 0; i < rows; ++i)
			data[i] = new float[cols];
	}

	void create(int rows_, int cols_) {
		rows  = rows_;
		cols = cols_;
		data = new float*[rows];		
		colMins = new float[cols];
		colMaxes = new float[cols];
		for (int i = 0; i < rows; ++i)
			data[i] = new float[cols];
	}

	void create(int rows_, int cols_, float init) {
		rows  = rows_;
		cols = cols_;
		data = new float*[rows];		
		colMins = new float[cols];
		colMaxes = new float[cols];
		for (int i = 0; i < rows; ++i) {
			data[i] = new float[cols];
			for (int j = 0; j < cols; ++j)
				data[i][j] = init;
		}
	}

	void calColMinMax() {

		// initialise
		for (int cIt = 0; cIt < cols; cIt ++) {
			colMins[cIt] = data[0][cIt];
			colMaxes[cIt] = data[0][cIt];
		}
		
		for (int rIt = 1; rIt < rows; rIt ++) {
			for (int cIt = 0; cIt < cols; cIt ++) {

				if (data[rIt][cIt] < colMins[cIt])
					colMins[cIt] = data[rIt][cIt];
				if (data[rIt][cIt] > colMaxes[cIt])
					colMaxes[cIt] = data[rIt][cIt];
			}
		}


	}

	Matrix2df operator+ (Matrix2df& m1) {

		if (m1.cols == cols && m1.rows == rows) {

			Matrix2df res(rows, cols);

			for (int i = 0; i < m1.rows; ++i)
				for (int j = 0; j < m1.cols; ++j)
					res.data[i][j] = data[i][j] + m1.data[i][j];

			return (res);
		}
		else{
			throw "Error: Matrix dimensions not the same size";
		}
	}

	
	Matrix2df& operator = (Matrix2df& m1) {

		if (m1.cols == cols && m1.rows == rows) {
			for (int i = 0; i< m1.rows; i++)
				for (int j = 0; j< m1.cols ;j++)
					data[i][j] = m1(i, j);
		}
		return *this;
	}
	

	Matrix2df& operator/ (float denom) {
	
		for (int i = 0; i < rows; ++i)
			for (int j = 0; j < cols; ++j)
				data[i][j] = data[i][j] / float(denom);

		return(*this);
	}

	float &Matrix2df::operator()(int i, int j) {
		if (i < rows && j < cols)
			return data[i][j];
		else {
			throw "index exceeds matrix size";			
		}
	}


	~Matrix2df() {	

		if (cols !=0 && rows !=0) {
			delete [] colMins;
			delete [] colMaxes;
			for (int i = 0; i < rows; ++i)
				delete [] data[i];
			delete [] data;
		}
		
	}

};



class Matrix3df{

public:
	int rows;
	int cols;
	int ch;
	float*** data;

	Matrix3df() {}

	Matrix3df(int rows_, int cols_, int ch_, float init) {
		rows  = rows_;
		cols = cols_;
		ch = ch_;

		data = new float**[rows];
		for (int i = 0; i < rows; ++i) {
			data[i] = new float*[cols];
			for (int j = 0; j < cols; ++j) {
				data[i][j] = new float[ch];

				for (int k = 0; k < ch; ++k)
					data[i][j][k] = init;
			}
		}
	}

	float &Matrix3df::operator()(int i, int j, int k) {
		if(i < rows && j < cols && k < ch)
			return data[i][j][k];
		else {
			throw "index exceeds matrix size";			
		}
	}

	~Matrix3df() {	
		for (int i = 0; i < rows; ++i) {
			for (int j = 0; j < cols; ++j) 
				delete [] data[i][j];			
			delete [] data[i];
		}
		delete [] data;
	}
};

class Matrix4df{

public:
	int x0;
	int x1;
	int x2;
	int x3;
	float**** data;

	Matrix4df() {}

	Matrix4df(int x0_, int x1_, int x2_, int x3_, float init) {
		x0  = x0_;
		x1 = x1_;
		x2 = x2_;
		x3 = x3_;

		data = new float***[x0];
		for (int i = 0; i < x0; ++i) {
			data[i] = new float**[x1];

			for (int j = 0; j < x1; ++j) {
				data[i][j] = new float*[x2];

				for (int k = 0; k < x2; ++k) {
					data[i][j][k] = new float[x3];

					for (int l = 0; l < x3; ++l)
						data[i][j][k][l] = init;
				}
			}
		}
	}

	float &Matrix4df::operator()(int i, int j, int k, int l) {
		if(i < x0 && j < x1 && k < x2 && l < x3)
			return data[i][j][k][l];
		else {
			throw "index exceeds metrix size";			
		}
	}

	~Matrix4df() {	
		for (int i = 0; i < x0; ++i) {
			for (int j = 0; j < x1; ++j) {
				for (int k = 0; k < x2; ++k) 
					delete [] data[i][j][k];
				delete [] data[i][j];
			}							
			delete [] data[i];
		}
		delete [] data;
	}

};


class Matrix1df{

public:
	int length;
	float* data;

	Matrix1df() {}

	Matrix1df(int length_, float init) {
		length  = length_;
		data = new float[length];

		for (int dIt = 0; dIt < length; dIt ++) 
			data[dIt] = 0.0;
	}

	// random vector with points between min and max
	// TODO check for duplicates
	Matrix1df(int length_, float min, float max) {
		length  = length_;
		data = new float[length];

		for (int dIt = 0; dIt < length; dIt ++) 
			data[dIt] = min + (max - min) * ((float)rand() / (float)RAND_MAX);
	}

	float &Matrix1df::operator() (int col) {
		if (col < length) 
			return(data[col]);
		else {
			throw "index exceeds metrix size";			
		}
	}

	~Matrix1df() {
		delete [] data;
	}

};

class Matrix1di{

public:
	int length;
	int* data;

	Matrix1di() {}

	Matrix1di(int length_, int init) {
		length  = length_;
		data = new int[length];

		for (int dIt = 0; dIt < length; dIt ++) 
			data[dIt] = 0;
	}

	// random integers between 0 and max
	// TODO check for duplicates
	Matrix1di(int length_, int min, int max) {
		length  = length_;
		data = new int[length];

		for (int dIt = 0; dIt < length; dIt ++) 
			data[dIt] = min + rand()%(max-min);
	}

	int &Matrix1di::operator() (int col) {
		if (col < length) 
			return(data[col]);
		else {
			throw "index exceeds metrix size";			
		}
	}

	~Matrix1di() {
		delete [] data;
	}

};


#endif