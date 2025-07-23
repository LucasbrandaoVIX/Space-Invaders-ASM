;
; Strings saved here for printing to user + debugging
;

DATASEG

	GameOverString			db	'Game Over!$'

	WinString				db	'You Win!$'

	YouEarnedXString		db	'You earned $'

	HitString				db	'You got hit: -1 heart $'

	NAString				db	'N/A$'


	; Difficulty menu strings
	DifficultyTitleString	db	'SPACE INVADERS', '$'
	SelectDifficultyString	db	'Select Difficulty:', '$'
	EasyString				db	'EASY', '$'
	MediumString			db	'MEDIUM', '$'
	HardString				db	'HARD', '$'
	UseArrowKeysString		db	'Use arrow keys to select, Enter to start', '$'
	
	; Menu decoration strings
	MenuStars1				db	'*~*~*~*~*~*~*~*~*~*', '$'
	MenuStars2				db	'*~*~*~*~*~*~*~*~*~*', '$'
	MenuSpacing				db	'                    ', '$'
	MenuBottomDecor			db	'~~~~~~ Press ESC to exit ~~~~~~', '$'
	
	; Pause menu strings
	PausedString			db	'PAUSED', '$'
	PressPhideString		db	'Press P to resume', '$'

;Debug strings:
	OpenErrorMsg			db	'File Open Error', 10,'$'
	FileNotFoundMsg			db	'File not found$' ;error code 2
	TooManyOpenFilesMsg		db	'Too many open files$' ;error code 4
	AccessDeniedMsg			db	'Access Denied$' ;error code 5
	InvalidAccessMsg		db	'Invalid Access$' ;error code 12
	UnknownErrorMsg			db	'Unknown Error$'

	CloseErrorMsg			db	'File Close Error', 10,'$'

	PointerSetErrorMsg		db	'Pointer Set Error', 10, '$'
	ReadErrorMsg			db	'Read Error', 10, '$'

	AndWordString			db	' and $'