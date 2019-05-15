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
MMatrix >> +* anotherMatrix [
	^ self multiplyWith: anotherMatrix 
]

{ #category : #'as yet unclassified' }
MMatrix >> - anotherMatrix [
	"Should be done in C!!!!"
	| result |
	result := MMatrix newRows: nbRows columns: nbColumns.
	1 to: nbRows do: [ :y |
		1 to: nbColumns do: [ :x |
			result at: x @ y put: ((self at: x @ y) - (anotherMatrix at: x @ y))
		] 
	].
	^ result
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

{ #category : #private }
MMatrix >> multiply: array1 with: m1_nb_rows with: m1_nb_columns with: array2 with: m2_nb_rows with: m2_nb_columns in: res [
"// This function multiplies mat1[][] and mat2[][], 
// and stores the result in res[][] 
void multiply(float *m1, int m1_nb_rows, int m1_nb_columns, 
              float *m2, int m2_nb_rows, int m2_nb_columns, 
              float *res) 
{ 
    int i, j, k; 
    for (i = 0; i < m2_nb_columns; i++) 
    { 
        for (j = 0; j < m1_nb_rows; j++) 
        { 
            res[i * m2_nb_columns + j] = 0; 
            for (k = 0; k < m2_nb_rows; k++) 
                res[i * m2_nb_columns + j] += 
                    m1[i * m1_nb_columns + k] * m2[k * m2_nb_columns + j]; 
        } 
    } 
} 
"

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
MMatrix >> multiplyWith: anotherMatrix [
	| result resultArray |
	nbColumns = anotherMatrix nbRows ifFalse: [self error: 'dimensions do not conform'].
	
	resultArray := ByteArray new: (nbRows * anotherMatrix nbColumns * 8).
	
	self assert: [ nbRows * nbColumns = array size ].
	self assert: [ anotherMatrix nbRows * anotherMatrix nbColumns = anotherMatrix array size ].
	self assert: [ nbRows * anotherMatrix nbColumns * 8 = resultArray size ].
	
	self 
		multiply: self array getHandle 
		with: nbRows 
		with: nbColumns 
		with: anotherMatrix array getHandle
		with: anotherMatrix nbRows 
		with: anotherMatrix nbColumns 
		in: resultArray.
	
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

{ #category : #private }
MMatrix >> transposed [
	| result |
	result := MMatrix newRows: nbColumns columns: nbRows.
	result fromContents: array copy.
	^ result
]
