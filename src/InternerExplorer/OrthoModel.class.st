Class {
	#name : 'OrthoModel',
	#superclass : 'Object',
	#instVars : [
		'idIndex',
		'records',
		'current',
		'stride'
	],
	#category : 'InternerExplorer',
	#package : 'InternerExplorer'
}

{ #category : 'as yet unclassified' }
OrthoModel class >> fromFile: aPath [
  | json model |
  json := NeoJSONReader fromString: (aPath asFileReference contents).
  model := self new.
  model stride: (json at: 'stride_words' ifAbsent: [ 0 ]).
  model records: (json at: 'records' ifAbsent: [ #() ]).
  model buildIndex.
  model current: (model records ifEmpty: [ nil ] ifNotEmpty: [ model records first ]).
  ^ model

]

{ #category : 'as yet unclassified' }
OrthoModel >> buildIndex [
  idIndex := Dictionary new.
  records do: [:rec | idIndex at: (rec at: 'ortho_id') put: rec ].

]

{ #category : 'as yet unclassified' }
OrthoModel >> candidates [
  ^ current ifNil: [ #() ] ifNotNil: [ current at: 'candidates' ifAbsent: [ #() ] ].

]

{ #category : 'as yet unclassified' }
OrthoModel >> current [ ^ current.

]

{ #category : 'as yet unclassified' }
OrthoModel >> current: aRec [ current := aRec.

]

{ #category : 'as yet unclassified' }
OrthoModel >> forbiddenKeys [
  ^ self current
    ifNil: [ #() ]
    ifNotNil: [ self current at: 'forbidden_keys' ifAbsent: [ #() ] ].

]

{ #category : 'as yet unclassified' }
OrthoModel >> gtOrthoFor: aView [
  <gtView>
  ^ aView explicit
    title: 'Ortho';
    priority: 10;
    stencil: [
      | root dispLabel dispElement reqLabel reqElement forbLabel forbElement candLabel candElement displayString |

      displayString := self current at: 'display' ifAbsent: ['(no display)'].

      dispLabel := BlTextElement new
        text: 'Ortho' asRopedText;
        constraintsDo: [:c | c horizontal fitContent. c vertical fitContent ].

      dispElement := BlElement new
        layout: BlLinearLayout vertical;
        constraintsDo: [:c | c horizontal fitContent. c vertical fitContent ].
      displayString lines do: [:line |
        dispElement addChild: (BlTextElement new
          text: line asRopedText;
          constraintsDo: [:c | c horizontal fitContent. c vertical fitContent ])].

      reqLabel := BlTextElement new
        text: 'Required keys' asRopedText;
        constraintsDo: [:c | c horizontal fitContent. c vertical fitContent ].
      reqElement := (self requiredKeys isEmpty
        ifTrue: [ BlTextElement new text: '(none)' asRopedText ]
        ifFalse: [
          (GtPhlowColumnedListView new
            title: 'Required';
            items: [ self requiredKeys ];
            column: 'Key' text: [:k |
              (k respondsTo: #joinSeparatedBy:)
                ifTrue: [ k joinSeparatedBy: ' ' ]
                ifFalse: [ k asString ] ]) asElement
        ]).

      forbLabel := BlTextElement new
        text: 'Forbidden keys' asRopedText;
        constraintsDo: [:c | c horizontal fitContent. c vertical fitContent ].
      forbElement := (self forbiddenKeys isEmpty
        ifTrue: [ BlTextElement new text: '(none)' asRopedText ]
        ifFalse: [
          (GtPhlowColumnedListView new
            title: 'Forbidden';
            items: [ self forbiddenKeys ];
            column: 'Key' text: [:k |
              (k respondsTo: #joinSeparatedBy:)
                ifTrue: [ k joinSeparatedBy: ' ' ]
                ifFalse: [ k asString ] ]) asElement
        ]).

      candLabel := BlTextElement new
        text: 'Candidates' asRopedText;
        constraintsDo: [:c | c horizontal fitContent. c vertical fitContent ].
      candElement := (GtPhlowColumnedListView new
        title: 'Candidates';
        items: [ self candidates ];
        column: 'Word' text: [:c | c at: 'word' ifAbsent: [''] ];
        column: 'Min input' text: [:c | (c at: 'min_input' ifAbsent: [0]) asString ];
        column: 'Child id' text: [:c | (c at: 'child_id' ifAbsent: [0]) asString ];
        send: [:c |
          self selectById: (c at: 'child_id' ifAbsent: [ nil ]).
          self ]) asElement.

      root := BlElement new
        layout: BlLinearLayout vertical;
        constraintsDo: [:c | c horizontal matchParent. c vertical matchParent ];
        addChild: dispLabel;
        addChild: dispElement;
        addChild: (BlElement new height: 8);
        addChild: reqLabel;
        addChild: reqElement;
        addChild: (BlElement new height: 4);
        addChild: forbLabel;
        addChild: forbElement;
        addChild: (BlElement new height: 8);
        addChild: candLabel;
        addChild: candElement;
        yourself.
      root ]

]

{ #category : 'as yet unclassified' }
OrthoModel >> idIndex [ ^ idIndex.
]

{ #category : 'as yet unclassified' }
OrthoModel >> records [ 
^ records.

]

{ #category : 'as yet unclassified' }
OrthoModel >> records: aCollection [ records := aCollection.

]

{ #category : 'as yet unclassified' }
OrthoModel >> requiredKeys [
  ^ current ifNil: [ #() ] ifNotNil: [ current at: 'required_keys' ifAbsent: [ #() ] ].

]

{ #category : 'as yet unclassified' }
OrthoModel >> selectById: anId [
  current := idIndex at: anId ifAbsent: [ current ].
  ^ current

]

{ #category : 'as yet unclassified' }
OrthoModel >> stride [ ^ stride.

]

{ #category : 'as yet unclassified' }
OrthoModel >> stride: aNumber [ stride := aNumber.

]
