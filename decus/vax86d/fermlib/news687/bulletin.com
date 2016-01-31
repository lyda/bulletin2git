$! LIB:[LIB.NEWS]BULLETIN.COM
$!
$!  3 AUG 1986	A. Kreymer
$!	Stripped almost everything out of BULLETIN.COM, retaining only enough
$!	to post items to NEWS through a command of the form
$!
$!      $ @BULLETIN$COMMANDS:BULLETIN.COM file topic version "one line subject"
$!
$!	This is required for compatibility with Bison products which when
$!	have such code embedded in their installation procedures. News items
$!      should be posted with the NEWS/ADD command in all other cases.
$!	Tom Nicinski is the author of the original BULLETIN procedure, and is
$!	not responsible for any of the errors and blunders contained herein.
$!
$ TOPIC_SIZE	= 10		! Maximum length of topic name
$ VERSION_SIZE	= 7		! Maximum length of a product version
$ HELP_TOPIC_SIZE = TOPIC_SIZE + 1 + VERSION_SIZE	! Maximum size
$ ONE_LINE_SIZE	= -
  78 - HELP_TOPIC_SIZE - 2      ! Max size of one line description
$ DSR_FILE	= "DSR_FILE.TMP"          ! DSR input
$ NEWS_FILE	= "NEWS_FILE.TMP"         ! DSR output for NEWS
$!
$ OPERATION	= F$EDIT (P1, "UPCASE, UNCOMMENT, TRIM, COMPRESS")
$ IF ( F$LOCATE("ADD",OPERATION) .NE. 0 ) THEN WRITE SYS$OUTPUT "%NEWS-F-NOADD"
$ IF ( F$LOCATE("ADD",OPERATION) .NE. 0 ) THEN EXIT
$!
$ BULL_FILE	= F$EDIT (P2, "UPCASE, UNCOMMENT, COMPRESS, TRIM")
$ IF (BULL_FILE .EQS. "")  THEN WRITE SYS$OUTPUT "%NEWS-F-NOFILESPEC"
$ IF (BULL_FILE .EQS. "")  THEN EXIT
$ BULL_FILE	= F$PARSE (BULL_FILE, ".BUL", , , "SYNTAX_ONLY")
$ IF (F$SEARCH (BULL_FILE) .EQS. "")  THEN WRITE SYS$OUTPUT "%NEWS-F-NOFILE"
$ IF (F$SEARCH (BULL_FILE) .EQS. "")  THEN EXIT
$!
$ TOPIC		= F$EDIT (P3, "TRIM, UNCOMMENT")
$ IF (TOPIC .EQS. "")  THEN $ topic = F$PARSE (BULL_FILE, , , "NAME", "SYNTAX_ONLY")
$ TOPIC		= F$EXTRACT (0, TOPIC_SIZE, TOPIC)
$!
$ VERSION	= F$EDIT (P4, "UPCASE, UNCOMMENT, COMPRESS, TRIM")
$ VERSION	= F$EXTRACT (0, VERSION_SIZE, VERSION)
$!
$ IF P5.EQS." " THEN WRITE SYS$OUTPUT "%NEWS-F-NODESCRIPTION"
$ IF P5.EQS." " THEN EXIT
$ ONE_LINE	= F$EDIT (P5, "TRIM")
$ ONE_LINE	= F$EXTRACT (0, ONE_LINE_SIZE, ONE_LINE ) ! Truncate
$!
$ UPDATER = F$EDIT (F$TRNLNM ("SYS$NODE") + F$GETJPI ("", "USERNAME"), "TRIM")
$ HELP_TOPIC    = TOPIC
$ IF (VERSION .NES. "")  THEN HELP_TOPIC = HELP_TOPIC + "_" + VERSION
$ F$GEN_TOPIC_LINE = -
  "F$FAO (""!#AS  !#<!AS!>""," + -
  "help_topic_size, help_topic," + -
  "one_line_size, one_line)"
$ TOPIC_LINE    = 'F$GEN_TOPIC_LINE'
$!
$ CLOSE DSR_FILE  /ERROR= CLOSE_20$
$ CLOSE_20$:
$ OPEN /WRITE DSR_FILE 'DSR_FILE'
$!
$   WRITE DSR_FILE   ".page size 58, 67"
$   WRITE DSR_FILE   ".right margin  67"
$   WRITE DSR_FILE   ".fill"
$   WRITE DSR_FILE   ".justify"
$   WRITE DSR_FILE   ".spacing 1"
$   WRITE DSR_FILE   ".no paging"
$   WRITE DSR_FILE   ".no headers"
$   WRITE DSR_FILE   ".no number"
$   WRITE DSR_FILE   ".disable hyphenation"
$   WRITE DSR_FILE   ".noautoparagraph"
$   WRITE DSR_FILE   ".control characters"
$   WRITE DSR_FILE   ".left margin +1"          ! For LIB/HELP
$   WRITE DSR_FILE   ".save"                    ! Put in text of the item
$   WRITE DSR_FILE   ".require ""''BULL_FILE'"""
$   WRITE DSR_FILE   ".restore"
$ CLOSE DSR_FILE
$!
$ RUNOFF /BACKSPACE 'DSR_FILE' /OUTPUT= 'NEWS_FILE'
$ NEWSART/ADD/FILE='NEWS_FILE'/SUBJECT='TOPIC_LINE'
$ DELETE 'NEWS_FILE'.
$ DELETE 'DSR_FILE'.
$!
$ BULLETIN_EXIT:
$ EXIT_CLOSE_10$: CLOSE DSR_FILE  /ERROR= EXIT_CLOSE_20$
$ EXIT_CLOSE_20$:
$   ASSIGN /USER_MODE NL: sys$output		! Don't want any error messages
$   ASSIGN /USER_MODE NL: sys$error
$!   DELETE /NOLOG 'DSR_FILE';*, 'NEWS_FILE';*
