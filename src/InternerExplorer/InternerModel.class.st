Class {
	#name : 'InternerModel',
	#superclass : 'Object',
	#instVars : [
		'vocab',
		'keys',
		'comps',
		'selected',
		'completionCounts',
		'chunkMap',
		'maxSentence',
		'cutoff',
		'maxWords',
		'bucketSizeWords',
		'bucketCounts',
		'orderFiles',
		'ordersBaseDir',
		'orderCache',
		'keysWithCompletionsCache'
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
  | vocab entries model |
  vocab := parsed at: 'vocab' ifAbsent: [ #() ].
  entries := parsed at: 'keys' ifAbsent: [ #() ].
  model := self new.
  model bucketSizeWords: (parsed at: 'bucket_size_words' ifAbsent: [ 500 ]).
  model maxWords: (parsed at: 'max_words' ifAbsent: [ 0 ]).
  model cutoff: model bucketSizeWords.  "start at first bucket (e.g., 500)"
  model orderFiles: (parsed at: 'order_bucket_files' ifAbsent: [ #() ]).
  model ordersBaseDir: baseDir.  "FileReference"
  ^ model loadIndexVocab: vocab keysEntries: entries baseDir: baseDir

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

{ #category : 'as yet unclassified' }
InternerModel >> bucketCount [
  | bsz |
  bsz := (self bucketSizeWords ifNil: [ 0 ]) max: 1.
  ^ ((self maxWords ifNil: [ 0 ]) + (bsz - 1)) // bsz

]

{ #category : 'as yet unclassified' }
InternerModel >> bucketCounts [
  bucketCounts ifNil: [ bucketCounts := Dictionary new ].
  ^ bucketCounts

]

{ #category : 'as yet unclassified' }
InternerModel >> bucketCounts: aDict [
  bucketCounts := aDict

]

{ #category : 'as yet unclassified' }
InternerModel >> bucketSizeWords [
	^ bucketSizeWords ifNil: [ 500 ]

]

{ #category : 'as yet unclassified' }
InternerModel >> bucketSizeWords: n [    
	bucketSizeWords := n

]

{ #category : 'as yet unclassified' }
InternerModel >> bumpBucket: delta [
  | new bsz |
  bsz := (self bucketSizeWords ifNil: [ 0 ]) max: 1.
  new := self clampBucket: (self currentBucketIndex + delta).
  self cutoff: (new + 1) * bsz.
  self selected ifNotNil: [ :k | k displayCutoff: self cutoff ].
  ^ new

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

{ #category : 'as yet unclassified' }
InternerModel >> clampBucket: idx [
  | maxB |
  maxB := (self bucketCount - 1) max: 0.
  ^ (idx max: 0) min: maxB

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
InternerModel >> countForKey: aKey bucket: bucketIndex [
  | buckets |
  buckets := self bucketCounts at: aKey name ifAbsent: [ #() ].
  buckets isEmpty ifTrue: [ ^ 0 ].
  (bucketIndex + 1) > buckets size ifTrue: [ ^ buckets last ].
  ^ buckets at: bucketIndex + 1

]

{ #category : 'as yet unclassified' }
InternerModel >> currentBucketIndex [
  | bsz maxB |
  bsz := (self bucketSizeWords ifNil: [ 0 ]) max: 1.
  maxB := (self bucketCount - 1) max: 0.
  ^ (((self cutoff max: bsz) - 1) // bsz) min: maxB

]

{ #category : 'as yet unclassified' }
InternerModel >> cutoff [
  cutoff ifNil: [ cutoff := self maxSentence ].
  ^ cutoff

]

{ #category : 'as yet unclassified' }
InternerModel >> cutoff: aNumber [
  cutoff := aNumber

]

{ #category : 'as yet unclassified' }
InternerModel >> deltaForKey: aKey bucket: bucketIndex [
  | buckets curr prev |
  buckets := self bucketCounts at: aKey name ifAbsent: [ #() ].
  buckets isEmpty ifTrue: [ ^ 0 ].
  curr := buckets at: bucketIndex + 1 ifAbsent: [ buckets last ].
  prev := bucketIndex = 0
    ifTrue: [ 0 ]
    ifFalse: [ buckets at: bucketIndex ifAbsent: [ curr ] ].
  ^ curr - prev

]

{ #category : 'as yet unclassified' }
InternerModel >> gtCompletionsFor: aView [
  <gtView>
  | k |
  k := self selected ifNil: [ ^ aView empty ].
  k displayCutoff: self cutoff.
  ^ k gtCompletionsFor: aView

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
  | list listElement toolbar root bucketLabel statsLabel |

  list := GtPhlowColumnedListView new
  title: 'Keys';
  items: [ self keysOrderedForCurrentBucket ];
  column: 'Key' text: [:k | k name];
  column: '#'
    text: [:k | (self countForKey: k bucket: self currentBucketIndex) asString ];
  column: 'Δ'
    text: [:k | (self deltaForKey: k bucket: self currentBucketIndex) asString ];
  send: [:k | self selected: k. k ].


  listElement := list asElement.

  bucketLabel := BlTextElement new
    text: ('# @' , ((self currentBucketIndex + 1) * self bucketSizeWords) asString) asRopedText;
    constraintsDo: [:c | c horizontal fitContent. c vertical fitContent].

  statsLabel := BlTextElement new
    text: ('keys≥1: ' , (self keysWithCompletionsAt: self currentBucketIndex) asString ,
            ' (Δ ' , (self keysDeltaAt: self currentBucketIndex) asString , ')') asRopedText;
    constraintsDo: [:c | c horizontal fitContent. c vertical fitContent].

  toolbar := BlElement new
    layout: BlLinearLayout horizontal;
    constraintsDo: [:c | c horizontal fitContent. c vertical fitContent ].
  toolbar addChild: bucketLabel.
  toolbar addChild: statsLabel.
  toolbar addChild: (
    BrButton new
      aptitude: BrGlamorousButtonWithLabelAptitude new;
      label: '-';
      constraintsDo: [:c | c horizontal fitContent. c vertical fitContent. c margin: (BlInsets all: 4)];
      action: [
        self bumpBucket: -1.
        bucketLabel text: ('# @' , ((self currentBucketIndex + 1) * self bucketSizeWords) asString) asRopedText.
        statsLabel text: ('keys≥1: ' , (self keysWithCompletionsAt: self currentBucketIndex) asString ,
                          ' (Δ ' , (self keysDeltaAt: self currentBucketIndex) asString , ')') asRopedText.
        list items: [ self keysOrderedForCurrentBucket ].
        list updateContent: listElement ]).
  toolbar addChild: (
    BrButton new
      aptitude: BrGlamorousButtonWithLabelAptitude new;
      label: '+';
      constraintsDo: [:c | c horizontal fitContent. c vertical fitContent. c margin: (BlInsets all: 4)];
      action: [
        self bumpBucket: 1.
        bucketLabel text: ('# @' , ((self currentBucketIndex + 1) * self bucketSizeWords) asString) asRopedText.
        statsLabel text: ('keys≥1: ' , (self keysWithCompletionsAt: self currentBucketIndex) asString ,
                          ' (Δ ' , (self keysDeltaAt: self currentBucketIndex) asString , ')') asRopedText.
        list items: [ self keysOrderedForCurrentBucket ].
        list updateContent: listElement ]).

  root := BlElement new
    layout: BlLinearLayout vertical;
    constraintsDo: [:c | c horizontal matchParent. c vertical matchParent];
    addChild: toolbar;
    addChild: listElement;
    yourself.

  ^ aView explicit
    title: 'Keys (bucketed)';
    priority: 10;
    stencil: [ root ]

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

{ #category : 'as yet unclassified' }
InternerModel >> keysDeltaAt: bucketIndex [
  | curr prev |
  curr := self keysWithCompletionsAt: bucketIndex.
  prev := bucketIndex = 0
    ifTrue: [ 0 ]
    ifFalse: [ self keysWithCompletionsAt: bucketIndex - 1 ].
  ^ curr - prev

]

{ #category : 'as yet unclassified' }
InternerModel >> keysOrderedForCurrentBucket [
  | bucket order |
  bucket := self currentBucketIndex.
  order := self orderForBucket: bucket.
  order isEmpty ifTrue: [ ^ self keys ].
  ^ order collect: [:idx | self keys at: idx + 1]

]

{ #category : 'as yet unclassified' }
InternerModel >> keysWithCompletionsAt: bucketIndex [
  | count val |
  (self keysWithCompletionsCache includesKey: bucketIndex) ifTrue: [
    ^ self keysWithCompletionsCache at: bucketIndex ].
  count := 0.
  self bucketCounts keysAndValuesDo: [:keyName :buckets |
    buckets isEmpty
      ifTrue: [ val := 0 ]
      ifFalse: [
        ((bucketIndex + 1) > buckets size)
          ifTrue: [ val := buckets last ]
          ifFalse: [ val := buckets at: bucketIndex + 1 ] ].
    val > 0 ifTrue: [ count := count + 1 ] ].
  self keysWithCompletionsCache at: bucketIndex put: count.
  ^ count

]

{ #category : 'as yet unclassified' }
InternerModel >> keysWithCompletionsCache [ ^ keysWithCompletionsCache ifNil: [ keysWithCompletionsCache := Dictionary new ].

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
  self bucketCounts: Dictionary new.
  self chunkMap: Dictionary new.
  summaries := entries collect: [:entry |
    | words keyName count chunkFile chunkPath buckets key |
    words := entry at: 'words' ifAbsent: [ #() ].
    keyName := self class joinWords: words.
    count := entry at: 'completion_count' ifAbsent: [ 0 ].
    chunkFile := entry at: 'chunk' ifAbsent: [ '' ].
    chunkPath := baseDir ifNotNil: [ (baseDir / chunkFile) fullName ] ifNil: [ chunkFile ].
    buckets := entry at: 'counts_by_word_bucket' ifAbsent: [ #() ].
    self completionCounts at: keyName put: count.
    self bucketCounts at: keyName put: buckets.
    self chunkMap at: keyName put: chunkPath.
    key := InternerKey fromName: keyName completions: #().
    key chunkPath: chunkPath.
    key displayCutoff: self cutoff.
    key ].
  keys := summaries.
self selected: (keys ifEmpty: [ nil ] ifNotEmpty: [ keys first ]).
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

{ #category : 'as yet unclassified' }
InternerModel >> maxSentence [
  ^ maxSentence ifNil: [ 0 ]

]

{ #category : 'as yet unclassified' }
InternerModel >> maxSentence: aNumber [
  maxSentence := aNumber
]

{ #category : 'as yet unclassified' }
InternerModel >> maxWords [
^ maxWords ifNil: [ 0 ]

]

{ #category : 'as yet unclassified' }
InternerModel >> maxWords: n [    
	maxWords := n
]

{ #category : 'as yet unclassified' }
InternerModel >> orderCache [ 
^ orderCache ifNil: [ orderCache := Dictionary new ].

]

{ #category : 'as yet unclassified' }
InternerModel >> orderFiles [ 
	^ orderFiles.
]

{ #category : 'as yet unclassified' }
InternerModel >> orderFiles: aColl [ 
	orderFiles := aColl.
]

{ #category : 'as yet unclassified' }
InternerModel >> orderForBucket: bucketIndex [
  | fname path bytes count order |
  fname := self orderFiles at: bucketIndex + 1 ifAbsent: [ ^ #() ].
  (self orderCache includesKey: bucketIndex) ifTrue: [ ^ self orderCache at: bucketIndex ].
  path := (self ordersBaseDir ifNil: [ FileSystem workingDirectory ]) / fname.
  bytes := path binaryReadStream contents.
  count := bytes size // 4.
  order := Array new: count.
  1 to: count do: [:i |
    | offset |
    offset := (i - 1) * 4 + 1.
    order at: i put: (bytes unsignedLongAt: offset bigEndian: false) ].
  self orderCache at: bucketIndex put: order.
  ^ order

]

{ #category : 'as yet unclassified' }
InternerModel >> ordersBaseDir [ 
	^ ordersBaseDir.
]

{ #category : 'as yet unclassified' }
InternerModel >> ordersBaseDir: aString [ 
	ordersBaseDir := aString.
]

{ #category : 'as yet unclassified' }
InternerModel >> selected [
  ^ selected ifNil: [ (keys ifNil: [ #() ]) ifEmpty: [ nil ] ifNotEmpty: [ keys first ] ]

]

{ #category : 'as yet unclassified' }
InternerModel >> selected: aKey [
  selected := aKey.
  selected ifNotNil: [ selected displayCutoff: self cutoff ].

]

{ #category : 'accessing' }
InternerModel >> vocab: aVocab [ 
^ vocab ifNil: [ #() ]
]
