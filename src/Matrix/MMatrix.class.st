Class {
	#name : #MMatrix,
	#superclass : #Object,
	#instVars : [
		'nbRows',
		'nbColumns',
		'array'
	],
	#category : #Matrix
}

{ #category : #'instance creation' }
MMatrix class >> new [ 
	
	self error: 'Use #newRows:columns:'
]

{ #category : #'instance creation' }
MMatrix class >> newFromArrays: arrays [
	"
	MMatrix newFromArrays: #(#(1 2 3) #(4 5 6))
	MMatrix newFromArrays: #(#(1 2 3))
	"
	^ self basicNew
		initializeRows: arrays size columns: arrays first size;
		fromContents: (arrays flatCollect: #yourself);
		yourself
			
]

{ #category : #'instance creation' }
MMatrix class >> newFromVector: vector [
	"
	MMatrix newFromVector: #(1 2 3)
	"
	^ self basicNew
		initializeRows: vector size columns: 1;
		fromContents: vector;
		yourself
			
]

{ #category : #'instance creation' }
MMatrix class >> newHandle: aHandle rows: numRows columns: numColumns [
	"Create a matrix with a provided content. Useful when creating a matrix after an FFI operation"
	^ self basicNew
		initializeHandle: aHandle rows: numRows columns: numColumns;
		yourself
			
]

{ #category : #'instance creation' }
MMatrix class >> newRows: numRows columns: numColumns [

	^ self basicNew
		initializeRows: numRows columns: numColumns;
		yourself
			
]

{ #category : #arithmetic }
MMatrix >> * aFactor [
	"Multiply each element of the matrix by a factor"
	^ self collect: [ :v | v * aFactor ]
]

{ #category : #arithmetic }
MMatrix >> + matrixOrVector [
	"Add either a matrix or a vector. The argument could either be a matrix of the same size than me, or a vector
	A new matrix is returned as result"
	| m |
	((nbRows = matrixOrVector nbRows) and: [ nbColumns = matrixOrVector nbColumns ])
		ifTrue: [ ^ self add: matrixOrVector ].
		
	matrixOrVector nbColumns ~= 1 ifTrue: [ self error: 'not a n * 1 vector' ].
	m := matrixOrVector stretchToColumns: nbColumns.
	^ self + m
]

{ #category : #arithmetic }
MMatrix >> +* anotherMatrix [
	"Shortcut for the dot operator between matrices"
	^ self dot: anotherMatrix 
]

{ #category : #arithmetic }
MMatrix >> ++ aVector [
	"NOT USED"
	| result |
	result := MMatrix newRows: nbRows columns: nbColumns.
	1 to: nbRows do: [ :y |
		1 to: nbColumns do: [ :x |
			result at: x @ y put: ((self at: x @ y) - (aVector at: x @ 1))
		] 
	].
	^ result
	
"	| resultArray result |
	resultArray := ByteArray new: (nbRows * nbColumns * 8).
	result := MMatrix 
		newHandle: resultArray 
		rows: nbRows 
		columns: nbColumns.
	^ result"
]

{ #category : #arithmetic }
MMatrix >> - anotherMatrix [
	"Substract a matrix from the receiver matrix"
	^ self sub: anotherMatrix
	
	"PHARO VERSION"
	"| result |
	result := MMatrix newRows: nbRows columns: nbColumns.
	1 to: nbRows do: [ :y |
		1 to: nbColumns do: [ :x |
			result at: x @ y put: ((self at: x @ y) - (anotherMatrix at: x @ y))
		] 
	].
	^ result"
]

{ #category : #arithmetic }
MMatrix >> / value [
	"Divide each element of the matrix by a value"
	^ self collect: [ :v | v / value ]
]

{ #category : #arithmetic }
MMatrix >> add: aMatrix [
	"Add two matrices, the receiver and the argument, and produces a new matrix"
	| result resultArray |
	nbColumns = aMatrix nbColumns ifFalse: [self error: 'dimensions do not conform'].
	nbRows = aMatrix nbRows ifFalse: [self error: 'dimensions do not conform'].
	
	resultArray := ByteArray new: (nbRows * aMatrix nbColumns * 8).
	
	self assert: [ nbRows * nbColumns = array size ].
	self assert: [ aMatrix nbRows * aMatrix nbColumns = aMatrix array size ].
	self assert: [ nbRows * aMatrix nbColumns * 8 = resultArray size ].
	
	self 
		add: self array getHandle 
		with: nbRows 
		with: nbColumns 
		with: aMatrix array getHandle
		in: resultArray.
	
	result := MMatrix 
		newHandle: resultArray 
		rows: nbRows 
		columns: nbColumns.
	
	^ result
]

{ #category : #private }
MMatrix >> add: m1 with: nb_rows with: nb_columns with: m2 in: res [

	^ self 
		ffiCall: #(void add(double *m1, int nb_rows, int nb_columns, 
              	double *m2, 
              	double *res)) 
		module: '/tmp/matrix.dylib'

]

{ #category : #accessing }
MMatrix >> array [
	^ array
]

{ #category : #accessing }
MMatrix >> asArray [
	^ array asArray
]

{ #category : #accessing }
MMatrix >> asStructuredArray [
	"Return a structured array that describe the matrix"
	^ (1 to: nbRows) collect: [ :i | self atRow: i ] as: Array

]

{ #category : #accessing }
MMatrix >> at: aPoint [
	"Access an element of the matrix"
	^ array at: ((aPoint y - 1) * nbColumns + (aPoint x - 1)) + 1
]

{ #category : #accessing }
MMatrix >> at: aPoint put: aNumber [
	"Modify an element of the matrix"
	array at: ((aPoint y - 1) * nbColumns + (aPoint x - 1)) + 1 put: aNumber asFloat
]

{ #category : #printing }
MMatrix >> atRow: rowNumber [
	"Return a particular row"
	(rowNumber between: 1 and: rowNumber)
		ifFalse: [ self error: '1st subscript out of range' ].
	^ (1 to: nbColumns) collect: [ :x | self at: x @ rowNumber ] 
		
]

{ #category : #private }
MMatrix >> codeForTransposition [

"#include <stdio.h>
 
void transpose(void *dest, void *src, int src_h, int src_w)
{
	int i, j;
	double (*d)[src_h] = dest, (*s)[src_w] = src;
	for (i = 0; i < src_h; i++)
		for (j = 0; j < src_w; j++)
			d[j][i] = s[i][j];
}
 
int main()
{
	int i, j;
	double a[3][5] = 
	         {{ 0, 1, 2, 3, 4 },
			  { 5, 6, 7, 8, 9 },
			  { 1, 0, 0, 0, 42}};
	double b[5][3];
	transpose(b, a, 3, 5);
 
	for (i = 0; i < 5; i++)
		for (j = 0; j < 3; j++)
			printf(""%g%c"", b[i][j], j == 2 ? '\n' : ' ');
	return 0;
}"
]

{ #category : #enumerating }
MMatrix >> collect: aOneArgBlock [
	"Return a new matrix, for which each matrix element is transformed."
	| result |
	result := MMatrix newRows: nbRows columns: nbColumns.
	1 to: nbRows do: [ :y |
		1 to: nbColumns do: [ :x |
			result at: x @ y put: (aOneArgBlock value: (self at: x @ y))
		] 
	].
	^ result
]

{ #category : #accessing }
MMatrix >> dot: anotherMatrix [
	| result resultArray |
	nbColumns = anotherMatrix nbRows ifFalse: [self error: 'dimensions do not conform'].
	
	resultArray := ByteArray new: (nbRows * anotherMatrix nbColumns * 8).
	
	self assert: [ nbRows * nbColumns = array size ].
	self assert: [ anotherMatrix nbRows * anotherMatrix nbColumns = anotherMatrix array size ].
	self assert: [ nbRows * anotherMatrix nbColumns * 8 = resultArray size ].
	
	"COMPUTATION WITHIN PHARO"
	"resultArray := FloatArray new: (nbRows * anotherMatrix nbColumns)."
	"-----"
	"
	self 
		pharoMultiply: self array asFloatArray 
		with: nbRows 
		with: nbColumns 
		with: anotherMatrix array asFloatArray
		with: anotherMatrix nbRows 
		with: anotherMatrix nbColumns 
		in: resultArray.
	"
	self 
		dot: self array getHandle 
		with: nbRows 
		with: nbColumns 
		with: anotherMatrix array getHandle
		with: anotherMatrix nbRows 
		with: anotherMatrix nbColumns 
		in: resultArray.
	
	
	"COMPUTATION WITHIN PHARO"
	"result := MMatrix 
		newRows: nbRows 
		columns: anotherMatrix nbColumns.
	result fromContents: resultArray."
	"-----"
	result := MMatrix 
		newHandle: resultArray 
		rows: nbRows 
		columns: anotherMatrix nbColumns.
	
	^ result
]

{ #category : #private }
MMatrix >> dot: array1 with: m1_nb_rows with: m1_nb_columns with: array2 with: m2_nb_rows with: m2_nb_columns in: res [

	^ self 
		ffiCall: #(void dot(
			void *array1, 
			int m1_nb_rows, 
			int m1_nb_columns, 
         void *array2, 
			int m2_nb_rows, 
			int m2_nb_columns, 
			void *res) ) 
		module: '/tmp/matrix.dylib'

]

{ #category : #accessing }
MMatrix >> fromContents: content [
	"Initialize the matrix with a linear content"
	self assert: [ content size = (nbColumns * nbRows) ] description: 'size mismatch'.
	content doWithIndex: [ :v :i | array at: i put: v ]
]

{ #category : #initialization }
MMatrix >> initializeHandle: aHandle rows: numRows columns: numColumns [

	self initialize.
	nbRows := numRows.
	nbColumns := numColumns.
	array := self newArrayFromHandle: aHandle
]

{ #category : #initialization }
MMatrix >> initializeRows: numRows columns: numColumns [
	self initialize.
	nbRows := numRows.
	nbColumns := numColumns.
	array := self newArray
]

{ #category : #accessing }
MMatrix >> max [
	^ array max
]

{ #category : #accessing }
MMatrix >> multiplyPerElement: mat [
	"
	| v1 v2 |
	v1 := MMatrix newFromVector: #(1 2 3).
	v2 := MMatrix newFromVector: #(10 20 30).
	v1 multiplyPerElement: v2	
	"
	| r |
	self assert: [ nbRows = mat nbRows ].
	self assert: [ nbColumns = mat nbColumns ].
	r := MMatrix newRows: nbRows columns: nbColumns.
	r fromContents: (self array asArray with: mat array asArray collect: [ :a :b | a * b ]).
	^ r
]

{ #category : #accessing }
MMatrix >> nbColumns [
	"Number of columns defined in the matrix"
	^ nbColumns
]

{ #category : #accessing }
MMatrix >> nbRows [
	"Number of rows defined in the matrix"
	^ nbRows
]

{ #category : #private }
MMatrix >> newArray [
	"Create an array used to contains the store the matrix content"
	^ FFIExternalArray 
		newType: 'double' 
		size: nbColumns * nbRows
]

{ #category : #private }
MMatrix >> newArrayFromHandle: aHandle [

	^ FFIExternalArray 
		fromHandle: aHandle 
		type: 'double' 
		size: nbColumns * nbRows
]

{ #category : #private }
MMatrix >> pharoMultiply: m1 with: m1_nb_rows with: m1_nb_columns with: m2 with: m2_nb_rows with: m2_nb_columns in: res [
	0 to: (m2_nb_columns - 1) do: [ :col |
		0 to: (m1_nb_rows - 1) do: [ :row |
			| tmp |
			tmp := 0.
			0 to: m2_nb_rows - 1 do: [ :k |
				"Transcript show: i asString, ' ', j asString, ' ', k asString; cr."
				"self halt."
				"res[row][col] += m1[row][k] * m2[k][col]"
				tmp := tmp + ((m1 at: (row * m1_nb_columns + k) + 1) * (m2 at: (k * m2_nb_columns + col) + 1))
			].
			res at: (row * m2_nb_columns + col) + 1 put: tmp
		] 
	].
	
]

{ #category : #printing }
MMatrix >> printOn: aStream [
	"Print the matrix in the stream, with 4 decimal for each value"
	self printOn: aStream round: 4
]

{ #category : #printing }
MMatrix >> printOn: aStream round: nbDecimals [
	"Print the receiver matrix into a stream. All numerical value are truncated to a fixed number of decimals"
	aStream nextPutAll: '('.
	(1 to: nbRows) 
		do: [ :r | 
				(self atRow: r) 
					do: [ :each | aStream nextPutAll: (each round: nbDecimals) printString ] 
					separatedBy: [ aStream space ]]
		separatedBy: [ aStream cr ].
	aStream nextPutAll: ' )'.
]

{ #category : #accessing }
MMatrix >> random [
	"Fill the matrix with random numbers"
	^ self random: Random new
]

{ #category : #accessing }
MMatrix >> random: randomNumberGenerator [
	"Fill the matrix with random numbers. Takes a random number generator as argument"
	self fromContents: ((1 to: nbRows * nbColumns) collect: [ :vv | randomNumberGenerator next ])

]

{ #category : #private }
MMatrix >> readme [

"
You need to have the following C function in a file, called mat.c

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
void dot(double *m1, int m1_nb_rows, int m1_nb_columns, 
              double *m2, int m2_nb_rows, int m2_nb_columns, 
              double *res) { 
    int col, row, k; 
    for (col = 0; col < m2_nb_columns; col++) { 
        for (row = 0; row < m1_nb_rows; row++) { 
				  double tmp = 0;
            for (k = 0; k < m2_nb_rows; k++) 
					   tmp += m1[row * m1_nb_columns + k] * m2[k * m2_nb_columns + col];
				  res[row * m2_nb_columns + col] = tmp;
} } } 

void sub(double *m1, int nb_rows, int nb_columns, 
              	double *m2, double *res) {
   int col, row; 
    for (col = 0; col < nb_columns; col++) { 
        for (row = 0; row < nb_rows; row++) { 
			   res[row * nb_columns + col] = 
				  m1[row * nb_columns + col] - m2[row * nb_columns + col];
} } } 

void add(double *m1, int nb_rows, int nb_columns, 
              	double *m2, double *res) {
   int col, row; 
    for (col = 0; col < nb_columns; col++) { 
        for (row = 0; row < nb_rows; row++) { 
			   res[row * nb_columns + col] = 
				  m1[row * nb_columns + col] + m2[row * nb_columns + col];
} } } 
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=


You then need to compile the file using the following instruction, to be performed in a terminal:
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
gcc -dynamiclib -o matrix.dylib matrix.c
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

This will create a file called matrix.dylib
"
]

{ #category : #arithmetic }
MMatrix >> stretchToColumns: nbOfColumns [
	"
	| x |
	x := MMatrix newFromVector: #(1 2 3 4).
	x stretchToColumns: 5.
	"
	| content result |
	content := OrderedCollection new.
	1 to: nbRows do: [ :row |
		1 to: nbOfColumns do: [ :columns |
			content add: (self at: 1 @ row)
		]
	].
	result := MMatrix newRows: nbRows columns: nbOfColumns.
	result fromContents: content.
	^ result
]

{ #category : #arithmetic }
MMatrix >> sub: anotherMatrix [
	| result resultArray |
	nbColumns = anotherMatrix nbColumns ifFalse: [self error: 'dimensions do not conform'].
	nbRows = anotherMatrix nbRows ifFalse: [self error: 'dimensions do not conform'].
	
	resultArray := ByteArray new: (nbRows * anotherMatrix nbColumns * 8).
	
	self assert: [ nbRows * nbColumns = array size ].
	self assert: [ anotherMatrix nbRows * anotherMatrix nbColumns = anotherMatrix array size ].
	self assert: [ nbRows * anotherMatrix nbColumns * 8 = resultArray size ].
	
	self 
		sub: self array getHandle 
		with: nbRows 
		with: nbColumns 
		with: anotherMatrix array getHandle
		in: resultArray.
	
	result := MMatrix 
		newHandle: resultArray 
		rows: nbRows 
		columns: nbColumns.
	
	^ result
]

{ #category : #private }
MMatrix >> sub: m1 with: nb_rows with: nb_columns with: m2 in: res [

	^ self 
		ffiCall: #(void sub(double *m1, int nb_rows, int nb_columns, 
              	double *m2, 
              	double *res)) 
		module: 'matrix.dylib'

]

{ #category : #enumerating }
MMatrix >> sum [
	"Return the sum of the matrix values"
	| sum |
	sum := 0.
	1 to: nbRows do: [ :y |
		1 to: nbColumns do: [ :x |
			sum := sum + (self at: x @ y)
		] 
	].
	^ sum
]

{ #category : #enumerating }
MMatrix >> sumKeepDimension [
	"Vertical summing
	| x |
	x := MMatrix newRows: 3 columns: 2.
	x fromContents: (1 to: 6).
	x sumKeepDimension
	"
	| result sum |
	result := MMatrix newRows: nbRows columns: 1.
	1 to: nbRows do: [ :y |
		sum := 0.
		1 to: nbColumns do: [ :x |
			sum := sum + (self at: x @ y)
		].
		result at: 1 @ y put: sum
	].
	^ result
]

{ #category : #private }
MMatrix >> transposed [
	"Transpose the matrix"
	| result |
	result := MMatrix newRows: nbColumns columns: nbRows.
	1 to: nbRows do: [ :row |
		1 to: nbColumns do: [ :column |
			result at: row @ column put: (self at: column @ row)
		]
	].
	^ result
	
	"
	| m |
	m := MMatrix newRows: 2 columns: 4.
	m fromContents: (1 to: 8).
	m transposed
	
	"


	"
	From https://rosettacode.org/wiki/Matrix_transposition#C
	
void transpose(void *dest, void *src, int src_h, int src_w)
{
	int i, j;
	double (*d)[src_h] = dest, (*s)[src_w] = src;
	for (i = 0; i < src_h; i++)
		for (j = 0; j < src_w; j++)
			d[j][i] = s[i][j];
}
"
"import java.util.Arrays;
public class Transpose{
       public static void main(String[] args){
               double[][] m = {{1, 1, 1, 1},
                               {2, 4, 8, 16},
                               {3, 9, 27, 81},
                               {4, 16, 64, 256},
                               {5, 25, 125, 625}};
               double[][] ans = new double[m[0].length][m.length];
               for(int rows = 0; rows < m.length; rows++){
                       for(int cols = 0; cols < m[0].length; cols++){
                               ans[cols][rows] = m[rows][cols];
                       }
               }
               for(double[] i:ans){//2D arrays are arrays of arrays
                       System.out.println(Arrays.toString(i));
               }
       }
}
"


]
