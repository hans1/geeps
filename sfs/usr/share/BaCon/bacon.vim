" Vim syntax file
" Language:	BaCon
" Maintainer:	Peter van Eerten
" Last Change:	July 3, 2011

if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

" BACON keywords
syn keyword basicStatement	WHILE DO WEND REPEAT UNTIL FOR TO NEXT SELECT OFF INTERNATIONAL
syn keyword basicStatement	IF THEN ELSE ELIF ENDIF PRINT FORMAT INPUT TRACE STOP CONTINUE
syn keyword basicStatement	LET END OPEN READING WRITING AS STEP BREAK DEFAULT ALIAS VAR
syn keyword basicStatement	APPENDING READWRITE CLOSE REWIND MEMREWIND READLN CURSOR LOOKUP
syn keyword basicStatement	FROM WRITELN SUB READ ENDSUB CALL IMPORT GETLINE INCR DECR
syn keyword basicStatement	DECLARE TYPE INCLUDE SYSTEM DATA RESTORE PUTLINE COLLAPSE
syn keyword basicStatement	FUNCTION ENDFUNCTION RETURN POKE PUSH PULL SEEK ON ALARM
syn keyword basicStatement	SLEEP SEED GETBYTE CONST COPY DELETE SETENVIRON CASE RELATE
syn keyword basicStatement	OFFSET WHENCE RESUME START CURRENT PUTBYTE ENDWITH SOCKET
syn keyword basicStatement	SIZE GOTO LABEL TRAP CATCH USEC WITH SPLIT BY COMPARE CHUNK
syn keyword basicStatement	ENDUSEC FILE DIRECTORY GETFILE RENAME CLEAR IS EQ PROTO GOSUB
syn keyword basicStatement	COLOR RESET INTENSE NORMAL BLACK RED GREEN RECORD ASSOC TEXTDOMAIN
syn keyword basicStatement	YELLOW BLUE MAGENTA CYAN WHITE FG BG GOTOXY NE ISNOT BASE
syn keyword basicStatement	MAKEDIR CHANGEDIR LOCAL GLOBAL RESIZE ENDSELECT OPTION MEMTYPE
syn keyword basicStatement	DEF FN FREE NETWORK SEND RECEIVE SERVER SORT DOWN MEMSTREAM

" BACON functions
syn match basicstrFunction	"ARGUMENT\$\|CHOP\$\|CHR\$\|CONCAT\$\|CURDIR\$\|ERR\$\|EXEC\$\|FILL\$\|HOST\$"
syn match basicstrFunction	"GETENVIRON\$\|HEX\$\|LCASE\$\|LEFT\$\|MID\$\|MONTH\$\|OS\$\|REPLACE\$"
syn match basicstrFunction	"REVERSE\$\|RIGHT\$\|SPC\$\|STR\$\|TAB\$\|UCASE\$\|WEEKDAY\$\|INTL\$\|NNTL\$"

syn keyword basicFunction	SQR POW SIN COS TAN ABS ROUND NOT ENDFILE TELL REGEX ISTRUE
syn keyword basicFunction	LEN VAL MOD DIR DEC ASC AND OR INSTR FLOOR ISFALSE NOW
syn keyword basicFunction	MEMORY PEEK INSTRREV GETX GETY DAY RND EVEN ODD RETVAL
syn keyword basicFunction	SEARCH WEEK MONTH YEAR INT SIZEOF ATN LOG EXP SGN GETKEY
syn keyword basicFunction	HOUR MINUTE SECOND ADDRESS ERROR FILELEN FILETYPE FILEEXISTS
syn keyword basicFunction	COLUMNS ROWS WAIT TIMEVALUE RANDOM EQUAL MEMTELL

" BACON constants
syn keyword basicConstant	TRUE FALSE PI MAXRANDOM
syn match basicstrConstant	"NL\$\|VERSION\$"

"integer number, or floating point number without a dot.
syn match  basicNumber		"\<\d\+\>"
"floating point number, with dot
syn match  basicNumber		"\<\d\+\.\d*\>"
"floating point number, starting with a dot
syn match  basicNumber		"\.\d\+\>"

" String and Character contstants
syn match   basicSpecial contained "\\\d\d\d\|\\."
syn region  basicString		  start=+"+  skip=+\\\\\|\\"+  end=+"+  contains=basicSpecial

syn region  basicComment	start="REM" end="$" contains=basicTodo
syn region  basicComment	start="'" end="$" contains=basicTodo
syn keyword basicTypeSpecifier	int double float long char short void signed unsigned static
syn keyword basicTypeSpecifier  STRING NUMBER FLOATING
syn match   basicTypeSpecifier  "[a-zA-Z0-9]"ms=s+1
syn match   basicMathsOperator   "-\|=\|[:<>+\*^/\\]"

" HUG wrapper functions
syn keyword basicWrapperFunc	INIT HUGOPTIONS QUIT DRAW HIDE SHOW WINDOW DISPLAY TEXT GET
syn keyword basicWrapperFunc	SET NOTEBOOK BUTTON STOCK TOGGLE CHECK RADIO ENTRY PASSWORD
syn keyword basicWrapperFunc	MARK COMBO HSEPARATOR VSEPARATOR FRAME EDIT LIST MSGDIALOG SYNC
syn keyword basicWrapperFunc	FILEDIALOG SPIN IMAGE CANVAS CLIPBOARD PROGRESSBAR CALLBACK
syn keyword basicWrapperFunc	CALLBACKX MOUSE CIRCLE PIXEL LINE SQUARE OUT PICTURE ATTACH
syn keyword basicWrapperFunc	TIMEOUT FONT DISABLE ENABLE FOCUS UNFOCUS SCREENSIZE KEY PROPERTY
syn match basicWrapperstrFunc	"GRAB\$\|HUGLIB\$"

" GMP wrapper functions
syn keyword basicWrapperFunc	INIT PRECISION FCOMPARE ISPRIME
syn match basicWrapperstrFunc	"ADD\$\|SUBSTRACT\$\|MULTIPLY\$\|DIVIDE\$\|MODULO\$\|POWER\$\|SQUARE\$"
syn match basicWrapperstrFunc	"ROOT\$\|FADD\$\|FSUBSTRACT\$\|FMULTIPLY\$\|FDIVIDE\$\|FPOWER\$"
syn match basicWrapperstrFunc	"FIBONACCI\$\|FACTORIAL\$\|NEXTPRIME\$\|FSQUARE\$\|GCD\$"

if version >= 508 || !exists("did_basic_syntax_inits")
  if version < 508
    let did_basic_syntax_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif

  hi def link basicStatement		Statement
  hi def link basicstrFunction		Identifier
  hi def link basicFunction		Identifier
  hi def link basicNumber		Number
  hi def link basicString		String
  hi def link basicComment		Comment
  hi def link basicSpecial		Special
  hi def link basicTodo			Todo
  hi def link basicTypeSpecifier	Type
  hi def link basicWrapperFunc		PreProc
  hi def link basicWrapperstrFunc	PreProc
  hi def link basicConstant		Constant
  hi def link basicstrConstant		Constant
  hi def link basicFilenumber	basicTypeSpecifier
  hi basicMathsOperator term=bold cterm=bold gui=bold

  delcommand HiLink
endif

let b:current_syntax = "bacon"
