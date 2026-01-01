Class {
	#name : 'InternerModel',
	#superclass : 'Object',
	#instVars : [
		'vocab',
		'keys',
		'comps',
		'selected',
		'completionCounts',
		'chunkMap'
	],
	#category : 'InternerExplorer',
	#package : 'InternerExplorer'
}

{ #category : 'as yet unclassified' }
InternerModel class >> fromFile: pathString [
  | file parsed |
  file := pathString asFileReference.
  file exists ifFalse: [ self error: 'Not found: ', file pathString ].
  parsed := NeoJSONReader fromString: file contents.
  ^ self fromParsed: parsed
]

{ #category : 'accessing' }
InternerModel class >> fromIndexFile: aPath [
  | json base |
  json := NeoJSONReader fromString: (aPath asFileReference contents).
  base := aPath asFileReference parent.
  ^ self fromParsedIndex: json baseDir: base
]

{ #category : 'as yet unclassified' }
InternerModel class >> fromParsed: parsed [
    | vocab keyEntries keyStrings comps |
    vocab := parsed at: 'vocab' ifAbsent: [ #() ].
    keyEntries := parsed at: 'keys' ifAbsent: [ #() ].
    keyStrings := keyEntries collect: [:e | self joinWords: (e at: 'words' ifAbsent: [ #() ]) ].
    comps := Dictionary new.
    keyEntries withIndexDo: [:entry :idx |
        | key completionEntries |
        key := keyStrings at: idx.
        completionEntries := entry at: 'completions' ifAbsent: [ #() ].
        comps at: key put: completionEntries ].
    ^ self new loadVocab: vocab keys: keyStrings comps: comps

]

{ #category : 'accessing' }
InternerModel class >> fromParsedIndex: parsed [
  | vocab entries |
  vocab := parsed at: 'vocab' ifAbsent: [ #() ].
  entries := parsed at: 'keys' ifAbsent: [ #() ].
  ^ self new loadIndexVocab: vocab keysEntries: entries
]

{ #category : 'accessing' }
InternerModel class >> fromParsedIndex: parsed baseDir: baseDir [
  | vocab entries |
  vocab := parsed at: 'vocab' ifAbsent: [ #() ].
  entries := parsed at: 'keys' ifAbsent: [ #() ].
  ^ self new loadIndexVocab: vocab keysEntries: entries baseDir: baseDir

]

{ #category : 'example' }
InternerModel class >> gtExampleFromFakeFile [
  <gtExample>
  <return: #InternerModel>
  | path ref |
  path := '/Users/michaelrauh/dev/fold/interner_fake_phase0.json'.
  ref := path asFileReference.
  (ref exists and: [ ref isFile ])
    ifTrue: [ ^ self fromFile: path ]
    ifFalse: [ ^ self new ]  "fails closed if the file is missing"

]

{ #category : 'as yet unclassified' }
InternerModel class >> gtExampleFromRealFile [
  <gtExample>
  <return: #InternerModel>
  | path ref |
  path := '/Users/michaelrauh/dev/fold/target/interner_full_export.json'.
  ref := path asFileReference.
  (ref exists and: [ ref isFile ])
    ifTrue: [ ^ self fromFile: path ]
    ifFalse: [ ^ self new ]  "fails closed if the file is missing"

]

{ #category : 'example' }
InternerModel class >> gtExampleTiny [
  <gtExample>
  <return: #InternerModel>
  | data |
  data := Dictionary new.
  data
    at: 'vocab' put: #('that' 'i' 'was' 'alone');
    at: 'keys' put: {
      Dictionary new
        at: 'words' put: #('that' 'i');
        at: 'completions' put: {
          Dictionary new at: 'word' put: 'i'; at: 'word_id' put: 1; at: 'first_pos' put: 3; yourself.
          Dictionary new at: 'word' put: 'was'; at: 'word_id' put: 2; at: 'first_pos' put: 7; yourself };
        yourself.
      Dictionary new
        at: 'words' put: #('i' 'was');
        at: 'completions' put: {
          Dictionary new at: 'word' put: 'alone'; at: 'word_id' put: 4; at: 'first_pos' put: 22; yourself };
        yourself }.
  ^ self fromParsed: data

]

{ #category : 'as yet unclassified' }
InternerModel class >> joinWords: words [
  words ifNil: [ ^ '' ].
  ^ words inject: '' into: [:acc :w |
    acc isEmpty
      ifTrue: [ w asString ]
      ifFalse: [ acc , ' ' , w asString ] ]
]

{ #category : 'accessing' }
InternerModel >> chunkMap [
  chunkMap ifNil: [ chunkMap := Dictionary new ].
  ^ chunkMap

]

{ #category : 'accessing' }
InternerModel >> chunkMap: aDict [
  chunkMap := aDict

]

{ #category : 'accessing' }
InternerModel >> completionCounts [
  completionCounts ifNil: [ completionCounts := Dictionary new ].
  ^ completionCounts

]

{ #category : 'accessing' }
InternerModel >> completionCounts: aDict [
  completionCounts := aDict
]

{ #category : 'as yet unclassified' }
InternerModel >> comps [
	^ comps
]

{ #category : 'as yet unclassified' }
InternerModel >> gtKeysFor: aView [
  <gtView>
  ^ aView columnedList
      title: 'Keys (', self keys size asString, ')';
      items: [ self keys ];
      column: 'Key' text: [ :k | k name ];
      column: '# Completions' text: [ :k | k completions size asString ].

]

{ #category : 'as yet unclassified' }
InternerModel >> gtKeysSortableFor: aView [
  <gtView>
  ^ aView explicit
    title: 'Keys (sortable)';
    priority: 10;
    stencil: [
      | sorter list listElement toolbar root |

      sorter := [:a :b | a name <= b name].

      list := GtPhlowColumnedListView new
        title: 'Keys';
        items: [ self keys ]; "export is already count-desc"
        column: 'Key' text: [:k | k name];
        column: '# Completions' text: [:k | (self completionCounts at: k name ifAbsent: [0]) asString ].

      listElement := list asElement.

      toolbar := BlElement new
        layout: BlLinearLayout horizontal;
        constraintsDo: [:c | c horizontal fitContent. c vertical fitContent].

      "Name ↑"
      toolbar addChild: (BrButton new
        aptitude: BrGlamorousButtonWithLabelAptitude new;
        label: 'Name ↑';
        constraintsDo: [:c | c horizontal fitContent. c vertical fitContent. c margin: (BlInsets all: 4)];
        action: [
          sorter := [:a :b | a name <= b name].
          list items: [ self keys asSortedCollection: sorter ].
          list updateContent: listElement ]).

      "Name ↓"
      toolbar addChild: (BrButton new
        aptitude: BrGlamorousButtonWithLabelAptitude new;
        label: 'Name ↓';
        constraintsDo: [:c | c horizontal fitContent. c vertical fitContent. c margin: (BlInsets all: 4)];
        action: [
          sorter := [:a :b | a name >= b name].
          list items: [ self keys asSortedCollection: sorter ].
          list updateContent: listElement ]).

      "Count ↓ (use exported order)"
      toolbar addChild: (BrButton new
        aptitude: BrGlamorousButtonWithLabelAptitude new;
        label: 'Count ↓';
        constraintsDo: [:c | c horizontal fitContent. c vertical fitContent. c margin: (BlInsets all: 4)];
        action: [
          list items: [ self keys ].  "already count-desc"
          list updateContent: listElement ]).

      "Count ↑ (reverse)"
      toolbar addChild: (BrButton new
        aptitude: BrGlamorousButtonWithLabelAptitude new;
        label: 'Count ↑';
        constraintsDo: [:c | c horizontal fitContent. c vertical fitContent. c margin: (BlInsets all: 4)];
        action: [
          list items: [ self keys reversed ].
          list updateContent: listElement ]).

      root := BlElement new
        layout: BlLinearLayout vertical;
        addChild: toolbar;
        addChild: listElement;
        yourself ].

]

{ #category : 'initialization' }
InternerModel >> initialize [
  super initialize.
  vocab := #().
  keys := #().
  comps := Dictionary new.
  selected := nil.
]

{ #category : 'accessor' }
InternerModel >> keys [
	^ keys
]

{ #category : 'accessing' }
InternerModel >> loadIndexVocab: aVocab keysEntries: entries [
  | summaries |
  self vocab: aVocab.
  self completionCounts: Dictionary new.
  self chunkMap: Dictionary new.
  summaries := entries collect: [:entry |
    | words keyName count chunk |
    words := entry at: 'words' ifAbsent: [ #() ].
    keyName := self class joinWords: words.
    count := entry at: 'completion_count' ifAbsent: [ 0 ].
    chunk := entry at: 'chunk' ifAbsent: [ '' ].
    self completionCounts at: keyName put: count.
    self chunkMap at: keyName put: chunk.
    InternerKey fromName: keyName completions: #() ].
  keys := summaries.
  selected := keys ifEmpty: [ nil ] ifNotEmpty: [ keys first ].
  ^ self

]

{ #category : 'as yet unclassified' }
InternerModel >> loadIndexVocab: aVocab keysEntries: entries baseDir: baseDir [
  | summaries |
  self vocab: aVocab.
  self completionCounts: Dictionary new.
  self chunkMap: Dictionary new.
  summaries := entries collect: [:entry |
    | words keyName count chunkFile chunkPath key |
    words := entry at: 'words' ifAbsent: [ #() ].
    keyName := self class joinWords: words.
    count := entry at: 'completion_count' ifAbsent: [ 0 ].
    chunkFile := entry at: 'chunk' ifAbsent: [ '' ].
    chunkPath := baseDir ifNotNil: [ (baseDir / chunkFile) fullName ] ifNil: [ chunkFile ].
    self completionCounts at: keyName put: count.
    self chunkMap at: keyName put: chunkPath.
    key := InternerKey fromName: keyName completions: #().
    key chunkPath: chunkPath.  "requires chunkPath accessors on InternerKey"
    key ].
  keys := summaries.
  selected := keys ifEmpty: [ nil ] ifNotEmpty: [ keys first ].
  ^ self

]

{ #category : 'as yet unclassified' }
InternerModel >> loadVocab: someVocab keys: someKeys comps: aDict [
  vocab := someVocab.
  comps := aDict.
  keys := someKeys collect: [:k |
    InternerKey fromName: k completions: (aDict at: k ifAbsent: [ #() ])].
  selected := keys ifEmpty: [ nil ] ifNotEmpty: [ keys first ].
  ^ self

]

{ #category : 'accessing' }
InternerModel >> vocab: aVocab [ 
^ vocab ifNil: [ #() ]
]
