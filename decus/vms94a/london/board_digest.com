 $! $! BOARD_DIGEST.COM  $!C $! Command file invoked by folder associated with a BBOARD which is A $! is specified with /SPECIAL.  It will convert "digest" mail and A $! split it into separate messages.  This type of mail is used in > $! certain Arpanet mailing lists, such as TEXHAX and INFO-MAC. $!/ $ FF[0,8] = 12			! Define a form feed character  $ SET PROTECT=(W:RWED)/DEFAULT $ SET PROC/PRIV=SYSPRV" $ USER := 'F$GETJPI("","USERNAME")1 $ EXTRACT_FILE = "BULL_DIR:" + "''USER'" + ".TXT" * $ DEFINE/USER EXTRACT_FILE BULL_DIR:'USER' $ MAIL READ EXTRACT EXTRACT_FILE DELETE  $ OPEN/READ INPUT 'EXTRACT_FILE'" $ OPEN/WRITE OUTPUT 'EXTRACT_FILE' $ READ INPUT FROM_USER $AGAIN:  $ READ/END=ERROR INPUT BUFFER 5 $ IF F$EXTRACT(0,3,BUFFER) .NES. "To:" THEN GOTO SKIP * $ USER = F$EXTRACT(4,F$LEN(BUFFER),BUFFER) $ GOTO AGAIN1  $SKIP:C $ IF F$EXTRACT(0,15,BUFFER) .NES. "---------------" THEN GOTO AGAIN  $AGAIN1: $ READ/END=ERROR INPUT BUFFER D $ IF F$EXTRACT(0,15,BUFFER) .NES. "---------------" THEN GOTO AGAIN1 $ FROM = " " $ SUBJ = " " $NEXT: $ READ/END=EXIT INPUT BUFFER $FROM:: $ IF F$EXTRACT(0,5,BUFFER) .NES. "From:" THEN GOTO SUBJECT $ FROM = BUFFER  $ GOTO NEXT 	 $SUBJECT: : $ IF F$EXTRACT(0,8,BUFFER) .NES. "Subject:" THEN GOTO NEXT $ SUBJ = BUFFER - "Subject:" $F2:* $ IF F$LENGTH(SUBJ) .EQ. 0 THEN GOTO WRITE2 $ IF F$EXTRACT(0,1,SUBJ) .NES. " " THEN GOTO WRITE) $ SUBJ = F$EXTRACT(1,F$LENGTH(SUBJ),SUBJ) 	 $ GOTO F2  $WRITE:  $ WRITE OUTPUT FROM_USER" 				! Write From: + TAB + USERNAME $ WRITE OUTPUT "To:	" + USER& 				! Write To: + TAB + BBOARDUSERNAME $ WRITE OUTPUT "Subj:	" + SUBJ) 				! Write Subject: + TAB + mail subject ) $ WRITE OUTPUT ""		! Write one blank line * $ IF FROM .NES. " " THEN WRITE OUTPUT FROM $READ:% $ READ/END=EXIT/ERR=EXIT INPUT BUFFER C $ IF F$EXTRACT(0,15,BUFFER) .EQS. "---------------" THEN GOTO READ1  $ WRITE OUTPUT BUFFER  $ GOTO READ  $READ1: % $ READ/END=EXIT/ERR=EXIT INPUT BUFFER ? $ IF F$LOCATE(":",BUFFER) .EQ. F$LENGTH(BUFFER) THEN GOTO READ1  $ WRITE OUTPUT FF  $ FROM = " " $ SUBJ = " " $ GOTO FROM  $EXIT: $ CLOSE INPUT  $ CLOSE OUTPUT $ PUR 'EXTRACT_FILE' $ EXIT $ERROR:  $ CLOSE INPUT  $ CLOSE OUTPUT $ DELETE 'EXTRACT_FILE';