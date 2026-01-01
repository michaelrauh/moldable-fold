Class {
	#name : 'InternerKey',
	#superclass : 'Object',
	#instVars : [
		'name',
		'completions',
		'words',
		'chunkPath'
	],
	#category : 'InternerExplorer',
	#package : 'InternerExplorer'
}

{ #category : 'as yet unclassified' }
InternerKey class >> fromName: aString completions: aCollection [
  ^ self new name: aString completions: aCollection

]

{ #category : 'as yet unclassified' }
InternerKey class >> fromName: aName words: someWords chunkPath: aPath [
  ^ self new
    name: aName;
    words: someWords;
    chunkPath: aPath;
    completions: #();
    yourself

]

{ #category : 'as yet unclassified' }
InternerKey >> chunkPath [
	^ chunkPath
]

{ #category : 'as yet unclassified' }
InternerKey >> chunkPath: p [
	chunkPath := p
]

{ #category : 'as yet unclassified' }
InternerKey >> completions [
	^ completions
]

{ #category : 'as yet unclassified' }
InternerKey >> ensureCompletionsLoaded [
  "Fill completions from the chunk file if they are empty."
  | json entry |
  completions ifNotEmpty: [ ^ self ].
  (self chunkPath isNil or: [ self chunkPath isEmpty ]) ifTrue: [ ^ self ].

  json := NeoJSONReader fromString: (self chunkPath asFileReference contents).
  entry := (json at: 'keys' ifAbsent: [ #() ]) detect: [ :each |
    (InternerModel joinWords: (each at: 'words' ifAbsent: [ #() ])) = self name
  ] ifNone: [ nil ].
  entry ifNotNil: [
    completions := entry at: 'completions' ifAbsent: [ #() ] ].
  ^ self

]

{ #category : 'as yet unclassified' }
InternerKey >> gtCompletionsFor: aView [
  <gtView>
  self ensureCompletionsLoaded.
  ^ aView columnedList
      title: 'Completions';
      items: [ completions ];
      column: 'Word' text: [:c | c at: 'word' ifAbsent: [ c ]];
      column: 'Pos'  text: [:c | (c at: 'first_pos' ifAbsent: '') asString ].

]

{ #category : 'as yet unclassified' }
InternerKey >> name [
  ^ name

]

{ #category : 'as yet unclassified' }
InternerKey >> name: aName [ 
]

{ #category : 'as yet unclassified' }
InternerKey >> name: aString completions: aCollection [
  name := aString.
  completions := aCollection.
  ^ self

]

{ #category : 'as yet unclassified' }
InternerKey >> words [ 
^ words
]

{ #category : 'as yet unclassified' }
InternerKey >> words: w [
	words := w
]
