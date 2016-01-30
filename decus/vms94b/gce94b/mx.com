9 From:	SMTP%"BULLETIN@PFC.MIT.EDU" 19-AUG-1994 17:30:47.43  To:	EVERHART CC:	 Subj:	MX.COM  + Date: Fri, 19 Aug 1994 17:26:24 -0400 (EDT)  From: BULLETIN@PFC.MIT.EDU To:   EVERHART@arisia.gce.com / Message-Id: <940819172624.21438991@PFC.MIT.EDU>  Subject: MX.COM   
 $set nover% $copy/log sys$input BUILD_MX_BULL.COM  $deck  $ save_verify = 'f$verify(0)'  $!B $!  Command file to build MX_BULL (MX SITE transport for BULLETIN) $! $ say := write sys$output % $ if f$trnlnm("BULL_SOURCE") .eqs. "" N $ then	say "BULL_SOURCE logical not defined; must point to BULL.OLB directory" $	exit $ endif  $ say "Compiling MX_BULL...."  $ cc mx_bull $ say "Linking MX_BULL...." @ $ link/notrace mx_bull,bull_source:BULL.OLB/LIB,sys$input/option SYS$SHARE:VAXCRTL.EXE/SHARE & $ say "Build of MX_BULL.EXE completed"! $ exit f$verify(save_verify).or.1  $eod   $copy/log sys$input MX_BULL.C  $deck  #module MX_BULL "01-001" /*  *  *  Program:	MX_BULL  *  *  Author:	Hunter Goatley  *		Academic Computing, STH 226   *		Western Kentucky University   *		Bowling Green, KY 42101   *		goathunter@wkuvx1.bitnet  *		502-745-5251  *  *  Date:	March 8, 1991   *  *  Functional description:   *C  *	This program serves as an MX SITE transport to transfer incoming !  *	mail files to UALR's BULLETIN.   *F  *	The MX_SITE delivery agent takes messages routed to a SITE path andG  *	feeds them into a subprocess that executes a command procedure named E  *	MX_EXE:SITE_DELIVER.COM.  There are three parameters passed to the   *	the command procedure:   *<  *		P1	- The name of a temporary file containing the message0  *			  text, including all of the RFC822 headers1  *			  (corresponding to the DATA part of an SMTP   *			  transaction).:  *		P2	- The name of a temporary file containing a list of6  *			  a messages recipients, which corresponds to the0  *			  RCPT_TO addresses of an SMTP transaction.9  *		P3	- The RFC822 address of the sender of the message, 7  *			  which corresponds to the MAIL FROM address of an   *			  SMTP transaction.  *B  *	This program expects the same parameters, except that the thirdF  *	parameter is optional.  If the third parameter is omitted, BULLETINB  *	will scan the RFC822 headers in the message for a "From:" line.C  *	If the third parameter is specified, it is expected to be a file F  *	specification.  It is assumed that SITE_DELIVER.COM has written the  *	address to this file.  *?  *	The logical MX_BULLETIN_POSTMASTER can be defined as a local C  *	username to receive error notices.  If BULLETIN returns an error @  *	while trying to add a message, and the MX_BULLETIN_POSTMASTERC  *	is defined as a valid local username, the message will be mailed %  *	to that user for further handling.   *H  *	MX_BULLETIN_POSTMASTER must be defined system-wide in executive mode:  *7  *		$ DEFINE/SYS/EXEC MX_BULLETIN_POSTMASTER GOATHUNTER   *  *  Modification history:   *,  *	01-001		Hunter Goatley		14-MAR-1991 14:41>  *		Added scan_for_from_line, which scans the message's RFC822;  *		headers for the "From:" line.  General cleanup on a few >  *		routines.  MX_BULL now provides an RESPOND-able address in  *		BULLETIN.   *,  *	01-000		Hunter Goatley		 8-MAR-1991 07:20  *		Genesis.  *  */   3 /*  Include all needed structures and constants  */    #include descrip #include lib$routines  #include libdef  #include lnmdef  #include maildef #include rms #include ssdef #include str$routines  #include string   9 /* Declare the external BULLETIN routines that we call */   % unsigned long int INIT_MESSAGE_ADD(); ' unsigned long int WRITE_MESSAGE_LINE(); ' unsigned long int FINISH_MESSAGE_ADD();   7 /* Define some macros to make things a little easier */   2 #define rms_get(rab) ((rms_status = SYS$GET(rab)))6 #define err_exit(stat) {traceerr(stat); return(stat);}? #define vms_errchk2() if(!(vms_status&1)) err_exit(vms_status); : #define vms_errchk(func) {vms_status=func; vms_errchk2();}  = #define tracemsg(msg) if (trace) printf("MX_BULL: %s\n",msg); O #define traceerr(msg) if (trace) printf("MX_BULL: Error status %%X%08x\n",msg);   6 /* Define some global variables to make things easy */  0 struct FAB msgfab;				/* FAB for message text */0 struct RAB msgrab;				/* RAB for message text */4 struct FAB rcptfab;				/* FAB for recipients file */4 struct RAB rcptrab;				/* RAB for recipients file */. struct FAB fromfab;				/* FAB for FROM file */. struct RAB fromrab;				/* RAB for FROM file */2 char msgbuf[512];				/* Input buffer for msgrab */4 char rcptbuf[512];				/* Input buffer for rcptrab */4 char frombuf[512];				/* Input buffer for frombuf */ short trace;9 unsigned long int rms_status;			/* Status of RMS calls */ ; unsigned long int vms_status;			/* Status of other calls */   1 static $DESCRIPTOR(lnm_table,"LNM$SYSTEM_TABLE");   6 #define itmlstend {0,0,0,0}			/* An empty item list */5 typedef struct itmlst				/* An item list structure */  {    short buffer_length;   short item_code;   long buffer_address;   long return_length_address; 	 } ITMLST;    ITMLST   nulllist[] = {itmlstend};    ITMLST5   address_itmlst[] = {				/* MAIL$SEND_ADD_ADDRESS */   	{0, MAIL$_SEND_USERNAME, 0, 0}, 	itmlstend},7   bodypart_itmlst[] = {				/* MAIL$SEND_ADD_BODYPART */  	{0, MAIL$_SEND_RECORD, 0, 0}, 	itmlstend},8   attribute_itmlst[] = {			/* MAIL$SEND_ADD_ATTRIBUTE */ 	{0, MAIL$_SEND_TO_LINE, 0, 0}, ! 	{0, MAIL$_SEND_FROM_LINE, 0, 0},  	{0, MAIL$_SEND_SUBJECT, 0, 0},  	itmlstend}    ;    ITMLST0   trnlnm_itmlst[] = {				/* $TRNLNM item list */ 	{0, LNM$_STRING, 0, 0}, 	itmlstend}    ;      /*  *  *  Function:	open_file_rms   *  *  Functional description:   *F  *	This routine opens a sequential text file in VMS "normal text" file)  *	format.  It uses RMS to open the file.   *  *  Inputs:   *#  *	infab	- Address of the input FAB #  *	inrab	- Address of the input RAB %  *	buff	- Address of the input buffer 5  *	filename - Address of the filename to open (ASCIZ)   *  *  Outputs:  *.  *	fab and rab are modified if file is opened.  *  *  Returns:  *  *	RMS status   *  */  unsigned long int P open_file_rms (struct FAB *infab, struct RAB *inrab, char *buff, char *filename) { !     unsigned long int rms_status;   3     *infab = cc$rms_fab;			/* Initialize the FAB */ 3     *inrab = cc$rms_rab;			/* Initialize the RAB */ B     infab->fab$b_fns = strlen(filename);	/* Set filename length */<     infab->fab$l_fna = filename;		/* Set filename address */8     infab->fab$b_fac = FAB$M_GET;		/* GET access only */>     infab->fab$b_shr = FAB$M_SHRGET+FAB$M_SHRPUT+FAB$M_SHRUPD;:     inrab->rab$l_fab = infab;			/* Let RAB point to FAB */?     inrab->rab$b_rac = RAB$C_SEQ;		/* Sequential file access */ <     inrab->rab$w_usz = 512;			/* Record size is 512 bytes */8     inrab->rab$l_ubf = buff;			/* Read to this buffer */  7     rms_status = SYS$OPEN (infab);		/* Open the file */ =     if (!(rms_status & 1))			/* If an error occurs, return */ * 	return (rms_status);			/* ... a status */<     rms_status = SYS$CONNECT (inrab);		/* Connect the RAB */6     return (rms_status);			/* Return the RMS status */ }    /*  *  *  Function:	init_sdesc  *  *  Functional description:   *)  *	Initialize a static string descriptor.   *  *  Inputs:   *2  *	sdesc	- Address of the descriptor to initialize'  *		  (of type struct dsc$descriptor_s) F  *	string	- Address of null-terminated string the descriptor describes  *  *  Outputs:  *4  *	sdesc	- Descriptor passed as sdesc is initialized  *  */  void9 init_sdesc (struct dsc$descriptor_s *sdesc, char *string)  { >     sdesc->dsc$w_length = strlen(string);	/* Set the length	*/<     sdesc->dsc$b_dtype = DSC$K_DTYPE_T;		/* Type is text		*/>     sdesc->dsc$b_class = DSC$K_CLASS_S;		/* Class is static	*/=     sdesc->dsc$a_pointer = string;		/* Point to the string	*/  }    /*  *$  *  Function:	add_to_bulletin_folder  *  *  Functional description:   *>  *	Adds a message to a BULLETIN folder by calling the external>  *	BULLETIN routines INIT_MESSAGE_ADD, WRITE_MESSAGE_LINE, and  *	FINISH_MESSAGE_ADD.  *C  *	The following constants are (may be) passed to INIT_MESSAGE_ADD:   *<  *		Subject = "" 	Causes BULLETIN to scan RFC822 headers for"  *				a "Subject:" or "Subj:" line;  *		From = "MX%"	Causes BULLETIN to scan RFC822 headers forM#  *				a "Reply-to:" or "From:" line   *  *  Inputs:0  *.  *	filerab	- Address of the message file's RABE  *	folder	- Address of a string descriptor for the name of the folderr@  *	from	- Address of a string descriptor for the "From:" address  *  *  Outputs:  *  *	None.  *  *  Returns:  *=  *	unsigned long int - RMS status of call to INIT_MESSAGE_ADDS  *  */i unsigned long intsE add_to_bulletin_folder(struct RAB *filerab, void *folder, void *from)U {.E     unsigned long int bull_status;	/* Status from INIT_MESSAGE_ADD */lL     struct dsc$descriptor_s msg_line;	/* Descriptor for a line of the msg */7     static $DESCRIPTOR(subject,"");	/* Subject is "" */v  @     /* Call BULLETIN routine to initialize adding the message */  <     INIT_MESSAGE_ADD (folder, from, &subject, &bull_status);  -     if (!(bull_status & 1)){					/* Error? */  	return(bull_status);U     }t  I     /*	Loop reading message lines until end-of-file.  For each line read,2C 	create a string descriptor for it and call the BULLETIN routine to* 	add the line. */e  ?     while (rms_get(filerab) != RMS$_EOF){		/* Loop until EOF */oB 	filerab->rab$l_rbf[filerab->rab$w_rsz] = 0;	/* End byte = NULL */A 	init_sdesc(&msg_line, filerab->rab$l_rbf);	/* Now build desc. */e8 	WRITE_MESSAGE_LINE (&msg_line);			/* Add to BULLETIN */     }e  @     FINISH_MESSAGE_ADD();		/* Call BULLETIN routine to finish */  (     tracemsg("Message added to folder");8     return(SS$_NORMAL);			/* Return success to caller */ }2   e /*  *   *  Function:	scan_for_from_line  *  *  Functional description:.  *G  *	The routine scans the message's RFC822 headers for the "From:" line.e9  *	It parses out the address by extracting the <address>.e  *G  *	This routine was necessary because letting BULLETIN find the "From:"eH  *	line was resulting in a non-RESPONDable address for MX.  For example,  *	BULLETIN was creating:*  *=  *		From: MX%"Hunter Goatley, WKU <goathunter@WKUVX1.BITNET>"*  *  *	but MX needsl  *)  *		From: MX%"<goathunter@WKUVX1.BITNET>"   *  *  Inputs:R  *.  *	filerab	- Address of the message file's RAB  *  *  Outputs:  *J  *	final_from - Address of a character buffer to receive the final address  *  *  Returns:  *4  *	unsigned long int - binary success/failure status  *  *  Side effects:P  *C  *	The message file is rewound so that subsequent GETs start at thes  *	beginning of the message.  *  */i unsigned long intm9 scan_for_from_line(struct RAB *filerab, char *final_from)v {dE     unsigned long int scan_status;	/* Status from INIT_MESSAGE_ADD */eL     struct dsc$descriptor_s msg_line;	/* Descriptor for a line of the msg */@     char whole_from_line[512];		/* The assembled "From:" line */9     char *filebuffer;			/* Pointer to the input buffer */n'     int i, j, x;			/* Work variables */   4     scan_status = SS$_NORMAL;			/* Assume success */=     whole_from_line[0] = '\0';			/* Initialize work buffer */	  G     /*	Loop reading message lines until end-of-file or first null line, G 	which should signal the end of the RFC822 header.  For each line read, 0 	check to see if we've located the "From:" line.     */  <     filebuffer = filerab->rab$l_ubf;			/* Init buffer ptr */B     while ((rms_get(filerab) != RMS$_EOF) &&		/* Loop until EOF */; 	   ((x = filerab->rab$w_rsz) != 0)){		/* or null record */ - 	filebuffer[x] = '\0';				/* Set NULL byte */lA 	if (strncmp(filebuffer,"From:",5)==0){		/* Is it the "From:"? */)   	   /* Found "From:" line */: 	   tracemsg("Found \042From:\042 line in RFC822 header");@ 	   strcpy(whole_from_line,filebuffer);		/* Copy to work buff */  A 	   /* The "From:" line may actually be split over several lines._C 	      In such cases, the remaining lines are indented by 6 spaces.cB 	      To handle this, loop reading records until one is read thatA 	      doesn't begin with a blank.  As each record is read, it is(B 	      trimmed and tacked on to whole_from_line, so we end up with1 	      the entire "From:" line in one buffer.  */u  D 	   while((rms_get(filerab) != RMS$_EOF) &&	/* Read rest of From: */+ 		 (filebuffer[0] == ' ')){		/* ... line */	E 	      for (i = 0; filebuffer[i] == ' '; ++i);	/* Step over blanks */iC 	      strcat(whole_from_line,&filebuffer[i]);	/* Tack it on end */R 	   }r  A 	   /* Now have the whole "From:" line in whole_from_line.  Sincef; 	      the real address is enclosed in "<>", look for it bya@ 	      searching for the last "<" and reading up to the ">".  */  : 	   i = strrchr(whole_from_line,'<');		/* Find last "<" */' 	   if (i != 0){					/* Found it.... */S* 		j = strchr(i,'>');			/* Find last ">" */- 	        j = j-i+1;				/* Calc addr length */t 	   } 	 	   else{	9 		j = strlen(whole_from_line)-6;		/* Don't count From: */e3 		i = &whole_from_line + 6;		/* in string length */h 	   }m( 	   if (j < 0){					/* If neg., error */4 		tracemsg("Error - unable to locate from address");3 		strcpy(final_from,"");			/* Return null string */	+ 		scan_status = 0;			/* Set error status */N 	   }A
 	   else {6 		tracemsg("Found sender's address in RFC822 header");2 		strncpy(final_from, i, j);		/* Copy to caller */ 	   }	 	}     }t  @     SYS$REWIND(filerab);		/* Rewind the file to the beginning */8     return(scan_status);		/* Return success to caller */ }S   U /*  *#  *  Function:	forward_to_postmaster   *  *  Functional description:N  *E  *	If an error occurs trying to write a message to a BULLETIN folder, =  *	this routine is called to forward the message to the local   *	postmaster.  *  *  Inputs:n  *.  *	filerab	- Address of the message file's RABE  *	folder	- Address of a string descriptor for the name of the foldere@  *	from	- Address of a string descriptor for the "From:" addressB  *	status	- Address of longword containing the BULLETIN error code  *  *  Outputs:  *  *	None.  *  *  Returns:  *@  *	unsigned long int - binary status of call to INIT_MESSAGE_ADD  *  *  Side effects:i  *G  *	The message file is rewound so that subsequent calls to this routinefI  *	can be made (in case the message is to be written to several folders).c  *  */; unsigned long inteP forward_to_postmaster(struct RAB *filerab, void *folder, void *from, int status) {=L     struct dsc$descriptor_s msg_line;	/* Descriptor for a line of the msg */$     struct dsc$descriptor_s subject;     char subject_buf[256];/     char postmaster[256];   int postmaster_len;M3     char status_msg_buf[256];   int status_msg_len;f'     struct dsc$descriptor_s status_msg; H     static $DESCRIPTOR(faostr,"Failed BULLETIN message for folder !AS");>     static $DESCRIPTOR(MXBULL,"MX->SITE (BULLETIN delivery)");@     static $DESCRIPTOR(postmaster_lnm,"MX_BULLETIN_POSTMASTER");)     int send_context = 0;  int x;  int y;   !     static char *error_msgs[] = {rJ 	{"Error delivering message to BULLETIN folder.  BULLETIN error status:"}, 	{""}, 	{""},$ 	{"Original message text follows:"},7 	{"--------------------------------------------------"}      };  )     trnlnm_itmlst[0].buffer_length = 255;i2     trnlnm_itmlst[0].buffer_address = &postmaster;=     trnlnm_itmlst[0].return_length_address = &postmaster_len;   B     SYS$TRNLNM( 0, &lnm_table, &postmaster_lnm, 0, trnlnm_itmlst);>     if (postmaster_len == 0)		/* If logical is not defined, */6 	return(SS$_NORMAL);		/* then pretend it worked     */  ;     tracemsg("Forwarding message to local postmaster....");c     subject.dsc$w_length = 255;g)     subject.dsc$a_pointer = &subject_buf;rJ     SYS$FAO(&faostr, &subject, &subject, folder);	/* Format the subject */  C     address_itmlst[0].buffer_length = postmaster_len;		   /* To: */iA     address_itmlst[0].buffer_address = &postmaster;		   /* To: */ E     attribute_itmlst[0].buffer_length = postmaster_len;		   /* To: */nC     attribute_itmlst[0].buffer_address = &postmaster;		   /* To: */nK     attribute_itmlst[1].buffer_length = MXBULL.dsc$w_length;	   /* From: */dM     attribute_itmlst[1].buffer_address = MXBULL.dsc$a_pointer;	   /* From: */ N     attribute_itmlst[2].buffer_length = subject.dsc$w_length;	   /* Subject:*/P     attribute_itmlst[2].buffer_address = subject.dsc$a_pointer;	   /* Subject:*/  E     vms_errchk(mail$send_begin(&send_context, &nulllist, &nulllist));sD     vms_errchk(mail$send_add_address(&send_context, &address_itmlst, 			&nulllist)); H     vms_errchk(mail$send_add_attribute(&send_context, &attribute_itmlst, 			&nulllist));r       for (x = 0; x < 5; x++){: 	bodypart_itmlst[0].buffer_length = strlen(error_msgs[x]);3 	bodypart_itmlst[0].buffer_address = error_msgs[x];i1 	vms_errchk(mail$send_add_bodypart(&send_context,f  		&bodypart_itmlst, &nulllist)); 	if (x == 1){n! 	  status_msg.dsc$w_length = 256;f* 	  status_msg.dsc$b_dtype = DSC$K_DTYPE_T;* 	  status_msg.dsc$b_class = DSC$K_CLASS_S;. 	  status_msg.dsc$a_pointer = &status_msg_buf;< 	  y = SYS$GETMSG (status, &status_msg, &status_msg, 15, 0); 	  if (!(y & 1))= 	     sprintf(status_msg_buf,"Error code is %%X%08x",status);b 	  elses5 	     status_msg_buf[status_msg.dsc$w_length] = '\0';r= 	  bodypart_itmlst[0].buffer_length = strlen(status_msg_buf);e7 	  bodypart_itmlst[0].buffer_address = &status_msg_buf;iD 	  vms_errchk(mail$send_add_bodypart(&send_context,&bodypart_itmlst, 		&nulllist)); 	}     }f  ?     while (rms_get(filerab) != RMS$_EOF){		/* Loop until EOF */i7 	bodypart_itmlst[0].buffer_length = filerab->rab$w_rsz;(8 	bodypart_itmlst[0].buffer_address = filerab->rab$l_rbf;1 	vms_errchk(mail$send_add_bodypart(&send_context,   		&bodypart_itmlst, &nulllist));     }/  G     vms_errchk(mail$send_message(&send_context, &nulllist, &nulllist));eC     vms_errchk(mail$send_end(&send_context, &nulllist, &nulllist));   4     tracemsg("Message forwarded to postmaster...."); }i   d /*  *  *  Function:	log_accounting  *  *  Functional description:   *@  *	This routine will write an accounting record for the message.  *  *  Inputs:T  *E  *	folder	- Address of a string descriptor for the name of the foldern@  *	from	- Address of a string descriptor for the "From:" addressB  *	status	- Address of longword containing the BULLETIN error code  *  *  Outputs:  *  *	None.  *  *  Returns:  *!  *	unsigned long int - RMS statusB  *  */  unsigned long int*9 log_accounting(void *folder, void *from, int bull_status)u {t     struct FAB accfab;     struct RAB accrab;>     static $DESCRIPTOR(MX_BULL_ACCNTNG,"MX_BULLETIN_ACCNTNG");     static $DESCRIPTOR(faostr,F 	"!%D MX_BULL: FOLDER=\042!AS\042, ORIGIN=\042!AS\042, STATUS=%X!XL");     char outbufbuf[256];H     struct dsc$descriptor_s outbuf = {256, DSC$K_DTYPE_T, DSC$K_CLASS_S, 		 &outbufbuf};i       int status;r.     static char bullacc[] = "MX_BULLETIN_ACC";2     static char bullaccdef[] = "MX_SITE_DIR:.DAT";  @     status = SYS$TRNLNM( 0, &lnm_table, &MX_BULL_ACCNTNG, 0, 0);     if (!(status & 1)) 	return(SS$_NORMAL);  E     tracemsg("Writing accounting information to accounting log....");n     accfab = cc$rms_fab;     accrab = cc$rms_rab;B     accfab.fab$b_fns = strlen(bullacc);		/* Set filename length */<     accfab.fab$l_fna = &bullacc;		/* Set filename address */D     accfab.fab$b_dns = strlen(bullaccdef);	/* Set filename length */?     accfab.fab$l_dna = &bullaccdef;		/* Set filename address */n8     accfab.fab$b_fac = FAB$M_PUT;		/* PUT access only */>     accfab.fab$b_shr = FAB$M_SHRGET+FAB$M_SHRPUT+FAB$M_SHRUPD;@     accfab.fab$b_rfm = FAB$C_VAR;		/* Variable length records */9     accfab.fab$b_rat = FAB$M_CR;		/* Normal "text" rat */l<     accrab.rab$l_fab = &accfab;			/* Let RAB point to FAB */?     accrab.rab$b_rac = RAB$C_SEQ;		/* Sequential file access */)  <     status = SYS$OPEN (&accfab);		/* Try to open the file */%     if (status & 1)				/* Success? */y0 	accrab.rab$l_rop = RAB$M_EOF;		/* Set to EOF */+     else					/* Couldn't open, so create */b4 	status = SYS$CREATE (&accfab);		/* ... a new one */1     if (status & 1){				/* If either was OK... */ 7 	status = SYS$CONNECT (&accrab);		/* Connect the RAB */h6 	if (status == RMS$_EOF)			/* RMS$_EOF status is OK */4 	   status = RMS$_NORMAL;		/* Change it to NORMAL */2 	if (!(status & 1)){			/* If any error occurred *// 	   tracemsg("Unable to open accounting file");t 	   traceerr(status);&/ 	   SYS$CLOSE (&accfab);			/* Close the file */'0 	   return(status);			/* And return the error */ 	}     }      else 	return(status);  E     SYS$FAO(&faostr, &outbuf, &outbuf, 0, folder, from, bull_status);R+     accrab.rab$w_rsz = outbuf.dsc$w_length; ,     accrab.rab$l_rbf = outbuf.dsc$a_pointer;     SYS$PUT (&accrab);     SYS$CLOSE (&accfab); }  s /*  * f  *  Main routine  *  */  main(int argc, char *argv[]) {rF   struct dsc$descriptor_s folder;	/* Descriptor for the folder name */F   struct dsc$descriptor_s from_user;	/* Descriptor for "From:" line */4   static $DESCRIPTOR(MX_SITE_DEBUG,"MX_SITE_DEBUG");  <   char *from_line;			/* Pointer to dynamic "From:" buffer */>   char *folder_name;			/* Pointer to folder name in rcptbuf */2   char *atsign;				/* Pointer to "@" in rcptbuf */    int  x;				/* Work variable */I   unsigned long int bull_status;	/* Status from add_to_bulletin_folder */   /   --argc;				/* Don't count the program name */ F   if ((argc != 2) && (argc != 3)) {	/* If too many or too few args, */=     exit(LIB$_WRONUMARG);		/* ...  exit with error status  */Y   }I  @   vms_status = SYS$TRNLNM( 0, &lnm_table, &MX_SITE_DEBUG, 0, 0);   if (vms_status & 1)u     trace = 1;   else     trace = 0;     /*  Open all input files  */  '   tracemsg("Opening message file....");IA   vms_errchk(open_file_rms (&msgfab, &msgrab, &msgbuf, argv[1])); *   tracemsg("Opening recipients file....");D   vms_errchk(open_file_rms (&rcptfab, &rcptrab, &rcptbuf, argv[2]));     if (argc == 2){g>      tracemsg("Using sender address from RFC822 headers....");+      scan_for_from_line(&msgrab, &frombuf);s   }    else {1      tracemsg("Opening sender address file....");nG      vms_errchk(open_file_rms (&fromfab, &fromrab, &frombuf, argv[3]));   6      tracemsg("Reading sender address from file....");2      rms_get(&fromrab);			/* Read the from line */<      if (!(rms_status & 1))		/* Exit if an error occurred */ 	err_exit(rms_status);  P      /* Set the end of the record read, then initialize the descriptor for it */$      frombuf[fromrab.rab$w_rsz] = 0;        SYS$CLOSE(&fromfab);l)   }						/* End of "if (argc == 2)"... */t  2   /* frombuf now has the sender's address in it */     if (strlen(frombuf) == 0) {r8 	tracemsg("Unable to find sender's address, using MX%"); 	init_sdesc(&from_user, "MX%");n   }    else{a  7      /* Now add the MX% prefix and the double quotes */sK      from_line = malloc(4 + strlen(frombuf) + 1 + 1);	/* Allocate memory */e  E      /* Make the string repliable through MX by adding MX%"" to it */i!      strcpy(from_line,"MX%\042");s      strcat(from_line,frombuf);E      strcat(from_line,"\042");      if (trace) 8 	printf("MX_BULL: Sender's address is %s\n", from_line);I      init_sdesc (&from_user, from_line);	/* Create a string descriptor */O   }a   /*H     Read through all the recipients, writing the message to all BULLETINB     folders (identified by checking for @BULLETIN in the address).   */.   rms_get(&rcptrab);				/* Read a recipient */6   while ((rms_status & 1) & (rms_status != RMS$_EOF)){1      tracemsg("Looking for BULLETIN folder....");t<      folder_name = &rcptbuf;			/* Point to receipt buffer */?      if (folder_name[0] == '<'){		/* If line begins with "<" */ 0 	++folder_name;				/*  bump over it and check */4 	atsign = strchr(rcptbuf,'@');		/*  for a "@"		   *// 	if (atsign != 0){			/* If "@" was found,	   */ B 	  if (strncmp(atsign,"@BULLETIN",9)==0){/* Is it @BULLETIN?	   */= 	    x = atsign - folder_name;		/* Length of folder name   */ 8 	    folder_name[x] = 0;			/* Terminate folder name   */E 	    init_sdesc (&folder, folder_name);	/* Initialize descriptor   */r@ 	    str$upcase(&folder, &folder);	/* Convert to uppercase    */ 	    if (trace)T; 		printf("MX_BULL: Found BULLETIN folder \042%s\042....\n",l 			folder_name);7 	    tracemsg("Adding message to BULLETIN folder....");$I 	    bull_status = add_to_bulletin_folder (&msgrab, &folder, &from_user);. 	    if (!(bull_status & 1)){  		 traceerr(bull_status);fA 		 vms_errchk(forward_to_postmaster(&msgrab, &folder, &from_user,c 				bull_status)); 	    }6 	    log_accounting(&folder, &from_user, bull_status);? 	    SYS$REWIND(&msgrab);	/* Rewind the file for next folder */    	  } 	}       }d3       rms_get(&rcptrab);		/* Read next recipient */&   }i       /* Close the RMS files */x  +   SYS$CLOSE(&msgfab);  SYS$CLOSE(&rcptfab);n  )   tracemsg("BULLETIN message processed");a0   exit(SS$_NORMAL);		/* Always return success */   }y $eod e $copy/log sys$input MX_BULL.TXT  $decks+                                     MX_BULLg1                              An MX SITE transport_.                                 March 14, 1991  L MX_BULL is a transport between MX and BULLETIN, a VMS bulletin board programL by Mark London at MIT.  It is designed to be called as an MX SITE transport,N letting MX write messages into BULLETIN folders as they are processed, instead: of routing the messages to MAIL.MAI files for each folder.  5 The following files make up the MX_BULL distribution:e  <    BUILD_MX_BULL.COM		Command procedure to build MX_BULL.EXE,    MX_BULL.C			VAX C source code for MX_BULL    MX_BULL.TXT			This file8    MX_BULL_SITE_DELIVER.COM	SITE_DELIVER.COM for MX_BULL   The current version is 01-001.     WHAT IS BULLETIN?p -----------------rJ BULLETIN is a VMS bulletin board written by Mark London at MIT that allowsJ multiple users to access a common message base.  Messages are divided intoL folders, which work much like VMS Mail folders.  Using MX_BULL, messages canJ be routed from Internet/Bitnet mailing lists directly to BULLETIN folders,L allowing all (or some) users on a system to access the mailing lists withoutF individual subscriptions.  This can cut down on the number of incomingM Bitnet/Internet mail messages significantly, since only one copy of a messagee need be sent to a site.t  K BULLETIN can be found on a number of the DECUS VAX SIG tapes, including the*G Fall 1990 tapes.  It can also be retrieved by sending a mail message to H BULLETIN@NERUS.PFC.MIT.EDU.  The body of the message must contain one of the following commands:d  1         SEND ALL        Sends all bulletin files.i1         SEND filename   Sends the specified file.t=         BUGS            Sends a list of the latest bug fixes.L>         HELP or INFO    Sends a brief description of BULLETIN.     BUILDING MX_BULL.EXE --------------------O MX_BULL is written in VAX C and can be compiled by executing BUILD_MX_BULL.COM.C  G MX_BULL must be linked with the BULLETIN object library, BULL.OLB.  ThecK build procedure for MX_BULL expects the logical BULL_SOURCE to point to the_G BULLETIN library.  You must define this logical (or edit the .COM file), before building MX_BULL.     INSTALLING MX_BULL ------------------0 To install MX_BULL, perform the following steps:  @ 1.  Using MCP, define a path named BULLETIN as a SITE transport:  ! 	MCP> DEFINE PATH "BULLETIN" SITE   L 2.  Using MCP, define a rewrite rule early in the list (this should actually;     be done using CONFIG.MCP so that the order is correct):l  E 	MCP> DEFINE REWRITE_RULE "<{folder}@BULLETIN>" "<{folder}@BULLETIN>"n  C 3.  If you don't have a SITE transport already defined, simply copyf8     MX_BULL_SITE_DELIVER.COM to MX_EXE:SITE_DELIVER.COM.  M     If you do have a SITE transport defined, you'll need to merge the MX_BULL=4     stuff into the existing MX_EXE:SITE_DELIVER.COM.  H 4.  Reset the MX routers by using MCP RESET/ALL, or shutting down MX and     restarting it.  K Once these steps have been completed, MX_BULL is set up to begin delivering  messages to BULLETIN./     ROUTING MESSAGES TO BULLETIN ----------------------------= Messages are routed to BULLETIN folders by addressing mail toRG MX%"folder@BULLETIN", where "folder" is the name of the target BULLETINrJ folder.  For example, the following commands would send a message from VMS: Mail to the BULLETIN folder GENERAL (on the local system):   	$ MAIL_ 	MAIL> SENDh 	To:     MX%"GENERAL@BULLETIN" 	Subj:   This is a test....o 	.....  K The message is sent to the MX router, which in turn sends it to the MX SITE ; agent, since the @BULLETIN path was defined as a SITE path.a  I To facilitate the automatic delivery of messages to BULLETIN folders, you D should set up forwarding addresses for each of the BULLETIN folders:  9 	MAIL> SET FORWARD/USER=GENERAL MX%"""GENERAL@BULLETIN"""b9 	MAIL> SET FORWARD/USER=MX-LIST MX%"""MX-LIST@BULLETIN"""   G Mail addressed to GENERAL or MX-LIST will automatically be forwarded tot BULLETIN via MX_BULL.r  N To subscribe to a Bitnet/Internet mailing list and have the messages deliveredL to BULLETIN, use MX's MLFAKE to send a subscription request on behalf of the< BULLETIN folder.  For example, the user to specify would be:   	MLFAKE/USER=MX-LIST ...."  K (Alternatively, you could create a dummy account named MX-LIST (or whateverhM the list name is) that exists only long enough to send the request via MAIL.)/  N Once added to the lists, incoming mail addressed to MX-LIST will get forwardedN to MX%"MX-LIST@BULLETIN", which will invoke MX_BULL.  For example, an incoming: message to my local BULLETIN folder would be addressed to:   	MX-LIST@WKUVX1.bitnet  N Since I have MX-LIST forwarded to MX%"MX-LIST@BULLETIN", the message is routed to the BULLETIN folder.s  J To try to illustrate the process, assume the node is WKUVX1.bitnet.  We'veO subscribed a fake local user, INFO-VAX, to the MX mailing list; mail forwardingaM has been set up for INFO-VAX to send it to MX%"INFO-VAX@BULLETIN".  When mail M arrives addressed to INFO-VAX@WKUVX1.BITNET, the MX Router passes the messagecA to the Local agent, which discovers that the mail is forwarded to.K MX%"INFO-VAX@BULLETIN".  The message is then sent back to the Router, whicheJ finds that BULLETIN is defined as a SITE path, so the message is passed to& MX->SITE, which in turn calls MX_BULL.      MX_BULL ACCOUNTING AND DEBUGGING  --------------------------------J MX_BULL accounting is enabled with the system logical MX_BULLETIN_ACCNTNG:  + 	$ DEFINE/SYS/EXEC MX_BULLETIN_ACCNTNG TRUE   G This will cause MX_BULL to create MX_SITE_DIR:MX_BULLETIN_ACC.DAT.  TherL logical MX_BULLETIN_ACC can be defined system-wide to change the name of the file:/  D 	$ DEFINE/SYS/EXEC MX_BULLETIN_ACC LOCALDISK:[DIR]MX_BULL.ACCOUNTING  E To generate debugging logs in MX_SITE_DIR:, define the system logicaln MX_SITE_DEBUG.     ERRORS WRITING TO BULLETIN --------------------------J By default, MX_BULL_SITE_DELIVER.COM always returns success to the MX SITEL agent.  This was done to avoid bouncing network mail back to a mailing list.L In order to be notified in case of problems writing the message to BULLETIN,D you can define a system logical MX_BULLETIN_POSTMASTER to be a local0 username to receive failed MX_BULL transactions:  4 	$ DEFINE/SYS/EXEC MX_BULLETIN_POSTMASTER GOATHUNTER  G If BULLETIN returns an error, MX_BULL will forward the message (via the*+ callable VMS Mail interface) to GOATHUNTER.g     BULLETIN AND "From:" ADDRESSES ------------------------------O If you use the return address supplied by the MX SITE agent, the return address/= for BULLETIN messages will look something like the following:t  . 	From: MX%"@WKUVX1.BITNET:I-AMIGA@UBVM.BITNET"  N By default, MX_BULL_SITE_DELIVER.COM is set up to ignore the sender's address.L If you want to use the MX SITE-supplied address, simply modify the following! line in MX_BULL_SITE_DELIVER.COM:b  < 	$ USE_SITE_FROM = 0	!Change to 1 to use MX sender's address  L If the sender's address is ignored (again, the default), MX_BULL will searchJ the RFC822 headers in the message for the "From:" line.  It then pulls outJ the sender's address in a format suitable for using the RESPOND command inH BULLETIN.  This lets users easily RESPOND to the sender of a message, or" POST a message to the list itself.  M Note: MX_BULL just uses the address it's given.  Some addresses are gatewayedlM to death, leaving a bad address on the "From:" line.  This frequently happens > with messages coming via UUCP through Internet to Bitnet, etc.     AUTHOR INFORMATION ------------------ MX_BULL was written by:   , 	Hunter Goatley, VMS Systems Programmer, WKU  ! 	E-mail: goathunter@wkuvx1.bitnet; 	Voice:	502-745-5251  ' 	U.S. Mail:	Academic Computing, STH 226  			Western Kentucky University 			Bowling Green, KY 42101 $eod  , $copy/log sys$input MX_BULL_SITE_DELIVER.COM $deck  $!  $!  SITE_DELIVER.COM for MX_BULL $!4 $!  Author:	Hunter Goatley, goathunter@wkuvx1.bitnet $!  Date:	March 11, 1991 $!G $!  By default, MX_BULL will tell BULLETIN to search the RFC822 headers J $!  in the message for a "Reply-to:" or "From:" line.  If you want MX_BULLE $!  to use the P3 as the "From:" line, simply set USE_SITE_FROM to 1.r $!- $ USE_SITE_FROM = 0				!Change to 1 to use P3   $ mxbull :== $mx_exe:mx_bull.exe $!
 $ set noonH $ if f$trnlnm("SYS$SCRATCH").eqs."" then define SYS$SCRATCH MX_SITE_DIR:) $ if USE_SITE_FROM				!Use P3 as "From:"?tI $ then	create mx_site_dir:sitesender.addr;	!If so, write it out to a file D $	open/append tmp mx_site_dir:sitesender.addr;	!... to make sure DCL) $	write tmp p3				!... doesn't mess it upn $	close tmp				!...L. $	mxbull 'p1' 'p2' mx_site_dir:sitesender.addr+ $	delete/nolog mx_site_dir:sitesender.addr; 9 $ else	mxbull 'p1' 'p2'			!Just let BULLETIN find "From:"D $ endifM $ exit 1	!Always return successo $eod -