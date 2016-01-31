$set nover
$copy sys$input BOARD_DIGEST.COM
$deck
$!
$! BOARD_DIGEST.COM
$!
$! Command file invoked by folder associated with a BBOARD which is
$! is specified with /SPECIAL.  It will convert "digest" mail and
$! split it into separate messages.  This type of mail is used in
$! certain Arpanet mailing lists, such as TEXHAX and INFO-MAC.
$!
$ FF[0,8] = 12			! Define a form feed character
$ SET PROTECT=(W:RWED)/DEFAULT
$ SET PROC/PRIV=SYSPRV
$ USER := 'F$GETJPI("","USERNAME")
$ EXTRACT_FILE = "BULL_DIR:" + "''USER'" + ".TXT"
$ DEFINE/USER EXTRACT_FILE BULL_DIR:'USER'
$ MAIL
READ
EXTRACT EXTRACT_FILE
DELETE
$ OPEN/READ INPUT 'EXTRACT_FILE'
$ OPEN/WRITE OUTPUT 'EXTRACT_FILE'
$ READ INPUT FROM_USER
$AGAIN:
$ READ/END=ERROR INPUT BUFFER
$ IF F$EXTRACT(0,3,BUFFER) .NES. "To:" THEN GOTO SKIP
$ USER = F$EXTRACT(4,F$LEN(BUFFER),BUFFER)
$ GOTO AGAIN1
$SKIP:
$ IF F$EXTRACT(0,15,BUFFER) .NES. "---------------" THEN GOTO AGAIN
$AGAIN1:
$ READ/END=ERROR INPUT BUFFER
$ IF F$EXTRACT(0,15,BUFFER) .NES. "---------------" THEN GOTO AGAIN1
$ FROM = " "
$ SUBJ = " "
$NEXT:
$ READ/END=EXIT INPUT BUFFER
$FROM:
$ IF F$EXTRACT(0,5,BUFFER) .NES. "From:" THEN GOTO SUBJECT
$ FROM = BUFFER 
$ GOTO NEXT
$SUBJECT:
$ IF F$EXTRACT(0,8,BUFFER) .NES. "Subject:" THEN GOTO NEXT
$ SUBJ = BUFFER - "Subject:"
$F2:
$ IF F$LENGTH(SUBJ) .EQ. 0 THEN GOTO WRITE
$ IF F$EXTRACT(0,1,SUBJ) .NES. " " THEN GOTO WRITE
$ SUBJ = F$EXTRACT(1,F$LENGTH(SUBJ),SUBJ)
$ GOTO F2
$WRITE:
$ WRITE OUTPUT FROM_USER
				! Write From: + TAB + USERNAME
$ WRITE OUTPUT "To:	" + USER
				! Write To: + TAB + BBOARDUSERNAME
$ WRITE OUTPUT "Subj:	" + SUBJ
				! Write Subject: + TAB + mail subject
$ WRITE OUTPUT ""		! Write one blank line
$ IF FROM .NES. " " THEN WRITE OUTPUT FROM
$READ:
$ READ/END=EXIT/ERR=EXIT INPUT BUFFER
$ IF F$EXTRACT(0,15,BUFFER) .EQS. "---------------" THEN GOTO READ1
$ WRITE OUTPUT BUFFER
$ GOTO READ
$READ1:
$ READ/END=EXIT/ERR=EXIT INPUT BUFFER
$ IF F$LOCATE(":",BUFFER) .EQ. F$LENGTH(BUFFER) THEN GOTO READ1
$ WRITE OUTPUT FF
$ FROM = " "
$ SUBJ = " "
$ GOTO FROM
$EXIT:
$ CLOSE INPUT
$ CLOSE OUTPUT
$ PUR 'EXTRACT_FILE'
$ EXIT
$ERROR:
$ CLOSE INPUT
$ CLOSE OUTPUT
$ DELETE 'EXTRACT_FILE';
$eod 
$copy sys$input BOARD_SPECIAL.COM
$deck
$!
$! BOARD_SPECIAL.COM
$!
$! Command file invoked by folder associated with a BBOARD which is
$! is specified with /SPECIAL.  This can be used to convert data to
$! a message via a different means than the VMS mail.  This is done by
$! converting the data to look like output created by the MAIL utility,
$! which appears as follows:
$!
$!	First line is 0 length line.
$!	Second line is "From:" followed by TAB followed by incoming username
$!	Third line is "To:" followed by TAB followed by BBOARD username
$!	The message text then follows.
$!	Message is ended by a line containing a FORM FEED.
$!
$! This command file should be put in the BBOARD_DIRECTORY as specified
$! in BULLFILES.INC.  You can also have several different types of special
$! procedures.  To accomplish this, rename the file to the BBOARD username.
$! i.e. if you specify SET BBOARD FOO/SPECIAL, you could name the file
$! FOO.COM and it will execute that rather than BOARD_SPECIAL.COM.
$!
$! The following routine is the one we use to convert mail from a non-DEC
$! mail network.  The output from this mail is written into a file which
$! is slightly different from the type outputted by MAIL.
$!
$! (NOTE: A username in the SET BBOARD command need only be specified if
$! the process which reads the mail requires that the process be owned by
$! a specific user, which is the case for this sample, and for that matter
$! when reading VMS MAIL.  If this is not required, you do not have to
$! specify a username.)
$!
$ USERNAME := 'F$GETJPI("","USERNAME")'		! This trims trailing spaces
$ IF F$SEARCH("MFE_TELL_FILES:"+USERNAME+".MAI") .EQS. "" THEN EXIT
$ SET DEFAULT BULL_DIR:	! BULLETIN looks for text in BBOARD directory
$ SET PROTECT=(W:RWED)/DEFAULT
$ IF F$SEARCH("MFEMSG.MAI") .NES. "" THEN -
  DELETE MFEMSG.MAI;*		! Delete any leftover output files.
$ MSG := $MFE_TELL: MESSAGE
$ DEFINE/USER SYS$COMMAND SYS$INPUT
$ MSG				! Read MFENET mail
copy * MFEMSG
delete *
exit
$ FF[0,8] = 12			! Define a form feed character
$ OPEN/READ/ERROR=EXIT INPUT MFEMSG.MAI
$ OUTNAME = USERNAME+".TXT"	! Output file will be 'USERNAME'.TXT
$ OPEN/WRITE OUTPUT 'OUTNAME'
$ READ/END=END INPUT DATA		! Skip first line in MSG output
$HEADER:
$ FROM = ""
$ SUBJ = ""
$ MFEMAIL = "T"
$NEXTHEADER:
$ IF (FROM.NES."") .AND. (SUBJ.NES."") THEN GOTO SKIPHEADER
$ READ/END=END INPUT DATA		! Read header line in MSG output
$ IF DATA .EQS. "" THEN GOTO SKIPHEADER	! Missing From or Subj ??
$ IF FROM .NES. "" THEN GOTO SKIPFROM
$ IF F$LOCATE("From: ",DATA) .NES. 0 THEN GOTO 10$
$ MFEMAIL = "F"
$ FROM= F$EXTRACT(6,F$LENGTH(DATA),DATA)
$ GOTO NEXTHEADER
$10$:
$ IF F$LOCATE("Reply-to: ",DATA) .NES. 0 THEN GOTO 20$
$ MFEMAIL = "F"
$ FROM= F$EXTRACT(10,F$LENGTH(DATA),DATA)
$ GOTO NEXTHEADER
$20$:
$ IF F$LOCATE("From ",DATA) .NES. 0 THEN GOTO SKIPFROM
$ FROM= F$EXTRACT(5,F$LENGTH(DATA),DATA)
$ GOTO NEXTHEADER
$SKIPFROM:
$ IF SUBJ .NES. "" THEN GOTO SKIPSUBJ
$ IF F$LOCATE("Subject",DATA) .NES. 0 THEN GOTO SKIPSUBJ
$ SUBJ= F$EXTRACT(F$LOCATE(": ",DATA)+2,F$LENGTH(DATA),DATA)
$ GOTO NEXTHEADER
$SKIPSUBJ:
$ GOTO NEXTHEADER
$SKIPHEADER:
$ WRITE OUTPUT "From:	" + FROM
				! Write From: + TAB + USERNAME
$ WRITE OUTPUT "To:	" + USERNAME
				! Write To: + TAB + BBOARDUSERNAME
$ WRITE OUTPUT "Subj:	" + SUBJ
				! Write Subject: + TAB + mail subject
$ WRITE OUTPUT ""		! Write one blank line
$ IF (DATA.EQS."") .OR. MFEMAIL THEN GOTO SKIPBLANKS
$50$:
$ READ/END=END INPUT DATA		! Skip rest of main header
$ IF DATA .NES. "" THEN GOTO 50$
$60$:
$ READ/END=END INPUT DATA		! Skip all of secondary header
$ IF DATA .NES. "" THEN GOTO 60$
$SKIPBLANKS:
$ READ/END=END INPUT DATA		! Skip all blanks
$ IF DATA .EQS. "" THEN GOTO SKIPBLANKS
$NEXT:				! Read and write message text
$ WRITE OUTPUT DATA
$ IF DATA .EQS. FF THEN GOTO HEADER
			! Multiple messages are seperated by form feeds
$ READ/END=END INPUT DATA
$ GOTO NEXT
$END:
$ CLOSE INPUT
$ CLOSE OUTPUT
$ DELETE MFEMSG.MAI;
$EXIT:
$ EXIT
$eod 
$copy sys$input BULLCOM.CLD
$deck
!
! BULLCOM.CLD
!
! VERSION 2/1/88
!
 	MODULE BULLETIN_SUBCOMMANDS

	DEFINE VERB ADD
		PARAMETER P1, LABEL=FILESPEC, VALUE(TYPE=$FILE)
		QUALIFIER ALL, NONNEGATABLE
		QUALIFIER BELL, NONNEGATABLE
		QUALIFIER BROADCAST, NONNEGATABLE
		DISALLOW NOT BROADCAST AND ALL
		DISALLOW NOT BROADCAST AND BELL
		QUALIFIER CLUSTER, DEFAULT
		QUALIFIER EDIT, NEGATABLE
		QUALIFIER EXPIRATION, NONNEGATABLE, VALUE
		QUALIFIER FOLDER, LABEL=SELECT_FOLDER, VALUE(REQUIRED,LIST)
		QUALIFIER NODES, LABEL=NODES, VALUE(REQUIRED,LIST)
		NONNEGATABLE
		QUALIFIER LOCAL, NONNEGATABLE
		DISALLOW LOCAL AND NOT BROADCAST
		DISALLOW NODES AND SELECT_FOLDER
		QUALIFIER PERMANENT, NONNEGATABLE
		QUALIFIER SHUTDOWN, NONNEGATABLE
		DISALLOW PERMANENT AND SHUTDOWN
		QUALIFIER SUBJECT, NONNEGATABLE, VALUE(REQUIRED)
		QUALIFIER SYSTEM, NONNEGATABLE
		QUALIFIER USERNAME, LABEL=USERNAME, VALUE(REQUIRED)
		NONNEGATABLE
	DEFINE VERB BACK
	DEFINE VERB CHANGE
		PARAMETER P1, LABEL=FILESPEC, VALUE(TYPE=$FILE)
		QUALIFIER EDIT, NEGATABLE
		QUALIFIER EXPIRATION, NONNEGATABLE, VALUE
		QUALIFIER GENERAL, NONNEGATABLE
		QUALIFIER HEADER, NONNEGATABLE
		QUALIFIER SUBJECT, NONNEGATABLE, VALUE(REQUIRED)
		QUALIFIER NEW,NONNEGATABLE
		QUALIFIER NUMBER, VALUE(TYPE=$NUMBER,REQUIRED)
		QUALIFIER PERMANENT, NONNEGATABLE
		QUALIFIER SHUTDOWN, NONNEGATABLE
		QUALIFIER SYSTEM,NONNEGATABLE
		QUALIFIER TEXT, NONNEGATABLE
		DISALLOW NEW AND NOT EDIT
		DISALLOW SYSTEM AND GENERAL
		DISALLOW PERMANENT AND SHUTDOWN
		DISALLOW PERMANENT AND EXPIRATION
		DISALLOW SHUTDOWN AND EXPIRATION
		DISALLOW SUBJECT AND HEADER
	DEFINE VERB COPY
		PARAMETER P1, LABEL=FOLDER, PROMPT="Folder"
			VALUE(REQUIRED)
		QUALIFIER BULLETIN_NUMBER
		QUALIFIER ORIGINAL
		DISALLOW FOLDER AND BULLETIN_NUMBER
	DEFINE VERB CREATE
		QUALIFIER BRIEF, NONNEGATABLE
!
! Make the following qualifier DEFAULT if you want CREATE to be
! a privileged command.
!
		QUALIFIER NEEDPRIV, NONNEGATABLE
		QUALIFIER NODE, NONNEGATABLE, VALUE(REQUIRED)
		QUALIFIER NOTIFY, NONNEGATABLE
		QUALIFIER PRIVATE, NONNEGATABLE
		QUALIFIER READNEW, NONNEGATABLE
		QUALIFIER SEMIPRIVATE, NONNEGATABLE
		QUALIFIER SHOWNEW, NONNEGATABLE
		QUALIFIER SYSTEM, NONNEGATABLE
		PARAMETER P1, LABEL=CREATE_FOLDER, PROMPT="Folder"
			VALUE(REQUIRED)
		DISALLOW PRIVATE AND SEMIPRIVATE
		DISALLOW BRIEF AND READNEW
		DISALLOW SHOWNEW AND READNEW
		DISALLOW BRIEF AND SHOWNEW
		DISALLOW NODE AND (NOTIFY OR PRIVATE OR SEMIPRIVATE)
	DEFINE VERB CURRENT
		QUALIFIER EDIT
	DEFINE VERB DELETE
		PARAMETER P1, LABEL=BULLETIN_NUMBER, VALUE(TYPE=$FILE)
		QUALIFIER IMMEDIATE,NONNEGATABLE
		QUALIFIER FOLDER, LABEL=SELECT_FOLDER, VALUE(REQUIRED,LIST)
		QUALIFIER NODES, LABEL=NODES, VALUE(REQUIRED,LIST)
		QUALIFIER USERNAME, LABEL=USERNAME, VALUE(REQUIRED)
		QUALIFIER SUBJECT, VALUE(REQUIRED)
		DISALLOW NOT SUBJECT AND (NODES OR SELECT_FOLDER)
		DISALLOW NODES AND SELECT_FOLDER
	DEFINE VERB DIRECTORY
		PARAMETER P1, LABEL=SELECT_FOLDER
		QUALIFIER FOLDER, SYNTAX=DIRECTORY_FOLDER, NONNEGATABLE
		QUALIFIER NEW
		QUALIFIER START, VALUE(REQUIRED,TYPE=$NUMBER), NONNEGATABLE
		QUALIFIER SINCE,VALUE(DEFAULT="TODAY",TYPE=$DATETIME)
		DISALLOW (NEW AND SINCE) OR (START AND NEW) OR (START AND SINCE)
	DEFINE SYNTAX DIRECTORY_FOLDER
		QUALIFIER DESCRIBE
		QUALIFIER FOLDER, DEFAULT
	DEFINE VERB E				! EXIT command.
	DEFINE VERB EX				! EXIT command.
	DEFINE VERB EXIT			! EXIT command.
	DEFINE VERB EXTRACT
		PARAMETER P1, LABEL=FILESPEC, VALUE(TYPE=$FILE,REQUIRED),
			PROMPT="File"
		QUALIFIER HEADER, DEFAULT
		QUALIFIER NEW, NONNEGATABLE
	DEFINE VERB FILE
		PARAMETER P1, LABEL=FILESPEC, VALUE(TYPE=$FILE,REQUIRED),
			PROMPT="File"
		QUALIFIER HEADER, DEFAULT
		QUALIFIER NEW, NONNEGATABLE
	DEFINE VERB HELP
		PARAMETER P1, LABEL=HELP_FOLDER, VALUE(TYPE=$REST_OF_LINE)
	DEFINE VERB INDEX
		PARAMETER P1, LABEL=SELECT_FOLDER
		QUALIFIER FOLDER, SYNTAX=DIRECTORY_FOLDER, NONNEGATABLE
		QUALIFIER NEW
		QUALIFIER RESTART
		QUALIFIER START, VALUE(REQUIRED,TYPE=$NUMBER), NONNEGATABLE
		QUALIFIER SINCE,VALUE(DEFAULT="TODAY",TYPE=$DATETIME)
		DISALLOW (NEW AND SINCE) OR (START AND NEW) OR (START AND SINCE)
	DEFINE VERB LAST
	DEFINE VERB MAIL
		PARAMETER P1, LABEL=RECIPIENTS, PROMPT="Recipients"
		VALUE(REQUIRED,TYPE=$REST_OF_LINE)
		QUALIFIER SUBJECT, VALUE(REQUIRED)
	DEFINE VERB MODIFY
		QUALIFIER DESCRIPTION
		QUALIFIER NAME, VALUE(REQUIRED)
		QUALIFIER OWNER, VALUE(REQUIRED)
	DEFINE VERB MOVE
		PARAMETER P1, LABEL=FOLDER, PROMPT="Folder"
			VALUE(REQUIRED)
		QUALIFIER BULLETIN_NUMBER
		QUALIFIER NODES
		QUALIFIER ORIGINAL
		QUALIFIER IMMEDIATE,NONNEGATABLE,DEFAULT
		DISALLOW FOLDER AND BULLETIN_NUMBER
		DISALLOW FOLDER AND NODES
	DEFINE VERB NEXT
	DEFINE VERB PRINT
		QUALIFIER HEADER, DEFAULT
		QUALIFIER NOTIFY, DEFAULT
		QUALIFIER QUEUE, VALUE(DEFAULT=SYS$PRINT), NONNEGATABLE
	DEFINE VERB QUIT
	DEFINE VERB READ
		PARAMETER P1, LABEL=BULLETIN_NUMBER, VALUE(TYPE=$NUMBER)
		QUALIFIER EDIT
		QUALIFIER NEW
		QUALIFIER PAGE, DEFAULT
		QUALIFIER SINCE,VALUE(DEFAULT="TODAY",TYPE=$DATETIME)
		DISALLOW NEW AND SINCE
	DEFINE VERB REPLY
		PARAMETER P1, LABEL=FILESPEC, VALUE(TYPE=$FILE)
		QUALIFIER ALL, NONNEGATABLE
		QUALIFIER BELL, NONNEGATABLE
		QUALIFIER BROADCAST, NONNEGATABLE
		DISALLOW NOT BROADCAST AND ALL
		DISALLOW NOT BROADCAST AND BELL
		QUALIFIER CLUSTER, DEFAULT
		QUALIFIER EDIT, NEGATABLE
		QUALIFIER EXPIRATION, NONNEGATABLE, VALUE
		QUALIFIER FOLDER, LABEL=SELECT_FOLDER, VALUE(REQUIRED,LIST)
		QUALIFIER NODES, LABEL=NODES, VALUE(REQUIRED,LIST)
		NONNEGATABLE
		QUALIFIER LOCAL
		DISALLOW LOCAL AND NOT BROADCAST
		DISALLOW NODES AND SELECT_FOLDER
		QUALIFIER PERMANENT, NONNEGATABLE
		QUALIFIER SHUTDOWN, NONNEGATABLE
		DISALLOW PERMANENT AND SHUTDOWN
		QUALIFIER SUBJECT, NONNEGATABLE, VALUE(REQUIRED)
		QUALIFIER SYSTEM, NONNEGATABLE
		QUALIFIER USERNAME, LABEL=USERNAME, VALUE(REQUIRED)
		NONNEGATABLE
	DEFINE VERB REMOVE
		PARAMETER P1, LABEL=REMOVE_FOLDER, PROMPT="Folder"
			VALUE(REQUIRED)
	DEFINE VERB RESPOND
		QUALIFIER SUBJECT, VALUE(REQUIRED)
		QUALIFIER TEXT
		QUALIFIER EDIT
		DISALLOW TEXT AND NOT EDIT
	DEFINE VERB SEARCH
		PARAMETER P1, LABEL=SEARCH_STRING
		QUALIFIER START, VALUE(TYPE=$NUMBER,REQUIRED)
	DEFINE VERB SELECT
		PARAMETER P1, LABEL=SELECT_FOLDER
	DEFINE VERB SET
		PARAMETER P1, LABEL=SET_PARAM1, PROMPT="What"
			VALUE(REQUIRED, TYPE=SET_OPTIONS)
	DEFINE TYPE SET_OPTIONS
		KEYWORD NODE, SYNTAX=SET_NODE
		KEYWORD NONODE, SYNTAX = SET_NONODE
		KEYWORD EXPIRE_LIMIT, SYNTAX=SET_EXPIRE
		KEYWORD NOEXPIRE_LIMIT
		KEYWORD GENERIC, SYNTAX=SET_GENERIC
		KEYWORD NOGENERIC, SYNTAX=SET_GENERIC
		KEYWORD LOGIN, SYNTAX=SET_LOGIN
		KEYWORD NOLOGIN, SYNTAX=SET_LOGIN
		KEYWORD NOBBOARD
		KEYWORD BBOARD, SYNTAX=SET_BBOARD
		KEYWORD NOBRIEF, SYNTAX=SET_NOFLAGS
		KEYWORD BRIEF, SYNTAX=SET_FLAGS
		KEYWORD NOSHOWNEW, SYNTAX=SET_NOFLAGS
		KEYWORD SHOWNEW, SYNTAX=SET_FLAGS
		KEYWORD NOREADNEW, SYNTAX=SET_NOFLAGS
		KEYWORD READNEW, SYNTAX=SET_FLAGS
		KEYWORD ACCESS, SYNTAX=SET_ACCESS
		KEYWORD NOACCESS, SYNTAX=SET_NOACCESS
		KEYWORD FOLDER, SYNTAX=SET_FOLDER
		KEYWORD NOTIFY, SYNTAX=SET_FLAGS
		KEYWORD NONOTIFY, SYNTAX=SET_NOFLAGS
		KEYWORD PRIVILEGES, SYNTAX=SET_PRIVILEGES
		KEYWORD DUMP
		KEYWORD NODUMP
		KEYWORD PAGE
		KEYWORD NOPAGE
		KEYWORD SYSTEM
		KEYWORD NOSYSTEM
	DEFINE SYNTAX SET_NODE
		PARAMETER P1, LABEL=SET_PARAM1, PROMPT="What"
			VALUE(REQUIRED, TYPE=SET_OPTIONS)
		PARAMETER P2, LABEL=NODENAME, VALUE(REQUIRED)
		QUALIFIER FOLDER, VALUE(REQUIRED)
	DEFINE SYNTAX SET_NONODE
		QUALIFIER FOLDER, VALUE(REQUIRED)
	DEFINE SYNTAX SET_EXPIRE
		PARAMETER P1, LABEL=SET_PARAM1, PROMPT="What"
			VALUE(REQUIRED, TYPE=SET_OPTIONS)
		PARAMETER P2, LABEL=EXPIRATION, VALUE(TYPE=$NUMBER,REQUIRED)
	DEFINE SYNTAX SET_GENERIC
		PARAMETER P1, LABEL=SET_PARAM1, PROMPT="What"
			VALUE(REQUIRED, TYPE=SET_OPTIONS)
		PARAMETER P2, LABEL=USERNAME, VALUE(REQUIRED)
		QUALIFIER DAYS,VALUE(TYPE=$NUMBER,DEFAULT="7"),DEFAULT
	DEFINE SYNTAX SET_LOGIN
		PARAMETER P1, LABEL=SET_PARAM1, PROMPT="What"
			VALUE(REQUIRED, TYPE=SET_OPTIONS)
		PARAMETER P2, LABEL=USERNAME, VALUE(REQUIRED)
	DEFINE SYNTAX SET_FLAGS
		PARAMETER P1, LABEL=SET_PARAM1, PROMPT="What"
			VALUE(REQUIRED, TYPE=SET_OPTIONS)
		QUALIFIER DEFAULT, NONNEGATABLE
		QUALIFIER ALL, NONNEGATABLE
		DISALLOW ALL AND DEFAULT
	DEFINE SYNTAX SET_NOFLAGS
		PARAMETER P1, LABEL=SET_PARAM1, PROMPT="What"
			VALUE(REQUIRED, TYPE=SET_OPTIONS)
		QUALIFIER DEFAULT, NONNEGATABLE
		QUALIFIER ALL, NONNEGATABLE
		QUALIFIER FOLDER, VALUE(REQUIRED)
		DISALLOW ALL AND DEFAULT
	DEFINE SYNTAX SET_BBOARD
		PARAMETER P1, LABEL=SET_PARAM1, PROMPT="What"
			VALUE(REQUIRED, TYPE=SET_OPTIONS)
		PARAMETER P2, LABEL=BB_USERNAME
		QUALIFIER EXPIRATION, VALUE(TYPE=$NUMBER)
			LABEL=EXPIRATION, DEFAULT
		QUALIFIER SPECIAL, NONNEGATABLE
		QUALIFIER VMSMAIL, NONNEGATABLE
		DISALLOW VMSMAIL AND NOT SPECIAL
		DISALLOW VMSMAIL AND NOT BB_USERNAME
	DEFINE SYNTAX SET_FOLDER
		PARAMETER P1, LABEL=SET_PARAM1, PROMPT="What"
			VALUE(REQUIRED, TYPE=SET_OPTIONS)
		PARAMETER P2, LABEL=SELECT_FOLDER
	DEFINE SYNTAX SET_NOACCESS
		PARAMETER P1, LABEL=SET_PARAM1, PROMPT="What"
			VALUE(REQUIRED, TYPE=SET_OPTIONS)
		PARAMETER P2, LABEL=ACCESS_ID
		PARAMETER P3, LABEL=ACCESS_FOLDER
		QUALIFIER ALL, NONNEGATABLE
		QUALIFIER READONLY, NONNEGATABLE
		DISALLOW NOT ALL AND NOT ACCESS_ID
		DISALLOW ALL AND NOT READONLY
	DEFINE SYNTAX SET_ACCESS
		PARAMETER P1, LABEL=SET_PARAM1, PROMPT="What"
			VALUE(REQUIRED, TYPE=SET_OPTIONS)
		PARAMETER P2, LABEL=ACCESS_ID
		PARAMETER P3, LABEL=ACCESS_FOLDER
		QUALIFIER READONLY, NONNEGATABLE
		QUALIFIER ALL, NONNEGATABLE
		DISALLOW NOT ALL AND NOT ACCESS_ID
	DEFINE SYNTAX SET_PRIVILEGES
		PARAMETER P1, LABEL=SET_PARAM1, PROMPT="What"
			VALUE(REQUIRED, TYPE=SET_OPTIONS)
		PARAMETER P2, LABEL=PRIVILEGES, PROMPT="Privileges"
		VALUE (REQUIRED,LIST)
	DEFINE VERB SHOW
		PARAMETER P1, LABEL=SHOW_PARAM1, PROMPT="What"
			VALUE(REQUIRED, TYPE=SHOW_OPTIONS)
		QUALIFIER FULL, SYNTAX=SHOW_FOLDER_FULL, NONNEGATABLE
	DEFINE TYPE SHOW_OPTIONS
		KEYWORD FOLDER, SYNTAX=SHOW_FOLDER
		KEYWORD NEW, SYNTAX=SHOW_FLAGS
		KEYWORD PRIVILEGES, SYNTAX=SHOW_FLAGS
		KEYWORD FLAGS, SYNTAX=SHOW_FLAGS
	DEFINE SYNTAX SHOW_FLAGS
		PARAMETER P1, LABEL=SHOW_PARAM1, PROMPT="What"
			VALUE(REQUIRED, TYPE=SHOW_OPTIONS)
	DEFINE SYNTAX SHOW_FOLDER
		PARAMETER P1, LABEL=SHOW_PARAM1, PROMPT="What"
			VALUE(REQUIRED, TYPE=SHOW_OPTIONS)
		PARAMETER P2, LABEL=SHOW_FOLDER
	DEFINE SYNTAX SHOW_FOLDER_FULL
		QUALIFIER FULL, DEFAULT
		PARAMETER P1, LABEL=SHOW_PARAM1, PROMPT="What"
			VALUE(REQUIRED, TYPE=SHOW_OPTIONS)
		PARAMETER P2, LABEL=SHOW_FOLDER
	DEFINE VERB UNDELETE
		PARAMETER P1, LABEL=BULLETIN_NUMBER, VALUE(TYPE=$FILE)
$eod 
$copy sys$input BULLETIN.COM
$deck
$ DEFINE SYS$INPUT SYS$NET
$ BULLETIN
$eod 
$copy sys$input BULLMAIN.CLD
$deck
	MODULE BULLETIN_MAINCOMMANDS
	DEFINE VERB BULLETIN
		PARAMETER P1, LABEL=SELECT_FOLDER
		QUALIFIER BBOARD
		QUALIFIER BULLCP
		QUALIFIER CLEANUP, LABEL=CLEANUP, VALUE(REQUIRED)
		QUALIFIER EDIT
		QUALIFIER LOGIN
		QUALIFIER PAGE, DEFAULT
		QUALIFIER READNEW
		QUALIFIER REVERSE
!
! The following line causes a line to be outputted separating system notices.
! The line consists of a line of all "-"s, i.e.:
!--------------------------------------------------------------------------
! If you want a different character to be used, simply put in the desired one
! in the following line.  If you want to disable the feature, remove the
! DEFAULT at the end of the line.  (Don't remove the whole line!)
!
		QUALIFIER SEPARATE, VALUE(DEFAULT="-"), DEFAULT
		QUALIFIER STARTUP
		QUALIFIER SYSTEM, VALUE(TYPE=$NUMBER,DEFAULT="7")
$eod 
$copy sys$input BULLSTART.COM
$deck
$ RUN SYS$SYSTEM:INSTALL
SYS$SYSTEM:BULLETIN/SHAR/OPEN/HEAD/PRIV=(OPER,SYSPRV,CMKRNL,WORLD,DETACH,PRMMBX)
/EXIT
$ BULL*ETIN :== $SYS$SYSTEM:BULLETIN
$ BULLETIN/STARTUP
$eod 
$copy sys$input BULL_COMMAND.COM
$deck
$B:=$PFCVAX$DBC1:[MRL.BULLETIN]BULLETIN.EXE;13
$ON ERROR THEN GOTO EXIT
$ON SEVERE THEN GOTO EXIT
$ON WARNING THEN GOTO EXIT
$B/'F$PROCESS()'
$EXIT:
$LOGOUT
$eod 
$copy sys$input CREATE.COM
$deck
$ FORTRAN/EXTEND BULLETIN
$ FORTRAN/EXTEND BULLETIN0
$ FORTRAN/EXTEND BULLETIN1
$ FORTRAN/EXTEND BULLETIN2
$ FORTRAN/EXTEND BULLETIN3
$ FORTRAN/EXTEND BULLETIN4
$ FORTRAN/EXTEND BULLETIN5
$ FORTRAN/EXTEND BULLETIN6
$ FORTRAN/EXTEND BULLETIN7
$ FORTRAN/EXTEND BULLETIN8
$ MAC ALLMACS
$ SET COMMAND/OBJ BULLCOM
$ SET COMMAND/OBJ BULLMAIN
$ @BULLETIN.LNK
$eod 
$copy sys$input INSTALL.COM
$deck
$ COPY BULLETIN.EXE SYS$SYSTEM:
$ RUN SYS$SYSTEM:INSTALL
SYS$SYSTEM:BULLETIN/DEL
SYS$SYSTEM:BULLETIN/SHAR/OPEN/HEAD/PRIV=(OPER,SYSPRV,CMKRNL,WORLD,DETACH,PRMMBX)
/EXIT
$!
$! NOTE: BULLETIN requires a separate help library. If you do not wish
$! the library to be placed in SYS$HELP, modify the following lines and
$! define the logical name BULL_HELP to be the help library directory, i.e.
$!	$ DEFINE/SYSTEM BULL_HELP SYSD$:[NEWDIRECTORY]
$! The above line should be placed in BULLSTART.COM to be executed after
$! every system reboot.
$!
$ IF F$SEARCH("SYS$HELP:BULL.HLB") .NES. "" THEN LIB/DELETE=*/HELP SYS$HELP:BULL
$ IF F$SEARCH("SYS$HELP:BULL.HLB") .EQS. "" THEN LIB/CREATE/HELP SYS$HELP:BULL
$ LIB/HELP SYS$HELP:BULL BULLCOMS1,BULLCOMS2
$ LIB/HELP SYS$HELP:HELPLIB BULLETIN
$eod 
$copy sys$input INSTRUCT.COM
$deck
$ BULLETIN
ADD/PERMANENT/SYSTEM INSTRUCT.TXT
INFO ON HOW TO USE THE BULLETIN UTILITY.
ADD/PERMANENT NONSYSTEM.TXT
INFO ON BEING PROMPTED TO READ NON-SYSTEM BULLETINS.
EXIT
$eod 
$copy sys$input LOGIN.COM
$deck
$!
$! Note: The command prompt when executing the utility is named after
$! the executable image.  Thus, as it is presently set up, the prompt
$! will be "BULLETIN>".  DO NOT make the command that executes the
$! image different from the image name, or certain things will break.
$! If you wish bulletins to be displayed upon logging in starting with
$! oldest rather than newest, change BULLETIN/LOGIN to BULLETIN/LOGIN/REVERSE. 
$!
$ BULL*ETIN :== $SYS$SYSTEM:BULLETIN
$ BULLETIN/LOGIN
$eod 
$copy sys$input MAKEFILE.
$deck
# Makefile for BULLETIN

Bulletin : Bulletin.Exe Bull.Hlb

Bulletin.Exe : Bulletin.Obj Bulletin0.Obj Bulletin1.Obj Bulletin2.Obj  \
               Bulletin3.Obj Bulletin4.Obj Bulletin5.Obj Bulletin6.Obj \
               Bulletin7.Obj Bulletin8.Obj \
               Bullcom.Obj Bullmain.Obj Allmacs.Obj
   Link /NoTrace Bulletin.Obj,Bulletin0.Obj,Bulletin1.Obj,Bulletin2.Obj, -
                 Bulletin3.Obj,Bulletin4.Obj,Bulletin5.Obj,Bulletin6.Obj, -
                 Bulletin7.Obj,Bulletin8.Obj, -
                 Bullcom.Obj,Bullmain.Obj,Allmacs.Obj, -
                 Sys$System:Sys.Stb /Sel /NoUserlib
   Purge /Log /Keep:2
   Purge /Log *.Obj,*.Exe

Bulletin.Obj : Bulletin.For Bullfiles.Inc Bulldir.Inc Bullfolder.Inc \
               Bulluser.Inc
   Fortran /Extend /NoList Bulletin.For

Bulletin0.Obj : Bulletin0.For Bulldir.Inc Bulluser.Inc Bullfolder.Inc \
                Bullfiles.Inc
   Fortran /Extend /NoList Bulletin0.For

Bulletin1.Obj : Bulletin1.For Bulldir.Inc Bullfolder.Inc Bulluser.Inc \
                Bullfiles.Inc
   Fortran /Extend /NoList Bulletin1.For

Bulletin2.Obj : Bulletin2.For Bulldir.Inc Bulluser.Inc Bullfolder.Inc \
                Bullfiles.Inc
   Fortran /Extend /NoList Bulletin2.For

Bulletin3.Obj : Bulletin3.For Bulldir.Inc Bullfolder.Inc Bulluser.Inc \
                Bullfiles.Inc
   Fortran /Extend /NoList Bulletin3.For

Bulletin4.Obj : Bulletin4.For Bullfolder.Inc Bulluser.Inc Bullfiles.Inc \
                Bulldir.Inc
   Fortran /Extend /NoList Bulletin4.For

Bulletin5.Obj : Bulletin5.For Bulldir.Inc Bulluser.Inc Bullfolder.Inc \
                Bullfiles.Inc
   Fortran /Extend /NoList Bulletin5.For

Bulletin6.Obj : Bulletin6.For Bulldir.Inc Bulluser.Inc Bullfolder.Inc \
                Bullfiles.Inc
   Fortran /Extend /NoList Bulletin6.For

Bulletin7.Obj : Bulletin7.For Bulldir.Inc Bulluser.Inc Bullfolder.Inc \
                Bullfiles.Inc
   Fortran /Extend /NoList Bulletin7.For

Bulletin8.Obj : Bulletin8.For Bulldir.Inc Bulluser.Inc Bullfolder.Inc \
                Bullfiles.Inc
   Fortran /Extend /NoList Bulletin8.For

Allmacs.Obj : Allmacs.mar
   Macro   /NoList Allmacs.Mar

Bullcom.Obj : Bullcom.cld
   Set Command /Obj Bullcom.Cld

Bullmain.Obj : Bullmain.cld
   Set Command /Obj Bullmain.Cld

Bull.Hlb : Bullcoms1.Hlp Bullcoms2.Hlp
   Library /Create /Help Bull.Hlb Bullcoms1.Hlp, Bullcoms2.Hlp
   Purge Bull.Hlb
*.hlb :
	lib/help/cre $*

$eod 