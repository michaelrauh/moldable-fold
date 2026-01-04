Class {
	#name : 'OrthoModel',
	#superclass : 'Object',
	#instVars : [
		'idIndex',
		'records',
		'current',
		'stride',
		'internerModel'
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
OrthoModel >> baseDir [
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
      | displayString dispBox reqElement forbElement candElement root |

      displayString := self current at: 'display' ifAbsent: [ '(no display)' ].

      dispBox := BlElement new
        layout: BlLinearLayout vertical;
        constraintsDo: [:c | c horizontal fitContent. c vertical fitContent ].
      displayString lines do: [:line |
        dispBox addChild: (BlTextElement new
          text: line asRopedText;
          constraintsDo: [:c | c horizontal fitContent. c vertical fitContent ]) ].

      reqElement := (self requiredKeys isEmpty
        ifTrue: [ BlTextElement new text: '(none)' asRopedText ]
        ifFalse: [
          (GtPhlowColumnedListView new
            title: 'Required';
            items: [ self requiredKeys ];
            column: 'Key' text: [:k | self keyNameFor: k ];
            send: [:k |
              | name ik |
              name := self keyNameFor: k.
              self internerModel ifNotNil: [:im |
                ik := im findKeyNamed: name.
                ik ifNotNil: [ im selected: ik ] ].
              ik ]) asElement ]).

      forbElement := (self forbiddenKeys isEmpty
        ifTrue: [ BlTextElement new text: '(none)' asRopedText ]
        ifFalse: [
          (GtPhlowColumnedListView new
            title: 'Forbidden';
            items: [ self forbiddenKeys ];
            column: 'Key' text: [:k | self keyNameFor: k ]) asElement ]).

      candElement := (GtPhlowColumnedListView new
        title: 'Candidates';
        items: [ self candidates ];
        column: 'Word' text: [:c | c at: 'word' ifAbsent: [''] ];
        column: 'Min input' text: [:c | (c at: 'min_input' ifAbsent: [0]) asString ];
        column: 'Child id' text: [:c | (c at: 'child_id' ifAbsent: [0]) asString ];
        send: [:c | self orthoForId: (c at: 'child_id' ifAbsent: [ nil ]) ]) asElement.

      root := BlElement new
        layout: BlLinearLayout vertical;
        constraintsDo: [:c | c horizontal matchParent. c vertical matchParent ];
        addChild: (BlTextElement new text: 'Ortho' asRopedText);
        addChild: dispBox;
        addChild: (BlElement new height: 8);
        addChild: (BlTextElement new text: 'Required keys' asRopedText);
        addChild: reqElement;
        addChild: (BlElement new height: 4);
        addChild: (BlTextElement new text: 'Forbidden keys' asRopedText);
        addChild: forbElement;
        addChild: (BlElement new height: 8);
        addChild: (BlTextElement new text: 'Candidates' asRopedText);
        addChild: candElement;
        yourself ]

]

{ #category : 'as yet unclassified' }
OrthoModel >> idIndex [ ^ idIndex.
]

{ #category : 'accessing' }
OrthoModel >> idIndex: anObject [
	idIndex := anObject
]

{ #category : 'as yet unclassified' }
OrthoModel >> internerModel [
  ^ internerModel

]

{ #category : 'as yet unclassified' }
OrthoModel >> internerModel: aModel [
  internerModel := aModel
]

{ #category : 'as yet unclassified' }
OrthoModel >> keyNameFor: aKey [
  (aKey isArray or: [aKey isKindOf: SequenceableCollection]) ifTrue: [
    ^ String streamContents: [:s |
      aKey doWithIndex: [:w :i | s nextPutAll: w asString. i < aKey size ifTrue: [ s space ] ] ] ].
  ^ aKey asString

]

{ #category : 'as yet unclassified' }
OrthoModel >> orthoById: anId [
  anId ifNil: [ ^ nil ].
  ^ (self idIndex at: anId ifAbsent: [
       self idIndex at: anId asString ifAbsent: [ nil ] ])

]

{ #category : 'as yet unclassified' }
OrthoModel >> orthoForId: anId [
  | childDict child |
  childDict := self orthoById: anId.
  childDict ifNil: [ ^ nil ].
  child := self class new.
  child idIndex: self idIndex.
  child internerModel: self internerModel.
  child stride: self stride.  "omit if you don’t use stride"
  child current: childDict.
  ^ child

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
