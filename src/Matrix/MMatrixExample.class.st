Class {
	#name : #MMatrixExample,
	#superclass : #Object,
	#category : #Matrix
}

{ #category : #examples }
MMatrixExample >> benchmark [
"
[ self new benchmark ] timeToRun 

0:00:00:07.933  => Only the multiplication in C
0:00:00:06.058  => With substraction and multiplication in C


"


| n din h dout r x y w1 w2 learningRate losses hh hrelu ypred loss gradYPred gradW2 gradHRelu gradH gradW1 |
n := 64.
din := 100.
h := 20.
dout := 5.

r := Random seed: 42.

x := MMatrix newRows: n columns: din.
x fromContents: ((1 to: n * din) collect: [ :i | r next ]).
y := MMatrix newRows: n columns: dout.
y fromContents: ((1 to: n * dout) collect: [ :i | r next ]).

w1 := MMatrix newRows: din columns: h.
w1 fromContents: ((1 to: din * h) collect: [ :i | r next ]).
w2 := MMatrix newRows: h columns: dout.
w2 fromContents: ((1 to: h * dout) collect: [ :i | r next ]).

learningRate := 1e-6.

losses := OrderedCollection new.

1500 timesRepeat: [ 
	hh := x +* w1.
	hrelu := hh collect: [ :v | v max: 0 ].
	ypred := hrelu +* w2.
	
	"Compute and print loss"
	loss := ((ypred - y) collect: [:vv | vv * vv ]) sum.
	losses add: loss.
	
	"Backprop to compute gradients of w2 and w2 with respect to loss"
	gradYPred := (ypred - y) * 2.0.
	gradW2 := hrelu transposed +* gradYPred.
	gradHRelu := gradYPred +* w2 transposed.
	gradH := gradHRelu collect: [ :v | v max: 0 ].
	gradW1 := x transposed +* gradH.
	
	w1 := w1 - (gradW1 * learningRate).
	w2 := w2 - (gradW2 * learningRate) 
].

]

{ #category : #examples }
MMatrixExample >> example01 [

"
n := 64.
din := 1000.
h := 100.
dout := 10.
"

| n din h dout r x y w1 w2 learningRate losses hh hrelu ypred loss gradYPred gradW2 gradHRelu gradH gradW1 g d |
n := 8.
din := 10.
h := 20.
dout := 5.

r := Random seed: 42.
"x := Array2D rows: n columns: din tabulate: [ :i :j | r next * 4 -2 ].
y := Array2D rows: n columns: dout tabulate: [ :i :j | r next * 4 -2 ].

w1 := Array2D rows: din columns: h tabulate: [ :i :j | r next * 4 -2 ].
w2 := Array2D rows: h columns: dout tabulate: [ :i :j | r next * 4 -2 ].
"

x := MMatrix newRows: n columns: din.
x fromContents: ((1 to: n * din) collect: [ :i | r next ]).
y := MMatrix newRows: n columns: dout.
y fromContents: ((1 to: n * dout) collect: [ :i | r next ]).

w1 := MMatrix newRows: din columns: h.
w1 fromContents: ((1 to: din * h) collect: [ :i | r next ]).
w2 := MMatrix newRows: h columns: dout.
w2 fromContents: ((1 to: h * dout) collect: [ :i | r next ]).

learningRate := 1e-6.

losses := OrderedCollection new.

1500 timesRepeat: [ 
	hh := x +* w1.
	hrelu := hh collect: [ :v | v max: 0 ].
	ypred := hrelu +* w2.
	
	"Compute and print loss"
	loss := ((ypred - y) collect: [:vv | vv * vv ]) sum.
	losses add: loss.
	
	"Backprop to compute gradients of w2 and w2 with respect to loss"
	gradYPred := (ypred - y) * 2.0.
	gradW2 := hrelu transposed +* gradYPred.
	gradHRelu := gradYPred +* w2 transposed.
	gradH := gradHRelu collect: [ :v | v max: 0 ].
	gradW1 := x transposed +* gradH.
	
	w1 := w1 - (gradW1 * learningRate).
	w2 := w2 - (gradW2 * learningRate) 
].

"g := RTGrapher new.
d := RTData new.
d points: losses.
d y: #yourself.
g add: d.
g"
]

{ #category : #examples }
MMatrixExample >> example02 [
"
n := 64.
din := 1000.
h := 100.
dout := 10.
"

| n din h dout r x y w1 w2 learningRate losses hh hrelu ypred loss gradYPred gradW2 gradHRelu gradH gradW1 g d |
n := 8.
din := 10.
h := 20.
dout := 5.

r := Random seed: 42.
"x := Array2D rows: n columns: din tabulate: [ :i :j | r next * 4 -2 ].
y := Array2D rows: n columns: dout tabulate: [ :i :j | r next * 4 -2 ].

w1 := Array2D rows: din columns: h tabulate: [ :i :j | r next * 4 -2 ].
w2 := Array2D rows: h columns: dout tabulate: [ :i :j | r next * 4 -2 ].
"

x := Array2D rows: n columns: din tabulate: [ :i :j | r next ].
y := Array2D rows: n columns: dout tabulate: [ :i :j | r next ].

w1 := Array2D rows: din columns: h tabulate: [ :i :j | r next  ].
w2 := Array2D rows: h columns: dout tabulate: [ :i :j | r next ].


learningRate := 1e-6.

losses := OrderedCollection new.

1500 timesRepeat: [ 
	hh := x +* w1.
	hrelu := hh collect: [ :v | v max: 0 ].
	ypred := hrelu +* w2.
	
	"Compute and print loss"
	loss := ((ypred - y) collect: [:vv | vv * vv ]) sum.
	losses add: loss.
	
	"Backprop to compute gradients of w2 and w2 with respect to loss"
	gradYPred := 2.0 * (ypred - y).
	gradW2 := hrelu t +* gradYPred.
	gradHRelu := gradYPred +* w2 t.
	gradH := gradHRelu collect: [ :v | v max: 0 ].
	gradW1 := x t +* gradH.
	
	w1 := w1 - (learningRate * gradW1).
	w2 := w2 - (learningRate * gradW2).
].

"g := RTGrapher new.
d := RTData new.
d points: losses.
d y: #yourself.
g add: d.
g"
]

{ #category : #examples }
MMatrixExample >> example03 [
"
self new example03 

"


| n din h dout r x y w1 w2 learningRate losses hh hrelu ypred loss gradYPred gradW2 gradHRelu gradH gradW1 |
n := 1.
din := 2.
h := 3.
dout := 2.

r := Random seed: 42.

x := MMatrix newRows: n columns: din.
x fromContents: ((1 to: n * din) collect: [ :i | r next ]).
y := MMatrix newRows: n columns: dout.
y fromContents: ((1 to: n * dout) collect: [ :i | r next ]).

w1 := MMatrix newRows: din columns: h.
w1 fromContents: ((1 to: din * h) collect: [ :i | r next ]).
w2 := MMatrix newRows: h columns: dout.
w2 fromContents: ((1 to: h * dout) collect: [ :i | r next ]).

learningRate := 1e-6.

losses := OrderedCollection new.

 
	hh := x +* w1.
	hrelu := hh collect: [ :v | v max: 0 ].
	ypred := hrelu +* w2.
	
	"Compute and print loss"
	loss := ((ypred - y) collect: [:vv | vv * vv ]) sum.
	losses add: loss.
	
	"Backprop to compute gradients of w2 and w2 with respect to loss"
	gradYPred := (ypred - y) * 2.0.
	gradW2 := hrelu transposed +* gradYPred.
	gradHRelu := gradYPred +* w2 transposed.
	gradH := gradHRelu collect: [ :v | v max: 0 ].
	gradW1 := x transposed +* gradH.
	
	w1 := w1 - (gradW1 * learningRate).
	w2 := w2 - (gradW2 * learningRate) 


]

{ #category : #examples }
MMatrixExample >> example04WithSigmoid [
"
self new example03 

"


| n din h dout r x y w1 w2 learningRate losses hh hrelu ypred loss gradYPred gradW2 gradHRelu gradH gradW1 |
n := 1.
din := 2.
h := 3.
dout := 2.

r := Random seed: 42.

x := MMatrix newRows: n columns: din.
x fromContents: ((1 to: n * din) collect: [ :i | r next ]).
y := MMatrix newRows: n columns: dout.
y fromContents: ((1 to: n * dout) collect: [ :i | r next ]).

w1 := MMatrix newRows: din columns: h.
w1 fromContents: ((1 to: din * h) collect: [ :i | r next ]).
w2 := MMatrix newRows: h columns: dout.
w2 fromContents: ((1 to: h * dout) collect: [ :i | r next ]).

learningRate := 0.1.

losses := OrderedCollection new.

 1500 timesRepeat: [ 
	hh := x +* w1.
	hrelu := hh collect: [ :v | 1 / (1 + (v negated exp)) ].
	ypred := hrelu +* w2.
	
	"Compute and print loss"
	loss := ((ypred - y) collect: [:vv | vv * vv ]) sum.
	losses add: loss.
	
	"Backprop to compute gradients of w2 and w2 with respect to loss"
	gradYPred := (ypred - y) * 2.0.
	gradW2 := hrelu transposed +* gradYPred.
	gradHRelu := gradYPred +* w2 transposed.
	gradH := gradHRelu collect: [ :v | v * (1 - v) ].
	gradW1 := x transposed +* gradH.
	
	w1 := w1 - (gradW1 * learningRate).
	w2 := w2 - (gradW2 * learningRate) 
].
losses

]
