Class {
	#name : #MMatrixTest,
	#superclass : #TestCase,
	#category : #Matrix
}

{ #category : #tests }
MMatrixTest >> testAddition [
	| m |
	m := MMatrix newFromArrays: #(#(1 2 3) #(4 5 6)). 
	self assert: (m + m) asStructuredArray equals: #(#(2.0 4.0 6.0) #(8.0 10.0 12.0))
]

{ #category : #tests }
MMatrixTest >> testAddition2 [
	| m1 m2 |
	m1 := MMatrix newFromArrays: #(#(1 2 3) #(4 5 6)). 
	m2 := MMatrix newFromArrays: #(#(4 5 6) #(1 2 3)).
	self assert: (m1 + m2) asStructuredArray equals: #(#(5.0 7.0 9.0) #(5.0 7.0 9.0))
]

{ #category : #tests }
MMatrixTest >> testDivision [
	| m |
	m := MMatrix newFromArrays: #(#(1 2 3) #(4 5 6)). 
	self assert: (m / 2) asStructuredArray equals: #(#(0.5 1.0 1.5) #(2.0 2.5 3.0))
]

{ #category : #tests }
MMatrixTest >> testMultiplication [
	| a m m2 |
	a := 0.
	m := MMatrix newRows: 3 columns: 2.
	m
		fromContents:
			((1 to: 6)
				collect: [ :i | 
					a := a + 1.
					a ]).
	m2 := MMatrix newRows: 2 columns: 3.
	m2
		fromContents:
			((1 to: 6)
				collect: [ :i | 
					a := a + 1.
					a ]).
	self assert: (m +* m2) asStructuredArray equals: #(27 30 33 61 68 75 95 106 117) asFloatArray.
	
	a := 0.
	self assert: m array asFloatArray equals: ((1 to: 6)
				collect: [ :i | 
					a := a + 1.
					a ]) asFloatArray.
	self assert: m2 array asFloatArray equals: ((1 to: 6)
				collect: [ :i | 
					a := a + 1.
					a ]) asFloatArray
]

{ #category : #tests }
MMatrixTest >> testSubstraction [
	| m1 m2 |
	m1 := MMatrix newFromArrays: #(#(1 2 3) #(4 5 6)). 
	m2 := MMatrix newFromArrays: #(#(4 5 6) #(1 2 3)).
	self assert: (m1 - m2) asStructuredArray equals: #(#(-3.0 -3.0 -3.0) #(3.0 3.0 3.0))
]

{ #category : #tests }
MMatrixTest >> testSumKeepDimension [
	| m expectedResult |
	m := MMatrix newFromArrays: #(#(1.0 2.0) #(3.0 4.0) #(5.0 6.0 )).
	expectedResult := MMatrix newFromArrays: #(#(3.0) #(7.0) #(11.0 )).
	self assert: m sumKeepDimension asStructuredArray equals: expectedResult asStructuredArray
]
