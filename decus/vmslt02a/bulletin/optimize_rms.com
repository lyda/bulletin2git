$ SET NOON
$ EXIT_STATUS = 1
$ IF P1 .NES. "" THEN GOTO BATCH
$!
$GET_FILE:
$ INQUIRE P1 "File to be optimized (^Y to quit)"
$!
$ FILENAME = P1
$ SPEC = F$SEARCH(FILENAME)
$!
$GOT_NAME_INTERACTIVE:
$ NAME = F$PARSE(FILENAME,,,"NAME")
$!
$ IF F$FILE_ATTRIBUTE(FILENAME,"ORG") .EQS. "IDX" THEN-
  GOTO INTERACTIVE_CHECK_ADDS
$ WRITE SYS$OUTPUT "File not indexed"
$ GOTO GET_FILE
$INTERACTIVE_CHECK_ADDS:
$ INQUIRE P2 "Number of records to add after initial load"
$ IF P2 .EQS. "" THEN P2 = 0
$!
$ IF P2 .GE. 0 THEN GOTO INTERACTIVE_CHECK_CONVERT
$ WRITE SYS$OUTPUT "Added records must be >= 0 "
$ GOTO GOT_NAME_INTERACTIVE
$!
$INTERACTIVE_CHECK_CONVERT:
$ INQUIRE P3 "Turn OFF Data and Key compression? (N)"
$ INQUIRE P4 "Turn OFF Index compression? (N)"
$!
$ GOTO ADD_OK
$!
$BATCH:
$GOT_NAME:
$ FILENAME = P1
$ SPEC = F$SEARCH(FILENAME)
$!
$ IF SPEC .NES. "" THEN GOTO FILE_EXISTS
$ WRITE SYS$OUTPUT "File does not exist"
$ EXIT_STATUS = %X18292
$ GOTO DONE
$!
$FILE_EXISTS:
$ NAME = F$PARSE(FILENAME,,,"NAME")
$ IF F$FILE_ATTRIBUTE(FILENAME,"ORG") .EQS. "IDX" THEN-
  GOTO TYPE_OK
$ WRITE SYS$OUTPUT "File not indexed"
$ EXIT_STATUS = 1000024
$ GOTO DONE
$!
$TYPE_OK:
$ IF P2 .EQS. "" THEN P2 = 0
$ IF P2 .GE. 0 THEN GOTO ADD_OK
$!
$ WRITE SYS$OUTPUT "Added records must be >= 0 "
$ EXIT_STATUS = %X38060
$ GOTO DONE
$!
$ADD_OK:
$ ADD_RECORDS = P2
$!
$ NUMBER_OF_KEYS == 'F$FILE_ATTRIBUTE(FILENAME,"NOK")
$ TURN_DATA_COMPRESSION_OFF = P3
$ TURN_INDEX_COMPRESSION_OFF = "Y"
$ FDL_NAME = F$PARSE(".FDL;0",SPEC)
$ TEMP_FILE = "''NAME'_TEMP_TEMP.COM"
$ OPEN/WRITE/ERROR=OPEN_ERROR OUT 'TEMP_FILE
$ WRITE OUT "$ DEFINE/USER SYS$COMMAND SYS$INPUT"
$ WRITE OUT "$ ANALYZE/RMS/FDL/OUT=''FDL_NAME' ''FILENAME'"
$ WRITE OUT "$ DEFINE/USER SYS$COMMAND SYS$INPUT"
$ WRITE OUT "$ DEFINE/USER EDF$$PLAYBACK_INPUT KLUDGE"
$ WRITE OUT "$ EDIT/FDL/SCRIPT=OPTIMIZE/ANALYZE=''FDL_NAME' ''FDL_NAME'"
$ WRITE OUT ""
$ WRITE OUT ""
$ WRITE OUT ""
$ WRITE OUT ""
$ WRITE OUT 'ADD_RECORDS
$ IF ADD_RECORDS .EQ. 0 THEN GOTO SKIP_NON_ZERO
$ WRITE OUT ""
$ WRITE OUT ""
$SKIP_NON_ZERO:
$ WRITE OUT ""
$ IF TURN_INDEX_COMPRESSION_OFF
$ THEN
$  WRITE OUT "IC"
$  WRITE OUT "NO"
$ ENDIF
$ IF TURN_DATA_COMPRESSION_OFF
$ THEN
$  WRITE OUT "RC"
$  WRITE OUT "NO"
$  WRITE OUT "KC"
$  WRITE OUT "NO"
$ ENDIF
$ WRITE OUT "FD"
$ WRITE OUT "Created from OPTIMIZE_RMS.COM, WITH SPACE/BUCKETSIZE for" +-
  " ''A DD_RECORDS' ADDED RECORDS"
$ WRITE OUT ""
$ WRITE OUT ""
$LOOP:
$ IF NUMBER_OF_KEYS .EQ. 1 THEN GOTO CLOSE_FILE
$ WRITE OUT ""
$ WRITE OUT ""
$ WRITE OUT ""
$ IF TURN_INDEX_COMPRESSION_OFF
$ THEN
$  WRITE OUT "IC"
$  WRITE OUT "NO"
$ ENDIF
$ IF TURN_DATA_COMPRESSION_OFF
$ THEN
$  WRITE OUT "KC"
$  WRITE OUT "NO"
$ ENDIF
$ WRITE OUT "FD"
$ WRITE OUT ""
$ WRITE OUT ""
$ NUMBER_OF_KEYS = 'NUMBER_OF_KEYS - 1
$ GOTO LOOP
$!
$CLOSE_FILE:
$ WRITE OUT "E"
$ CLOSE OUT
$!
$ @'TEMP_FILE
$ DELETE 'TEMP_FILE;*
$ WRITE SYS$OUTPUT ""
$ WRITE SYS$OUTPUT "Starting CONVERT of ''FILENAME'"
$ CONVERT /NOSORT /STAT /FDL='FDL_NAME 'FILENAME 'FILENAME
$ WRITE SYS$OUTPUT ""
$ GOTO DONE
$OPEN_ERROR:
$ WRITE SYS$OUTPUT "Unable to open ''TEMP_FILE'"
$DONE:
$ EXIT 'EXIT_STATUS
