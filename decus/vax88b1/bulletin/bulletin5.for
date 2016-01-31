C
C  BULLETIN5.FOR, Version 8/8/88
C  Purpose: Contains subroutines for the bulletin board utility program.
C  Environment: MIT PFC VAX-11/780, VMS
C  Programmer: Mark R. London
C
	SUBROUTINE SET_FOLDER_DEFAULT(NOTIFY,READNEW,BRIEF)
C
C  SUBROUTINE SET_FOLDER_DEFAULT
C
C  FUNCTION: Sets flag defaults for specified folder
C
	IMPLICIT INTEGER (A-Z)

	INCLUDE 'BULLFOLDER.INC'

	INCLUDE 'BULLUSER.INC'

	COMMON /COMMAND_LINE/ INCMD
	CHARACTER*132 INCMD

	IF (.NOT.SETPRV_PRIV().AND.INCMD(:3).EQ.'SET') THEN
	   WRITE (6,'(
     &      '' ERROR: No privs to change all defaults.'')')
	   RETURN
	END IF

	CALL OPEN_FILE_SHARED(4)
	CALL READ_USER_FILE_HEADER(IER)
	IF (NOTIFY.EQ.0) CALL CLR2(NOTIFY_FLAG_DEF,FOLDER_NUMBER)
	IF (NOTIFY.EQ.1) CALL SET2(NOTIFY_FLAG_DEF,FOLDER_NUMBER)
	IF (READNEW.EQ.0) CALL CLR2(SET_FLAG_DEF,FOLDER_NUMBER)
	IF (READNEW.EQ.1) CALL SET2(SET_FLAG_DEF,FOLDER_NUMBER)
	IF (BRIEF.EQ.0) CALL CLR2(BRIEF_FLAG_DEF,FOLDER_NUMBER)
	IF (BRIEF.EQ.1) CALL SET2(BRIEF_FLAG_DEF,FOLDER_NUMBER)
	REWRITE(4) USER_HEADER

	IF (BRIEF.NE.-1.AND.NOTIFY.NE.-1.AND.READNEW.NE.-1) THEN
	   CALL READ_USER_FILE(IER)
	   DO WHILE (IER.EQ.0)
	      IF (TEMP_USER(:1).NE.'*') THEN
	         IF (NOTIFY.EQ.0) CALL CLR2(NOTIFY_FLAG,FOLDER_NUMBER)
	         IF (NOTIFY.EQ.1) CALL SET2(NOTIFY_FLAG,FOLDER_NUMBER)
	         IF (READNEW.EQ.0) CALL CLR2(SET_FLAG,FOLDER_NUMBER)
	         IF (READNEW.EQ.1) CALL SET2(SET_FLAG,FOLDER_NUMBER)
	         IF (BRIEF.EQ.0) CALL CLR2(BRIEF_FLAG,FOLDER_NUMBER)
	         IF (BRIEF.EQ.1) CALL SET2(BRIEF_FLAG,FOLDER_NUMBER)
	         REWRITE(4) TEMP_USER//USER_ENTRY(13:)
	      END IF
	      CALL READ_USER_FILE(IER)
	   END DO
	END IF
	CALL CLOSE_FILE(4)

	RETURN
	END




	SUBROUTINE REMOVE_FOLDER
C
C  SUBROUTINE REMOVE_FOLDER
C
C  FUNCTION: Removes a bulletin folder.
C

	IMPLICIT INTEGER (A-Z)

	INCLUDE 'BULLFOLDER.INC'

	INCLUDE 'BULLUSER.INC'

	INCLUDE 'BULLFILES.INC'

	EXTERNAL CLI$_ABSENT

	CHARACTER RESPONSE*1,TEMP*80

	IER = CLI$GET_VALUE('REMOVE_FOLDER',FOLDER1,LEN_T) ! Get folder name

	IF (IER.EQ.%LOC(CLI$_ABSENT)) THEN
	   IF (.NOT.FOLDER_SET) THEN
	      WRITE (6,'('' ERROR: No folder specified.'')')
	      RETURN
	   ELSE
	      FOLDER1 = FOLDER
	   END IF
	ELSE IF (LEN_T.GT.25) THEN
	   WRITE(6,'('' ERROR: Folder name must be < 26 characters.'')')
	   RETURN
	END IF

	CALL GET_INPUT_PROMPT(RESPONSE,LEN,
     &   'Are you sure you want to remove folder '
     &	 //FOLDER1(:TRIM(FOLDER1))//' (Y/N with N as default): ')
	IF (RESPONSE.NE.'y'.AND.RESPONSE.NE.'Y') THEN
	   WRITE (6,'('' Folder was not removed.'')')
	   RETURN
	END IF

	CALL OPEN_FILE(7)				! Open folder file
	CALL READ_FOLDER_FILE_KEYNAME_TEMP(FOLDER1,IER)	! See if folder exists
	FOLDER1_FILE = FOLDER_DIRECTORY(:TRIM(FOLDER_DIRECTORY))//
     &		FOLDER1

	IF (IER.NE.0) THEN
	   WRITE (6,'('' ERROR: No such folder exists.'')')
	   GO TO 1000
	END IF

	IF ((FOLDER1_OWNER.NE.USERNAME.AND..NOT.SETPRV_PRIV()).OR.
     &	     FOLDER1_NUMBER.EQ.0) THEN
	   WRITE (6,'('' ERROR: You are not able to remove the folder.'')')
	   GO TO 1000
	END IF

	IF (FOLDER1_BBOARD(:2).EQ.'::'.AND.BTEST(FOLDER1_FLAG,2)) THEN
	   OPEN (UNIT=17,STATUS='UNKNOWN',IOSTAT=IER,
     &		RECL=256,FILE=FOLDER1_BBOARD(3:TRIM(FOLDER1_BBOARD))
     &		//'::"TASK=BULLETIN1"')
	   IF (IER.EQ.0) THEN		! Disregister remote SYSTEM folder
	      WRITE(17,'(2A)',IOSTAT=IER) 14,0
	      CLOSE (UNIT=17)
	   END IF
	END IF

	TEMP = FOLDER_FILE
	FOLDER_FILE = FOLDER1_FILE
	TEMPSET = FOLDER_SET
	FOLDER_SET = .TRUE.
	CALL OPEN_FILE(2)			! Remove directory file
	CALL OPEN_FILE(1)			! Remove bulletin file
	CALL CLOSE_FILE_DELETE(1)
	CALL CLOSE_FILE_DELETE(2)
	FOLDER_FILE = TEMP
	FOLDER_SET = TEMPSET

	DELETE (7)

	TEMP_NUMBER = FOLDER_NUMBER
	FOLDER_NUMBER = FOLDER1_NUMBER
	CALL SET_FOLDER_DEFAULT(0,0,0)
	FOLDER_NUMBER = TEMP_NUMBER

	WRITE (6,'('' Folder removed.'')')

	IF (FOLDER.EQ.FOLDER1) FOLDER_SET = .FALSE.

1000	CALL CLOSE_FILE(7)

	RETURN

	END


	SUBROUTINE SELECT_FOLDER(OUTPUT,IER)
C
C  SUBROUTINE SELECT_FOLDER
C
C  FUNCTION: Selects the specified folder.
C
C  INPUTS:
C	OUTPUT - Specifies whether status messages are outputted.
C
C  NOTES:
C	FOLDER_NUMBER is used for selecting the folder.
C	If FOLDER_NUMBER = -1, the name stored in FOLDER1 is used.
C	If FOLDER_NUMBER = -2, the name stored in FOLDER1 is used,
C	but the folder is not selected if it is remote.
C	If the specified folder is on a remote node and does not have
C	a local entry (i.e. specified via NODENAME::FOLDERNAME), then
C	FOLDER_NUMBER is set to -1.
C

	IMPLICIT INTEGER (A-Z)

	INCLUDE 'BULLFOLDER.INC'

	INCLUDE 'BULLFILES.INC'

	INCLUDE 'BULLDIR.INC'

	INCLUDE 'BULLUSER.INC'

	INCLUDE '($RMSDEF)'
	INCLUDE '($SSDEF)'

	COMMON /POINT/ BULL_POINT

	COMMON /ACCESS/ READ_ONLY
	LOGICAL READ_ONLY

	COMMON /COMMAND_LINE/ INCMD
	CHARACTER*132 INCMD

	COMMON /REMOTE_FOLDER/ REMOTE_SET,REMOTE_UNIT
	DATA REMOTE_SET /.FALSE./

	COMMON /SHUTDOWN/ NODE_NUMBER,NODE_AREA
	COMMON /SHUTDOWN/ SHUTDOWN_FLAG(FLONG)

	EXTERNAL CLI$_ABSENT

	CHARACTER*80 LOCAL_FOLDER1_DESCRIP

	DIMENSION FIRST_TIME(FLONG)	! Bit set for folder if folder has
	DATA FIRST_TIME /FLONG*0/	! been selected before this.

	COMMAND = (INCMD(:3).EQ.'ADD').OR.(INCMD(:3).EQ.'DEL').OR.
     &		  (INCMD(:3).EQ.'DIR').OR.(INCMD(:3).EQ.'IND').OR.
     &		  (INCMD(:3).EQ.'REP').OR.(INCMD(:3).EQ.'SEL').OR.
     &		  (INCMD(:3).EQ.'SET')

	IF (.NOT.OUTPUT.OR.FOLDER_NUMBER.NE.-1.OR.COMMAND) THEN
	   IF (OUTPUT) THEN			! Get folder name
	      IER = CLI$GET_VALUE('SELECT_FOLDER',FOLDER1)
	   END IF

	   FLEN = TRIM(FOLDER1)		! Add GENERAL after :: if no
	   IF (FLEN.GT.1) THEN		! name specified after the ::
	      IF (FOLDER1(FLEN-1:FLEN).EQ.'::') THEN
	         FOLDER1 = FOLDER1(:FLEN)//'GENERAL'
	      END IF
	   END IF

	   IF (((IER.EQ.%LOC(CLI$_ABSENT).OR.FOLDER1.EQ.'GENERAL').AND.
     &	    OUTPUT).OR.((FOLDER_NUMBER.EQ.0.OR.(FOLDER1.EQ.'GENERAL'.AND.
     &	    FOLDER_NUMBER.LE.-1)).AND..NOT.OUTPUT)) THEN ! Select GENERAL
	      FOLDER_NUMBER = 0
	      FOLDER1 = 'GENERAL'
	   END IF
	END IF

	CALL OPEN_FILE_SHARED(7)			! Go find folder

	REMOTE_TEST = 0

	IF (OUTPUT.OR.FOLDER_NUMBER.LE.-1) THEN
	   REMOTE_TEST = INDEX(FOLDER1,'::')
	   IF (REMOTE_TEST.GT.0) THEN
	      FOLDER1_BBOARD = '::'//FOLDER1(:REMOTE_TEST-1)
	      FOLDER1 = FOLDER1(REMOTE_TEST+2:TRIM(FOLDER1))
	      FOLDER1_NUMBER = -1
	      IER = 0
	   ELSE IF (INCMD(:2).EQ.'SE') THEN
	      CALL READ_FOLDER_FILE_KEYNAME_TEMP
     &				(FOLDER1(:TRIM(FOLDER1)),IER)
	   ELSE
	      CALL READ_FOLDER_FILE_KEYNAME_TEMP(FOLDER1,IER)
	   END IF
	ELSE
	   FOLDER1_NUMBER = FOLDER_NUMBER
	   CALL READ_FOLDER_FILE_KEYNUM_TEMP(FOLDER_NUMBER,IER)
	END IF

	IF (BTEST(FOLDER1_FLAG,29)) THEN	! Error in folder flag!!
	   FOLDER1_FLAG = FOLDER1_FLAG.AND.3
	   F1_EXPIRE_LIMIT = 0
	   CALL REWRITE_FOLDER_FILE_TEMP
	END IF

	CALL CLOSE_FILE(7)

	IF (IER.EQ.0.AND.FOLDER1_BBOARD(:2).EQ.'::') THEN
	   IF (FOLDER_NUMBER.EQ.-2) RETURN	! Don't allow
	   LOCAL_FOLDER1_FLAG = FOLDER1_FLAG
	   LOCAL_FOLDER1_DESCRIP = FOLDER1_DESCRIP
	   CALL CONNECT_REMOTE_FOLDER(READ_ONLY,IER)
	   IF (IER.NE.0) THEN
	      IF (OUTPUT) THEN
	         WRITE (6,'('' ERROR: Unable to connect to folder.'')')
	      END IF
	      RETURN
	   END IF
	   IF (REMOTE_TEST.GT.0) THEN	! Folder specified with "::"
	      FOLDER1 = FOLDER1_BBOARD(3:TRIM(FOLDER1_BBOARD))//'::'//
     &			FOLDER1
	      FOLDER1_NUMBER = -1
	   ELSE				! True remote folder
	      FOLDER1_DESCRIP = LOCAL_FOLDER1_DESCRIP	! Use local description
	      IF (BTEST(FOLDER1_FLAG,0)) THEN	! Copy remote folder protection
		 LOCAL_FOLDER1_FLAG = IBSET(LOCAL_FOLDER1_FLAG,0)
	      ELSE
		 LOCAL_FOLDER1_FLAG = IBCLR(LOCAL_FOLDER1_FLAG,0)
	      END IF
	      FOLDER1_FLAG = LOCAL_FOLDER1_FLAG		! Use local flag info
	      CALL OPEN_FILE(7)		! Update local folder information
              CALL READ_FOLDER_FILE_KEYNAME(FOLDER1,IER)
	      FOLDER_COM = FOLDER1_COM
	      CALL REWRITE_FOLDER_FILE
	      CALL CLOSE_FILE(7)
	   END IF
	   REMOTE_SET = .TRUE.
	END IF

	IF (IER.EQ.0) THEN				! Folder found
	   FOLDER1_FILE = FOLDER_DIRECTORY(:TRIM(FOLDER_DIRECTORY))
     &		//FOLDER1
	   IF (BTEST(FOLDER1_FLAG,0).AND.FOLDER1_BBOARD(:2).NE.'::'
     &		.AND..NOT.SETPRV_PRIV()) THEN
				! Is folder protected and not remote?
	      CALL CHKACL
     &		(FOLDER1_FILE(:TRIM(FOLDER1_FILE))//'.BULLFIL',IER)
	      IF (IER.NE.(SS$_ACLEMPTY.OR.SS$_NORMAL).AND.USERNAME
     &		  .NE.FOLDER1_OWNER) THEN
	         CALL CHECK_ACCESS
     &		  (FOLDER1_FILE(:TRIM(FOLDER1_FILE))//'.BULLFIL',USERNAME,
     &		  READ_ACCESS,WRITE_ACCESS)
	         IF (.NOT.READ_ACCESS.AND..NOT.WRITE_ACCESS) THEN
		  IF (OUTPUT) THEN
	           WRITE(6,'('' You are not allowed to access folder.'')')
	           WRITE(6,'('' See '',A,'' if you wish to access folder.'')')
     &			FOLDER1_OWNER(:TRIM(FOLDER1_OWNER))
		  ELSE IF (TEST2(BRIEF_FLAG,FOLDER1_NUMBER).OR.
     &			 TEST2(SET_FLAG,FOLDER1_NUMBER)) THEN
		   CALL OPEN_FILE_SHARED(4)
		   CALL READ_USER_FILE_KEYNAME(USERNAME,IER)
		   CALL CLR2(BRIEF_FLAG,FOLDER1_NUMBER)
		   CALL CLR2(SET_FLAG,FOLDER1_NUMBER)
		   IF (IER.EQ.0) REWRITE (4) USER_ENTRY
		   CALL CLOSE_FILE(4)
		  END IF
		  IER = 0
		  RETURN
	         END IF
	      END IF
	   ELSE					! Folder not protected
	      IER = SS$_ACLEMPTY.OR.SS$_NORMAL	! Indicate folder selected
	   END IF

	   IF (FOLDER1_BBOARD(:2).NE.'::') THEN
	      IF (REMOTE_SET) CLOSE(UNIT=REMOTE_UNIT)
	      REMOTE_SET = .FALSE.
	   END IF

	   IF (IER) THEN
	      FOLDER_COM = FOLDER1_COM		! Folder successfully set so
	      FOLDER_FILE = FOLDER1_FILE	! update folder parameters

	      IF (FOLDER_NUMBER.NE.0) THEN
		 FOLDER_SET = .TRUE.
	      ELSE
		 FOLDER_SET = .FALSE.
	      END IF

	      IF (OUTPUT.AND.INCMD(:3).NE.'DIR') THEN
		 WRITE (6,'('' Folder has been set to '',A)') 
     &		    FOLDER(:TRIM(FOLDER))//'.'
		 BULL_POINT = 0	! Reset pointer to first bulletin
	      END IF

	      IF (IER.NE.(SS$_ACLEMPTY.OR.SS$_NORMAL).AND.USERNAME
     &		  .NE.FOLDER_OWNER) THEN
	         IF (.NOT.WRITE_ACCESS) THEN
		   IF (OUTPUT.AND.INCMD(:3).NE.'DIR')
     &		    WRITE (6,'('' Folder only accessible for reading.'')')
		   READ_ONLY = .TRUE.
		 ELSE
		   READ_ONLY = .FALSE.
		 END IF
	      ELSE
		 READ_ONLY = .FALSE.
	      END IF

	      IF (FOLDER_NUMBER.GT.0) THEN
		IF (TEST_BULLCP()) THEN
		 CALL SET2(FIRST_TIME,FOLDER_NUMBER)
		ELSE IF (.NOT.TEST2(FIRST_TIME,FOLDER_NUMBER)) THEN
	       			! If first select, look for expired messages.
		 CALL OPEN_FILE(2)
		 CALL READDIR(0,IER)	! Get header info from BULLDIR.DAT
	 	 IF (IER.EQ.1) THEN		! Is header present?
	   	    IER = COMPARE_DATE(NEWEST_EXDATE,' ') ! Yes. Any expired?
		    IF (SHUTDOWN.GT.0.AND.NODE_AREA.GT.0.AND.
     &			(FOLDER_NUMBER.EQ.0.OR.BTEST(FOLDER_FLAG,2))
     &			.AND.TEST2(SHUTDOWN_FLAG,FOLDER_NUMBER)) THEN
						! Do shutdown bulletins exist?
		       SHUTDOWN = 0
		       IER1 = -1
		    ELSE
		       IF (TEST2(SHUTDOWN_FLAG,FOLDER_NUMBER)) THEN
			  CALL UPDATE_SHUTDOWN(FOLDER_NUMBER)
		       END IF
	               IER1 = 1
		    END IF
	 	    IF (IER.LE.0.OR.IER.GT.20*356.OR.IER1.LE.0) THEN
		       CALL UPDATE	! Need to update
		    END IF
		 ELSE
		    NBULL = 0
		 END IF
		 CALL CLOSE_FILE(2)
		 CALL SET2(FIRST_TIME,FOLDER_NUMBER)
	        END IF
	      END IF

	      IF (FOLDER_NUMBER.NE.0) THEN
	        IF (OUTPUT.AND.INCMD(:3).NE.'DIR') THEN
	         DIFF = COMPARE_BTIM(LAST_READ_BTIM(1,FOLDER_NUMBER+1),
     &					F_NEWEST_BTIM)
	         IF (DIFF.LT.0.AND.F_NBULL.GT.0) THEN 	! If new unread messages
		  CALL FIND_NEWEST_BULL			! See if we can find it
		  IF (BULL_POINT.NE.-1) THEN
	     	    WRITE(6,'('' Type READ to read new messages.'')')
		    NEW_COUNT = F_NBULL - BULL_POINT
		    DIG = 0
		    DO WHILE (NEW_COUNT.GT.0)
		      NEW_COUNT = NEW_COUNT / 10
		      DIG = DIG + 1
		    END DO
		    WRITE(6,'('' There are '',I<DIG>,'' new messages.'')')
     &			F_NBULL - BULL_POINT	! Alert user if new bulletins
		  ELSE
		    BULL_POINT = 0
		  END IF
		 END IF
		END IF
	      END IF
	      IER = 1
	   ELSE IF (OUTPUT) THEN
	      WRITE (6,'('' Cannot access specified folder.'')')
	      CALL SYS_GETMSG(IER)
	   END IF
	ELSE						! Folder not found
	   IF (OUTPUT) WRITE (6,'('' ERROR: Folder does not exist.'')')
	   IER = 0
	END IF

	RETURN

	END



	SUBROUTINE CONNECT_REMOTE_FOLDER(READ_ONLY,IER)
C
C  SUBROUTINE CONNECT_REMOTE_FOLDER
C
C  FUNCTION: Connects to folder that is located on other DECNET node.
C
	IMPLICIT INTEGER (A-Z)

	COMMON /REMOTE_FOLDER/ REMOTE_SET,REMOTE_UNIT
	DATA REMOTE_UNIT /15/

	INCLUDE 'BULLUSER.INC'

	INCLUDE 'BULLFOLDER.INC'

	CHARACTER*12 FOLDER_BBOARD_SAVE,FOLDER_OWNER_SAVE

	DIMENSION DUMMY(2)

	REMOTE_UNIT = 31 - REMOTE_UNIT

	OPEN (UNIT=REMOTE_UNIT,STATUS='UNKNOWN',IOSTAT=IER,RECL=256,
     &		FILE=FOLDER1_BBOARD(3:TRIM(FOLDER1_BBOARD))
     &		//'::"TASK=BULLETIN1"')

	IF (IER.EQ.0) THEN
	   WRITE (REMOTE_UNIT,'(2A)',IOSTAT=IER) 1,FOLDER1
	   FOLDER_OWNER_SAVE = FOLDER1_OWNER
	   FOLDER_BBOARD_SAVE = FOLDER1_BBOARD
	   FOLDER_NUMBER_SAVE = FOLDER1_NUMBER
	   IF (IER.EQ.0) THEN
	      READ(REMOTE_UNIT,'(5A)',IOSTAT=IER)IER1,READ_ONLY,
     &		DUMMY(1),DUMMY(2),FOLDER1_COM
	   END IF
	END IF

	IF (IER.NE.0.OR..NOT.IER1) THEN
	   CLOSE (UNIT=REMOTE_UNIT)
	   REMOTE_UNIT = 31 - REMOTE_UNIT
	   IF (IER.EQ.0.AND.FOLDER_NUMBER_SAVE.GE.0) THEN
	      IF (TEST2(BRIEF_FLAG,FOLDER_NUMBER_SAVE)
     &		  .OR.TEST2(SET_FLAG,FOLDER_NUMBER_SAVE)) THEN
	         CALL OPEN_FILE_SHARED(4)
	         CALL READ_USER_FILE_KEYNAME(USERNAME,IER)
	         CALL CLR2(BRIEF_FLAG,FOLDER_NUMBER_SAVE)
	         CALL CLR2(SET_FLAG,FOLDER_NUMBER_SAVE)
	         IF (IER.EQ.0) REWRITE (4) USER_ENTRY
	         CALL CLOSE_FILE(4)
	      END IF
	   END IF
	   IER = 2
	ELSE
	   FOLDER1_BBOARD = FOLDER_BBOARD_SAVE
	   FOLDER1_NUMBER = FOLDER_NUMBER_SAVE
	   FOLDER1_OWNER = FOLDER_OWNER_SAVE
	   CLOSE (UNIT=31-REMOTE_UNIT)
	   IF ((FOLDER_NUMBER.NE.FOLDER1_NUMBER.AND.(DUMMY(1).NE.0
     &		.OR.DUMMY(2).NE.0)).OR.FOLDER1_NUMBER.EQ.-1) THEN
	      LAST_READ_BTIM(1,FOLDER1_NUMBER+1) = DUMMY(1)
	      LAST_READ_BTIM(2,FOLDER1_NUMBER+1) = DUMMY(2)
	   END IF
	   IER = 0
	END IF

	RETURN
	END









	SUBROUTINE UPDATE_FOLDER
C
C  SUBROUTINE UPDATE_FOLDER
C
C  FUNCTION: Updates folder info due to new message.
C

	IMPLICIT INTEGER (A-Z)

	INCLUDE 'BULLDIR.INC'

	INCLUDE 'BULLFOLDER.INC'

	IF (FOLDER_NUMBER.LT.0) RETURN

	CALL OPEN_FILE_SHARED(7)			! Open folder file

	CALL READ_FOLDER_FILE_KEYNAME(FOLDER,IER)

	CALL SYS_BINTIM(NEWEST_DATE//' '//NEWEST_TIME,F_NEWEST_BTIM)

	F_NBULL = NBULL

	IF (FOLDER_NUMBER.EQ.0) FOLDER_FLAG = IBSET(FOLDER_FLAG,2)

	IF (.NOT.BTEST(SYSTEM,0)) THEN 	! Is non-system message?
	   F_NEWEST_NOSYS_BTIM(1) = F_NEWEST_BTIM(1) ! If so, update latest
	   F_NEWEST_NOSYS_BTIM(2) = F_NEWEST_BTIM(2) ! system time.
	END IF

	CALL REWRITE_FOLDER_FILE

	CALL CLOSE_FILE(7)

	RETURN
	END



	SUBROUTINE SHOW_FOLDER
C
C  SUBROUTINE SHOW_FOLDER
C
C  FUNCTION: Shows the information on any folder.
C

	IMPLICIT INTEGER (A-Z)

	INCLUDE 'BULLUSER.INC'

	INCLUDE 'BULLFOLDER.INC'

	INCLUDE 'BULLFILES.INC'

	INCLUDE '($SSDEF)'

	INCLUDE '($RMSDEF)'

	EXTERNAL CLI$_ABSENT

	IF (CLI$GET_VALUE('SHOW_FOLDER',FOLDER1).EQ.%LOC(CLI$_ABSENT))
     &		FOLDER1 = FOLDER

	IF (INDEX(FOLDER1,'::').NE.0) THEN
	   WRITE (6,'('' ERROR: Invalid command for remote folder.'')')
	   RETURN
	END IF

	CALL OPEN_FILE_SHARED(7)			! Open folder file

	CALL READ_FOLDER_FILE_KEYNAME_TEMP(FOLDER1,IER)
	FOLDER1_FILE = FOLDER_DIRECTORY(:TRIM(FOLDER_DIRECTORY))//
     &		FOLDER1
	IF (IER.NE.0) THEN
	   WRITE (6,'('' ERROR: Specified folder was not found.'')')
	   CALL CLOSE_FILE(7)
	   RETURN
	ELSE IF (FOLDER.EQ.FOLDER1) THEN
	   WRITE (6,1000) FOLDER1,FOLDER1_OWNER,
     &			FOLDER1_DESCRIP(:TRIM(FOLDER1_DESCRIP))
	ELSE
	   WRITE (6,1010) FOLDER1,FOLDER1_OWNER,
     &			FOLDER1_DESCRIP(:TRIM(FOLDER1_DESCRIP))
	END IF

	IF (CLI$PRESENT('FULL')) THEN
	   CALL CHKACL
     &		(FOLDER1_FILE(:TRIM(FOLDER1_FILE))//'.BULLFIL',IER)
	   IF (IER.EQ.(SS$_ACLEMPTY.OR.SS$_NORMAL).OR.(.NOT.IER)) THEN
	      IF (FOLDER1_BBOARD(:2).EQ.'::'.AND.	! Is folder remote
     &		BTEST(FOLDER1_FLAG,0)) THEN		! and private?
	         WRITE (6,'('' Folder is a private folder.'')')
	      ELSE
	         WRITE (6,'('' Folder is not a private folder.'')')
	      END IF
	   ELSE
	      CALL CHECK_ACCESS
     &		(FOLDER1_FILE(:TRIM(FOLDER1_FILE))//'.BULLFIL',USERNAME,
     &		 READ_ACCESS,WRITE_ACCESS)
	      IF (WRITE_ACCESS)
     &	      CALL SHOWACL(FOLDER1_FILE(:TRIM(FOLDER1_FILE))//'.BULLFIL')
	   END IF
	   IF (SETPRV_PRIV().OR.USERNAME.EQ.FOLDER1_OWNER) THEN
	      IF (FOLDER1_BBOARD(:2).EQ.'::') THEN
		 FLEN = TRIM(FOLDER1_BBOARD)
		 WRITE (6,'('' Folder is located on node '',
     &		   A<FLEN-2>,''.'')') FOLDER1_BBOARD(3:FLEN)
	      ELSE IF (FOLDER1_BBOARD.NE.'NONE') THEN
		 FLEN = TRIM(FOLDER1_BBOARD)
		 IF (FLEN.GT.0) THEN
 	          WRITE (6,'('' BBOARD for folder is '',A<FLEN>,''.'')')
     &		 	FOLDER1_BBOARD(:FLEN)
		 END IF
		 IF ((USERB1.EQ.0.AND.GROUPB1.EQ.0).OR.BTEST(USERB1,31)) THEN
 		  WRITE (6,'('' BBOARD was specified with /SPECIAL.'')')
		  IF (BTEST(GROUPB1,31)) THEN
		   WRITE (6,'('' BBOARD was specified with /VMSMAIL.'')')
		  END IF
		 END IF
		 IF (FOLDER1_BBEXPIRE.GT.0) THEN
		  WRITE (6,'('' BBOARD expiration is '',I3,'' days.'')')
     &			FOLDER1_BBEXPIRE
		 ELSE
		  WRITE (6,'('' BBOARD messages will not expire.'')')
		 END IF
	      ELSE
	         WRITE (6,'('' No BBOARD has been defined.'')')
	      END IF
	      IF (BTEST(FOLDER1_FLAG,2)) THEN
		 WRITE (6,'('' SYSTEM has been set.'')')
	      END IF
	      IF (BTEST(FOLDER1_FLAG,1)) THEN
		 WRITE (6,'('' DUMP has been set.'')')
	      END IF
	      IF (F1_EXPIRE_LIMIT.GT.0) THEN
		 WRITE (6,'('' EXPIRATION limit is '',I3,'' days.'')')
     &			F1_EXPIRE_LIMIT
	      END IF
	      CALL OPEN_FILE_SHARED(4)
	      CALL READ_USER_FILE_HEADER(IER)
	      IF (TEST2(SET_FLAG_DEF,FOLDER1_NUMBER)) THEN
	       IF (TEST2(BRIEF_FLAG_DEF,FOLDER1_NUMBER)) THEN
		 WRITE (6,'('' Default is BRIEF.'')')
	       ELSE
		 WRITE (6,'('' Default is READNEW.'')')
	       END IF
	      ELSE
	       IF (TEST2(BRIEF_FLAG_DEF,FOLDER1_NUMBER)) THEN
		 WRITE (6,'('' Default is SHOWNEW.'')')
	       ELSE
		 WRITE (6,'('' Default is NOREADNEW.'')')
	       END IF
	      END IF
	      IF (TEST2(NOTIFY_FLAG_DEF,FOLDER1_NUMBER)) THEN
		 WRITE (6,'('' Default is NOTIFY.'')')
	      ELSE
		 WRITE (6,'('' Default is NONOTIFY.'')')
	      END IF
	      CALL CLOSE_FILE(4)
	   END IF
	END IF

	CALL CLOSE_FILE(7)

	RETURN

1000	FORMAT(' Current folder is: ',A25,' Owner: ',A12,
     &		' Description: ',/,1X,A)
1010	FORMAT(' Folder name is: ',A25,' Owner: ',A12,
     &		' Description: ',/,1X,A)
	END


	SUBROUTINE DIRECTORY_FOLDERS(FOLDER_COUNT)
C
C  SUBROUTINE DIRECTORY_FOLDERS
C
C  FUNCTION: Display all FOLDER entries.
C
	IMPLICIT INTEGER (A - Z)

	INCLUDE 'BULLFOLDER.INC'

	INCLUDE 'BULLUSER.INC'

	COMMON /PAGE/ PAGE_LENGTH,PAGING
	LOGICAL PAGING

	DATA SCRATCH_D1/0/

	CHARACTER*17 DATETIME

	EXTERNAL CLI$_NEGATED,CLI$_PRESENT

	IF (FOLDER_COUNT.GT.0) GO TO 50		! Skip init steps if this is
						! not the 1st page of folder

	IF (CLI$PRESENT('DESCRIBE')) THEN
	   NLINE = 2	! Include folder descriptor if /DESCRIBE specified
	ELSE
	   NLINE = 1
	END IF

C
C  Folder listing is first buffered into temporary memory storage before
C  being outputted to the terminal.  This is to be able to quickly close the
C  folder file, and to avoid the possibility of the user holding the screen,
C  and thus causing the folder file to stay open.  The temporary memory
C  is structured as a linked-list queue, where SCRATCH_D1 points to the header
C  of the queue.  See BULLSUBS.FOR for more description of the queue.
C
	CALL INIT_QUEUE(SCRATCH_D1,FOLDER1_COM)
	SCRATCH_D = SCRATCH_D1

	CALL OPEN_FILE_SHARED(7)		! Get folder file

	NUM_FOLDER = 0
	IER = 0
	FOLDER1 = '                         '	! Start folder search
	DO WHILE (IER.EQ.0)			! Copy all bulletins from file
	   CALL READ_FOLDER_FILE_TEMP(IER)
	   IF (IER.EQ.0) THEN
	      NUM_FOLDER = NUM_FOLDER + 1
	      CALL WRITE_QUEUE(%VAL(SCRATCH_D),SCRATCH_D,FOLDER1_COM)
	   END IF
	END DO

	CALL CLOSE_FILE(7)			! We don't need file anymore

	IF (NUM_FOLDER.EQ.0) THEN
	   WRITE (6,'('' There are no folders.'')')
	   RETURN
	END IF

C
C  Folder entries are now in queue.  Output queue entries to screen.
C

	SCRATCH_D = SCRATCH_D1			! Init queue pointer to header

	FOLDER_COUNT = 1			! Init folder number counter

50	CALL LIB$ERASE_PAGE(1,1)		! Clear the screen

	WRITE (6,'(1X,''Folder'',22X,''Last message'',7X,''Messages'',
     &		2X,''Owner'',/,1X,80(''-''))')

	IF (.NOT.PAGING) THEN
	   DISPLAY = (NUM_FOLDER-FOLDER_COUNT+1)*NLINE+2
	ELSE
	   DISPLAY = MIN((NUM_FOLDER-FOLDER_COUNT+1)*NLINE+2,PAGE_LENGTH-4)
			! If more entries than page size, truncate output
	END IF

	DO I=FOLDER_COUNT,FOLDER_COUNT+(DISPLAY-2)/NLINE-1
	   CALL READ_QUEUE(%VAL(SCRATCH_D),SCRATCH_D,FOLDER1_COM)
	   DIFF = COMPARE_BTIM
     &			(LAST_READ_BTIM(1,FOLDER1_NUMBER+1),F1_NEWEST_BTIM)
	   IF (F1_NBULL.GT.0) THEN
	      CALL SYS$ASCTIM(,DATETIME,F1_NEWEST_BTIM,)
	   ELSE
	      DATETIME = '      NONE'
	   END IF
	   IF (DIFF.GE.0.OR.F1_NBULL.EQ.0) THEN
	      WRITE (6,1000) ' '//FOLDER1,DATETIME,F1_NBULL,FOLDER1_OWNER
	   ELSE
	      WRITE (6,1000) '*'//FOLDER1,DATETIME,F1_NBULL,FOLDER1_OWNER
	   END IF
	   IF (NLINE.EQ.2) WRITE (6,'(1X,A)') FOLDER1_DESCRIP
	   FOLDER_COUNT = FOLDER_COUNT + 1	! Update folder counter
	END DO

	IF (FOLDER_COUNT.GT.NUM_FOLDER) THEN	! Outputted all entries?
	   FOLDER_COUNT = 0			! Yes. Set counter to 0.
	ELSE
	   WRITE(6,1010)			! Else say there are more
	END IF

	RETURN

1000	FORMAT(1X,A26,2X,A17,2X,I8,2X,A12)
1010	FORMAT(1X,/,' Press RETURN for more...',/)

	END


	SUBROUTINE SET_ACCESS(ACCESS)
C
C  SUBROUTINE SET_ACCESS
C
C  FUNCTION: Set access on folder for specified ID.
C
C  PARAMETERS:
C	ACCESS  -  Logical: If .true., grant access, if .false. deny access
C

	IMPLICIT INTEGER (A-Z)

	INCLUDE 'BULLFOLDER.INC'

	INCLUDE 'BULLUSER.INC'

	INCLUDE 'BULLFILES.INC'

	INCLUDE '($SSDEF)'

	LOGICAL ACCESS,ALL,READONLY

	EXTERNAL CLI$_ABSENT

	CHARACTER ID*25,RESPONSE*1

	IF (CLI$PRESENT('ALL')) THEN
	   ALL = .TRUE.
	ELSE
	   ALL = .FALSE.
	END IF

	IF (CLI$PRESENT('READONLY')) THEN
	   READONLY = .TRUE.
	ELSE
	   READONLY = .FALSE.
	END IF

	IER = CLI$GET_VALUE('ACCESS_FOLDER',FOLDER1,LEN) ! Get folder name

	IF (IER.EQ.%LOC(CLI$_ABSENT)) THEN
	   FOLDER1 = FOLDER
	ELSE IF (LEN.GT.25) THEN
	   WRITE(6,'('' ERROR: Folder name must be < 26 characters.'')')
	   RETURN
	END IF

	IF (.NOT.ALL) THEN
	   IER = CLI$GET_VALUE('ACCESS_ID',ID,LEN) 	! Get ID
	   IF (LEN.GT.25) THEN
	      WRITE(6,'('' ERROR: ID name must be < 26 characters.'')')
	      RETURN
	   END IF
	END IF

	CALL OPEN_FILE(7)		! Open folder file
	CALL READ_FOLDER_FILE_KEYNAME_TEMP(FOLDER1,IER)	! See if it exists
	OLD_FOLDER1_FLAG = FOLDER1_FLAG
	CALL CLOSE_FILE(7)

	IF ((.NOT.ALL).AND.(ID.EQ.FOLDER1_OWNER)) THEN
	 WRITE (6,'(
     &	  '' ERROR: Cannot modify access for owner of folder.'')')
	 RETURN
	END IF

	IF (IER.NE.0) THEN
	   WRITE (6,'('' ERROR: No such folder exists.'')')
	ELSE IF (FOLDER1_OWNER.NE.USERNAME.AND..NOT.SETPRV_PRIV()) THEN
	   WRITE (6,
     &	'('' ERROR: You are not able to modify access to the folder.'')')
	ELSE
	   FOLDER1_FILE = FOLDER_DIRECTORY(:TRIM(FOLDER_DIRECTORY))//
     &		FOLDER1
	   CALL CHKACL
     &		(FOLDER1_FILE(:TRIM(FOLDER1_FILE))//'.BULLFIL',IER)
	   IF (IER.EQ.(SS$_ACLEMPTY.OR.SS$_NORMAL)) THEN
	     IF ((ALL.AND..NOT.READONLY).OR.(.NOT.ACCESS)) THEN
	        WRITE (6,'('' ERROR: Folder is not a private folder.'')')
		RETURN
	     END IF
	     CALL GET_INPUT_PROMPT(RESPONSE,LEN,
     &      'Folder is not private. Do you want to make it so? (Y/N): ')
	     IF (RESPONSE.NE.'y'.AND.RESPONSE.NE.'Y') THEN
	       WRITE (6,'('' Folder access was not changed.'')')
	       RETURN
	     ELSE
	       FOLDER1_FLAG = IBSET(FOLDER1_FLAG,0)
	       IF (READONLY.AND.ALL) THEN
	          CALL ADD_ACL('*','R',IER)
	       ELSE
	          CALL ADD_ACL('*','NONE',IER)
	       END IF
	       CALL ADD_ACL(FOLDER1_OWNER,'R+W+C',IER)
	       IF (ALL) THEN		! All finished, so exit
	        WRITE (6,'('' Access to folder has been modified.'')')
		GOTO 100
	       END IF
	     END IF
	   END IF
	   IF (ACCESS) THEN
	      IF (.NOT.ALL) THEN
	         IF (READONLY) THEN
	            CALL ADD_ACL(ID,'R',IER)
		 ELSE
	            CALL ADD_ACL(ID,'R+W',IER)
		 END IF
	      ELSE
	         IF (READONLY) THEN
	            CALL ADD_ACL('*','R',IER)
		 ELSE
		    CALL DEL_ACL(' ','R+W',IER)
		    FOLDER1_FLAG = IBCLR(FOLDER1_FLAG,0)
		 END IF
	      END IF
	   ELSE
	      IF (ALL) THEN
		 CALL DEL_ACL('*','R',IER)
	      ELSE
	         CALL DEL_ACL(ID,'R+W',IER)
	         IF (.NOT.IER) CALL DEL_ACL(ID,'R',IER)
	      END IF
	   END IF
	   IF (.NOT.IER) THEN
	      WRITE(6,'('' ERROR: Cannot modify ACL of folder files.'')')
	      CALL SYS_GETMSG(IER)
	   ELSE
	      WRITE (6,'('' Access to folder has been modified.'')')
100	      IF (OLD_FOLDER1_FLAG.NE.FOLDER1_FLAG) THEN
	       CALL OPEN_FILE(7)		! Open folder file
	       OLD_FOLDER1_FLAG = FOLDER1_FLAG
	       CALL READ_FOLDER_FILE_KEYNAME_TEMP(FOLDER1,IER)
	       FOLDER1_FLAG = OLD_FOLDER1_FLAG
	       CALL REWRITE_FOLDER_FILE_TEMP
	       CALL CLOSE_FILE(7)
	      END IF
	   END IF
	END IF

	RETURN

	END



	SUBROUTINE CHKACL(FILENAME,IERACL)
C
C  SUBROUTINE CHKACL
C
C  FUNCTION: Checks ACL of given file.
C
C  PARAMETERS:
C	FILENAME - Name of file to check.
C	IERACL   - Error returned for attempt to open file.
C

	IMPLICIT INTEGER (A-Z)

	CHARACTER*(*) FILENAME

	INCLUDE '($ACLDEF)'
	INCLUDE '($SSDEF)'

	CHARACTER*255 ACLENT,ACLSTR

	CALL INIT_ITMLST	! Initialize item list
	CALL ADD_2_ITMLST(255,ACL$C_READACL,%LOC(ACLENT))
	CALL END_ITMLST(ACL_ITMLST)	! Get address of itemlist

	IERACL=SYS$CHANGE_ACL(,ACL$C_FILE,FILENAME,%VAL(ACL_ITMLST),,,)

	IF (IERACL.EQ.SS$_ACLEMPTY) THEN
	   IERACL = SS$_NORMAL.OR.IERACL
	END IF

	RETURN
	END



	SUBROUTINE CHECK_ACCESS(FILENAME,USERNAME,READ_ACCESS,WRITE_ACCESS)
C
C  SUBROUTINE CHECK_ACCESS
C
C  FUNCTION: Checks ACL of given file.
C
C  PARAMETERS:
C	FILENAME - Name of file to check.
C	USERNAME - Name of user to check access for.
C	READ_ACCESS - Error returned indicating read access.
C	WRITE_ACCESS - Error returned indicating write access.
C
C  NOTE: SYS$CHECK_ACCESS is only available under V4.4 or later.
C	If you have an earlier version, comment out the lines which call
C	it and set both READ_ACCESS and WRITE_ACCESS to 1, which will
C	allow program to run, but will not allow READONLY access feature.
C

	IMPLICIT INTEGER (A-Z)

	CHARACTER FILENAME*(*),USERNAME*(*),ACE*255,OUTPUT*80

	INCLUDE '($ACLDEF)'
	INCLUDE '($CHPDEF)'
	INCLUDE '($ARMDEF)'

	IF (SETPRV_PRIV()) THEN
	   READ_ACCESS = 1
	   WRITE_ACCESS = 1
	   RETURN
	END IF

	CALL INIT_ITMLST	! Initialize item list
	CALL ADD_2_ITMLST(4,CHP$_FLAGS,%LOC(FLAGS))
	CALL ADD_2_ITMLST(4,CHP$_ACCESS,%LOC(ACCESS))
	CALL ADD_2_ITMLST(LEN(ACE),CHP$_MATCHEDACE,%LOC(ACE))
	CALL END_ITMLST(ACL_ITMLST)	! Get address of itemlist

	FLAGS = 0		! Default is no access

	ACCESS = ARM$M_READ	! Check if user has read access
	READ_ACCESS=SYS$CHECK_ACCESS(ACL$C_FILE,FILENAME,USERNAME,
     &		%VAL(ACL_ITMLST))

	IF (.NOT.SETPRV_PRIV().AND.ICHAR(ACE(:1)).NE.0) THEN
	   CALL SYS$FORMAT_ACL(ACE,,OUTPUT,,,,)
	   IF (INDEX(OUTPUT,'=*').NE.0.AND.
     &		INDEX(OUTPUT,'READ').EQ.0) READ_ACCESS = 0
	END IF

	ACCESS = ARM$M_WRITE	! Check if user has write access
	WRITE_ACCESS=SYS$CHECK_ACCESS(ACL$C_FILE,FILENAME,USERNAME,
     &		%VAL(ACL_ITMLST))

	IF (.NOT.SETPRV_PRIV().AND.ICHAR(ACE(:1)).NE.0) THEN
	   CALL SYS$FORMAT_ACL(ACE,,OUTPUT,,,,)
	   IF (INDEX(OUTPUT,'=*').NE.0.AND.
     &		INDEX(OUTPUT,'WRITE').EQ.0) WRITE_ACCESS = 0
	END IF

	RETURN
	END




	SUBROUTINE SHOWACL(FILENAME)
C
C  SUBROUTINE SHOWACL
C
C  FUNCTION: Shows users who are allowed to read private bulletin.
C
C  PARAMETERS:
C	FILENAME - Name of file to check.
C
	IMPLICIT INTEGER (A-Z)

	INCLUDE '($ACLDEF)'

	CHARACTER*(*) FILENAME

	CALL INIT_ITMLST	! Initialize item list
	CALL ADD_2_ITMLST(4,ACL$C_ACLLENGTH,%LOC(ACLLENGTH))
	CALL END_ITMLST(ACL_ITMLST)	! Get address of itemlist

	IER = SYS$CHANGE_ACL(,ACL$C_FILE,FILENAME,%VAL(ACL_ITMLST),,,)

	CALL LIB$GET_VM(ACLLENGTH+8,ACLSTR)
	CALL MAKE_CHAR(%VAL(ACLSTR),ACLLENGTH,ACLLENGTH)

	CALL READACL(FILENAME,%VAL(ACLSTR),ACLLENGTH)

	RETURN
	END



	SUBROUTINE FOLDER_FILE_ROUTINES

	IMPLICIT INTEGER (A-Z)

	CHARACTER*(*) KEY_NAME

	INCLUDE 'BULLFOLDER.INC'

	ENTRY WRITE_FOLDER_FILE(IER)

	DO WHILE (REC_LOCK(IER))
	   WRITE (7,IOSTAT=IER) FOLDER_COM
	END DO

	RETURN

	ENTRY REWRITE_FOLDER_FILE

	REWRITE (7) FOLDER_COM

	RETURN

	ENTRY REWRITE_FOLDER_FILE_TEMP

	REWRITE (7) FOLDER1_COM

	RETURN

	ENTRY READ_FOLDER_FILE(IER)

	DO WHILE (REC_LOCK(IER))
	   READ (7,IOSTAT=IER) FOLDER_COM
	END DO

	RETURN

	ENTRY READ_FOLDER_FILE_TEMP(IER)

	DO WHILE (REC_LOCK(IER))
	   READ (7,IOSTAT=IER) FOLDER1_COM
	END DO

	RETURN

	ENTRY READ_FOLDER_FILE_KEYNUM(KEY_NUMBER,IER)

	SAVE_FOLDER_NUMBER = FOLDER_NUMBER

	DO WHILE (REC_LOCK(IER))
	   READ (7,KEY=KEY_NUMBER,KEYID=1,IOSTAT=IER) FOLDER_COM
	END DO

	FOLDER_NUMBER = SAVE_FOLDER_NUMBER

	RETURN

	ENTRY READ_FOLDER_FILE_KEYNUM_TEMP(KEY_NUMBER,IER)

	DO WHILE (REC_LOCK(IER))
	   READ (7,KEY=KEY_NUMBER,KEYID=1,IOSTAT=IER) FOLDER1_COM
	END DO

	RETURN

	ENTRY READ_FOLDER_FILE_KEYNAME_TEMP(KEY_NAME,IER)

	DO WHILE (REC_LOCK(IER))
	   READ (7,KEY=KEY_NAME,KEYID=0,IOSTAT=IER) FOLDER1_COM
	END DO

	RETURN

	ENTRY READ_FOLDER_FILE_KEYNAME(KEY_NAME,IER)

	DO WHILE (REC_LOCK(IER))
	   READ (7,KEY=KEY_NAME,KEYID=0,IOSTAT=IER) FOLDER_COM
	END DO

	RETURN

	END


	SUBROUTINE USER_FILE_ROUTINES

	IMPLICIT INTEGER (A-Z)

	CHARACTER*(*) KEY_NAME

	INCLUDE 'BULLUSER.INC'

	CHARACTER*12 SAVE_USERNAME

	ENTRY READ_USER_FILE(IER)

	SAVE_USERNAME = USERNAME

	DO WHILE (REC_LOCK(IER))
	   READ (4,IOSTAT=IER) USER_ENTRY
	END DO

	TEMP_USER = USERNAME
	USERNAME = SAVE_USERNAME

	RETURN

	ENTRY READ_USER_FILE_KEYNAME(KEY_NAME,IER)

	SAVE_USERNAME = USERNAME

	DO WHILE (REC_LOCK(IER))
	   READ (4,KEY=KEY_NAME,IOSTAT=IER) USER_ENTRY
	END DO

	USERNAME = SAVE_USERNAME
	TEMP_USER = KEY_NAME

	RETURN

	ENTRY READ_USER_FILE_HEADER(IER)

	DO WHILE (REC_LOCK(IER))
	   READ (4,KEY='            ',IOSTAT=IER) USER_HEADER
	END DO

	RETURN

	ENTRY WRITE_USER_FILE_NEW(IER)

	SET_FLAG(1) = SET_FLAG_DEF(1)
	SET_FLAG(2) = SET_FLAG_DEF(2)
	BRIEF_FLAG(1) = BRIEF_FLAG_DEF(1)
	BRIEF_FLAG(2) = BRIEF_FLAG_DEF(2)
	NOTIFY_FLAG(1) = NOTIFY_FLAG_DEF(1)
	NOTIFY_FLAG(2) = NOTIFY_FLAG_DEF(2)

	ENTRY WRITE_USER_FILE(IER)

	DO WHILE (REC_LOCK(IER))
	   WRITE (4,IOSTAT=IER) USER_ENTRY
	END DO

	RETURN

	END





	SUBROUTINE SET_GENERIC(GENERIC)
C
C  SUBROUTINE SET_GENERIC
C
C  FUNCTION: Enables or disables "GENERIC" display, i.e. displaying
C	general bulletins continually for a certain amount of days.
C
	IMPLICIT INTEGER (A-Z)

	INCLUDE 'BULLUSER.INC'

	COMMON /BULLPAR/ BULL_PARAMETER,LEN_P
	CHARACTER*64 BULL_PARAMETER

	IF (.NOT.SETPRV_PRIV()) THEN
	   WRITE (6,'(
     &      '' ERROR: No privs to change GENERIC.'')')
	   RETURN
	END IF

	IER = CLI$GET_VALUE('USERNAME',TEMP_USER)

	CALL OPEN_FILE_SHARED(4)

	CALL READ_USER_FILE_KEYNAME(TEMP_USER,IER)

	IF (IER.EQ.0) THEN
	   IF (GENERIC) THEN
	      IF (CLI$PRESENT('DAYS')) THEN
	         IER = CLI$GET_VALUE('DAYS',BULL_PARAMETER)
	         CALL LIB$MOVC3(4,%REF(BULL_PARAMETER),NEW_FLAG(2))
	      ELSE
		 NEW_FLAG(2) = '   7'
	      END IF
	   ELSE
	      NEW_FLAG(2) = 0
	   END IF
	   REWRITE (4) TEMP_USER//USER_ENTRY(13:)
	ELSE
	   WRITE (6,'('' ERROR: Specified username not found.'')')
	END IF

	CALL CLOSE_FILE(4)

	RETURN
	END


	SUBROUTINE SET_LOGIN(LOGIN)
C
C  SUBROUTINE SET_LOGIN
C
C  FUNCTION: Enables or disables bulletin display at login.
C
	IMPLICIT INTEGER (A-Z)

	INCLUDE 'BULLUSER.INC'

	CHARACTER TODAY*23

	DIMENSION NOLOGIN_BTIM(2)

	CALL SYS$ASCTIM(,TODAY,,)		! Get the present time

	IF (.NOT.SETPRV_PRIV()) THEN
	   WRITE (6,'(
     &      '' ERROR: No privs to change LOGIN.'')')
	   RETURN
	END IF

	IER = CLI$GET_VALUE('USERNAME',TEMP_USER)

	CALL OPEN_FILE_SHARED(4)

	CALL READ_USER_FILE_KEYNAME(TEMP_USER,IER)

	CALL SYS_BINTIM('5-NOV-2956',NOLOGIN_BTIM)
	IF (IER.EQ.0) THEN
	   IF (LOGIN.AND.COMPARE_BTIM(LOGIN_BTIM,NOLOGIN_BTIM).EQ.0) THEN
	      CALL SYS_BINTIM(TODAY,LOGIN_BTIM)
	   ELSE IF (.NOT.LOGIN) THEN
	      LOGIN_BTIM(1) = NOLOGIN_BTIM(1)
	      LOGIN_BTIM(2) = NOLOGIN_BTIM(2)
	   END IF
	   REWRITE (4) TEMP_USER//USER_ENTRY(13:)
	ELSE
	   WRITE (6,'('' ERROR: Specified username not found.'')')
	END IF

	CALL CLOSE_FILE(4)

	RETURN
	END





	SUBROUTINE GET_UAF(USERNAME,USER,GROUP,ACCOUNT,FLAGS,IER)

	IMPLICIT INTEGER (A-Z)

	CHARACTER USERNAME*(*),ACCOUNT*(*)

	INCLUDE '($UAIDEF)'

	INTEGER*2 UIC(2)

	CALL INIT_ITMLST
	CALL ADD_2_ITMLST(4,UAI$_FLAGS,%LOC(FLAGS))
	CALL ADD_2_ITMLST(LEN(ACCOUNT),UAI$_ACCOUNT,%LOC(ACCOUNT))
	CALL ADD_2_ITMLST(4,UAI$_UIC,%LOC(UIC))
	CALL END_ITMLST(GETUAI_ITMLST)

	IER = SYS$GETUAI(,,USERNAME,%VAL(GETUAI_ITMLST),,,)

	USER = UIC(1)
	GROUP = UIC(2)

	RETURN
	END



	SUBROUTINE DCLEXH(EXIT_ROUTINE)

	IMPLICIT INTEGER (A-Z)

	INTEGER*4 EXBLK(4)

	EXBLK(2) = EXIT_ROUTINE
	EXBLK(3) = 1
	EXBLK(4) = %LOC(EXBLK(4))

	CALL SYS$DCLEXH(EXBLK(1))

	RETURN
	END




	SUBROUTINE FULL_DIR(INDEX_COUNT)
C
C	Add INDEX command to BULLETIN, display directories of ALL
C	folders. Added per request of a faculty member for his private
C	board. Changes to BULLETIN.FOR should be fairly obvious.
C
C	Brian Nelson, Brian@uoft02.bitnet (or .ccnet, node 8.2)
C
	IMPLICIT INTEGER (A-Z)

	INCLUDE 'BULLDIR.INC'
	INCLUDE 'BULLFILES.INC'
	INCLUDE 'BULLFOLDER.INC'
	INCLUDE 'BULLUSER.INC'

	COMMON /POINT/ BULL_POINT

	DATA FOLDER_Q1/0/

	BULL_POINT = 0

	IF (NUM_FOLDERS.GT.0.AND..NOT.CLI$PRESENT('RESTART')
     &		.AND.INDEX_COUNT.EQ.1) THEN
	   INDEX_COUNT = 2
	   DIR_COUNT = 0
	END IF

	IF (INDEX_COUNT.EQ.1) THEN
	  CALL INIT_QUEUE(FOLDER_Q1,FOLDER1_COM)

	  FOLDER_Q = FOLDER_Q1
	  CALL OPEN_FILE_SHARED(7)		 ! Get folder file

	  NUM_FOLDERS = 0
	  IER = 0
	  DO WHILE (IER.EQ.0)			! Copy all bulletins from file
	    CALL READ_FOLDER_FILE_TEMP(IER)
	    IF (IER.EQ.0) THEN
	      NUM_FOLDERS = NUM_FOLDERS + 1
	      CALL WRITE_QUEUE(%VAL(FOLDER_Q),FOLDER_Q,FOLDER1_COM)
	    END IF
	  END DO

	  CALL CLOSE_FILE(7)			 ! We don't need file anymore

	  FOLDER_Q = FOLDER_Q1			! Init queue pointer to header
	  WRITE (6,1000)
	  WRITE (6,1020)
	  DO J = 1,NUM_FOLDERS
	   CALL READ_QUEUE(%VAL(FOLDER_Q),FOLDER_Q,FOLDER1_COM)
	   WRITE (6,1030) FOLDER1(:15),F1_NBULL,
     &		FOLDER1_DESCRIP(:MIN(TRIM(FOLDER1_DESCRIP),60))
	  END DO
	  WRITE (6,1060)
	  FOLDER_Q = FOLDER_Q1			! Init queue pointer to header
	  INDEX_COUNT = 2
	  DIR_COUNT = 0
	  RETURN
	ELSE IF (INDEX_COUNT.EQ.2) THEN
	 IF (DIR_COUNT.EQ.0) THEN
	  F1_NBULL = 0
	  DO WHILE (NUM_FOLDERS.GT.0.AND.F1_NBULL.EQ.0)
	     NUM_FOLDERS = NUM_FOLDERS - 1
	     CALL READ_QUEUE(%VAL(FOLDER_Q),FOLDER_Q,FOLDER1_COM)
	     IF (F1_NBULL.GT.0) THEN
	      FOLDER_NUMBER = -1
	      CALL SELECT_FOLDER(.FALSE.,IER)
	      IF (.NOT.IER) F1_NBULL = 0
	     END IF
	  END DO

	  IF (F1_NBULL.EQ.0) THEN
	     WRITE (6,1050)
	     INDEX_COUNT = 0
	     RETURN
	  END IF
	 END IF
     
	 CALL DIRECTORY(DIR_COUNT)

	 IF (DIR_COUNT.GT.0) RETURN

	 IF (NUM_FOLDERS.GT.0) THEN
	    WRITE (6,1040)
	 ELSE
	    INDEX_COUNT = 0
	 END IF
	END IF

	RETURN

1000	FORMAT (' The following folders are present'/)
1020	FORMAT (' Name	       Count Description'/)
1030	FORMAT (1X,A15,I4,1X,A)
1040	FORMAT (' Type Return to continue to the next folder...')
1050	FORMAT (' End of folder search.')
1060	FORMAT (' Type Return to continue...')

	END