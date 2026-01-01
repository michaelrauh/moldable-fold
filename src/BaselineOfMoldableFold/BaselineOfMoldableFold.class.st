Class {
	#name : 'BaselineOfMoldableFold',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfMoldableFold',
	#package : 'BaselineOfMoldableFold'
}

{ #category : 'loading' }
BaselineOfMoldableFold class >> loadLepiter [
	IceRepository registry  
		detect: [ :aRepository |
			aRepository name = 'moldable-fold' ]
		ifFound: [ :aRepository | 
			| defaultDatabase currentProperties |
			defaultDatabase := LeDatabasesRegistry defaultLogicalDatabase.
			currentProperties := defaultDatabase properties.
			currentProperties addRegisteredDirectory: aRepository repositoryDirectory / 'lepiter'.
			defaultDatabase reload ]
		ifNone: [
			self inform: 'Repository not found.' ]
]

{ #category : 'baseline' }
BaselineOfMoldableFold >> baseline: spec [
	<baseline>
		^ spec for: #common do: [
			spec package: 'MoldableFold'
		]
]
