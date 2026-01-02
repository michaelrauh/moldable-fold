Class {
	#name : 'InternerKey',
	#superclass : 'Object',
	#instVars : [
		'name',
		'completions',
		'words',
		'chunkPath',
		'displayCutoff'
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
	^ completions ifNil: [ completions := #() ].
]

{ #category : 'as yet unclassified' }
InternerKey >> displayCutoff [ 
^ displayCutoff ifNil: [ SmallInteger maxVal ].

]

{ #category : 'as yet unclassified' }
InternerKey >> displayCutoff: aNumber [
  displayCutoff := aNumber.


]

{ #category : 'as yet unclassified' }
InternerKey >> ensureCompletionsLoaded [
  | json entry targetWords |
  completions ifNotNil: [ ^ completions ].
  chunkPath ifNil: [ ^ completions := #() ].

  json := NeoJSONReader fromString: (chunkPath asFileReference contents).
  targetWords := self name substrings: ' '.
  entry := (json at: 'keys' ifAbsent: [ #() ]) detect: [:each |
    (each at: 'words' ifAbsent: [ #() ]) = targetWords
  ] ifNone: [ nil ].
  entry ifNil: [ ^ completions := #() ].

  completions := (entry at: 'completions' ifAbsent: [ #() ]) collect: [:c |
    { c at: 'word' ifAbsent: [''].
      c at: 'first_word_pos' ifAbsent: [ 0 ] } ].
  ^ completions

]

{ #category : 'as yet unclassified' }
InternerKey >> filteredCompletionsUpTo: cutoff [
  ^ self completions select: [:c | c second <= cutoff]

]

{ #category : 'as yet unclassified' }
InternerKey >> gtCompletionsFor: aView [
  <gtView>
  self refreshCompletions.
  ^ aView columnedList
    title: 'Completions';
    items: [ self filteredCompletionsUpTo: self displayCutoff ];
    column: 'Word' text: [:c | c first];
    column: 'Pos'  text: [:c | c second asString ]

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
InternerKey >> refreshCompletions [
  completions := nil.
  ^ self ensureCompletionsLoaded

]

{ #category : 'as yet unclassified' }
InternerKey >> words [ 
^ words
]

{ #category : 'as yet unclassified' }
InternerKey >> words: w [
	words := w
]
