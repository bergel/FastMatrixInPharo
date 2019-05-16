Class {
	#name : #MMatrixTest,
	#superclass : #TestCase,
	#category : #Matrix
}

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
	self assert: (m +* m2) array asFloatArray equals: #(27 30 33 61 68 75 95 106 117) asFloatArray
]
