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
	^ self collect: [ :v | v * aFactor ]
]

{ #category : #arithmetic }
MMatrix >> + anotherMatrix [
	| m |
	((nbRows = anotherMatrix nbRows) and: [ nbColumns = anotherMatrix nbColumns ])
		ifTrue: [ ^ self add: anotherMatrix ].
		
	anotherMatrix nbColumns ~= 1 ifTrue: [ self error: 'not a n * 1 vector' ].
	m := anotherMatrix stretchToColumns: nbColumns.
	^ self + m
]

{ #category : #arithmetic }
MMatrix >> +* anotherMatrix [
	^ self multiplyWith: anotherMatrix 
]

{ #category : #arithmetic }
MMatrix >> ++ aVector [

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

{ #category : #'as yet unclassified' }
MMatrix >> - anotherMatrix [
	"PHARO VERSION"
	"| result |
	result := MMatrix newRows: nbRows columns: nbColumns.
	1 to: nbRows do: [ :y |
		1 to: nbColumns do: [ :x |
			result at: x @ y put: ((self at: x @ y) - (anotherMatrix at: x @ y))
		] 
	].
	^ result"
	^ self substracte: anotherMatrix
]

{ #category : #arithmetic }
MMatrix >> / value [
	^ self collect: [ :v | v / 4 ]
]

{ #category : #'as yet unclassified' }
MMatrix >> add: anotherMatrix [
	| result resultArray |
	nbColumns = anotherMatrix nbColumns ifFalse: [self error: 'dimensions do not conform'].
	nbRows = anotherMatrix nbRows ifFalse: [self error: 'dimensions do not conform'].
	
	resultArray := ByteArray new: (nbRows * anotherMatrix nbColumns * 8).
	
	self assert: [ nbRows * nbColumns = array size ].
	self assert: [ anotherMatrix nbRows * anotherMatrix nbColumns = anotherMatrix array size ].
	self assert: [ nbRows * anotherMatrix nbColumns * 8 = resultArray size ].
	
	self 
		add: self array getHandle 
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

{ #category : #'as yet unclassified' }
MMatrix >> array: anArray [
	array := anArray 
]

{ #category : #accessing }
MMatrix >> at: aPoint [
	^ array at: ((aPoint y - 1) * nbColumns + (aPoint x - 1)) + 1
]

{ #category : #accessing }
MMatrix >> at: aPoint put: value [
	array at: ((aPoint y - 1) * nbColumns + (aPoint x - 1)) + 1 put: value asFloat
]

{ #category : #accessing }
MMatrix >> atIndex: index [
	^ array at: index
]

{ #category : #printing }
MMatrix >> atRow: rowNumber [
	(rowNumber between: 1 and: rowNumber)
		ifFalse: [ self error: '1st subscript out of range' ].
	^ (1 to: nbColumns) collect: [ :x | self at: x @ rowNumber ] 
		
]

{ #category : #enumerating }
MMatrix >> collect: aOneArgBlock [
	| result |
	result := MMatrix newRows: nbRows columns: nbColumns.
	1 to: nbRows do: [ :y |
		1 to: nbColumns do: [ :x |
			result at: x @ y put: (aOneArgBlock value: (self at: x @ y))
		] 
	].
	^ result
]

{ #category : #'as yet unclassified' }
MMatrix >> createArray [

	self array: (FFIExternalArray newType: 'double' size: nbColumns * nbRows)
]

{ #category : #accessing }
MMatrix >> fromContents: content [

	self assert: [ content size = (nbColumns * nbRows) ] description: 'size mismatch'.
	content doWithIndex: [ :v :i | array at: i put: v ]
]

{ #category : #initialization }
MMatrix >> initializeHandle: aHandle rows: numRows columns: numColumns [

	self initialize.
	self nbRows: numRows.
	self nbColumns: numColumns.
	array := self newArrayFromHandle: aHandle
]

{ #category : #initialization }
MMatrix >> initializeRows: numRows columns: numColumns [

	self initialize.
	self nbRows: numRows.
	self nbColumns: numColumns.
	array := self newArray
]

{ #category : #accessing }
MMatrix >> max [
	^ array max
]

{ #category : #private }
MMatrix >> multiply: array1 with: m1_nb_rows with: m1_nb_columns with: array2 with: m2_nb_rows with: m2_nb_columns in: res [

	^ self 
		ffiCall: #(void multiply(
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
MMatrix >> multiplyWith: anotherMatrix [
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
		multiply: self array getHandle 
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

{ #category : #accessing }
MMatrix >> nbColumns [
	^ nbColumns
]

{ #category : #private }
MMatrix >> nbColumns: anInt [
	nbColumns := anInt
]

{ #category : #accessing }
MMatrix >> nbRows [
	^ nbRows
]

{ #category : #private }
MMatrix >> nbRows: anInt [
	nbRows := anInt
]

{ #category : #private }
MMatrix >> newArray [

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

	self printOn: aStream round: 4
]

{ #category : #printing }
MMatrix >> printOn: aStream round: nbDecimals [

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
	^ self random: Random new
]

{ #category : #accessing }
MMatrix >> random: random [
	self fromContents: ((1 to: nbRows * nbColumns) collect: [ :vv | random next ])
	"array := array collect: [ :v | random next ]"
]

{ #category : #private }
MMatrix >> readme [

"

You need to have the following C function in a file, called mat.c

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
void multiply(double *m1, int m1_nb_rows, int m1_nb_columns, 
              double *m2, int m2_nb_rows, int m2_nb_columns, 
              double *res) 
{ 
    int col, row, k; 
    for (col = 0; col < m2_nb_columns; col++) 
    { 
        for (row = 0; row < m1_nb_rows; row++) 
        { 
				double tmp = 0;
            for (k = 0; k < m2_nb_rows; k++) 
					tmp += m1[row * m1_nb_columns + k] * m2[k * m2_nb_columns + col];
				res[row * m2_nb_columns + col] = tmp;
        } 
    } 
} 

void substracte(double *m1, int nb_rows, int nb_columns, 
              	double *m2, 
              	double *res)
{
   int col, row; 
    for (col = 0; col < nb_columns; col++) 
    { 
        for (row = 0; row < nb_rows; row++) 
        { 
			res[row * nb_columns + col] = 
				m1[row * nb_columns + col] - m2[row * nb_columns + col];
        } 
    } 

}

void add(double *m1, int nb_rows, int nb_columns, 
              	double *m2, 
              	double *res)
{
   int col, row; 
    for (col = 0; col < nb_columns; col++) 
    { 
        for (row = 0; row < nb_rows; row++) 
        { 
			res[row * nb_columns + col] = 
				m1[row * nb_columns + col] + m2[row * nb_columns + col];
        } 
    } 

}
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=


You then need to compile the file using the following instruction, to be performed in a terminal:
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
gcc -dynamiclib -o matrix.dylib mat.c
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

{ #category : #'as yet unclassified' }
MMatrix >> substracte: anotherMatrix [
	| result resultArray |
	nbColumns = anotherMatrix nbColumns ifFalse: [self error: 'dimensions do not conform'].
	nbRows = anotherMatrix nbRows ifFalse: [self error: 'dimensions do not conform'].
	
	resultArray := ByteArray new: (nbRows * anotherMatrix nbColumns * 8).
	
	self assert: [ nbRows * nbColumns = array size ].
	self assert: [ anotherMatrix nbRows * anotherMatrix nbColumns = anotherMatrix array size ].
	self assert: [ nbRows * anotherMatrix nbColumns * 8 = resultArray size ].
	
	self 
		substracte: self array getHandle 
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
MMatrix >> substracte: m1 with: nb_rows with: nb_columns with: m2 in: res [

	^ self 
		ffiCall: #(void substracte(double *m1, int nb_rows, int nb_columns, 
              	double *m2, 
              	double *res)) 
		module: '/tmp/matrix.dylib'

]

{ #category : #enumerating }
MMatrix >> sum [
	| result sum |
	sum := 0.
	result := MMatrix newRows: nbRows columns: nbColumns.
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

	| result |
	result := MMatrix newRows: nbColumns columns: nbRows.
	1 to: nbRows do: [ :row |
		1 to: nbColumns do: [ :column |
			result at: row @ column put: (self at: column @ row)
		]
	].
	^ result
]
