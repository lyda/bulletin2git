
 $set nover' $copy/log sys$input BULLETIN_MASTER.PAS  $deck $ %INCLUDE 'PMDF_ROOT:[SRC]ATTRIB.INC'* PROGRAM bulletin_master (output, outbound,?                          %INCLUDE 'PMDF_ROOT:[SRC]APFILES.INC', ?                          %INCLUDE 'PMDF_ROOT:[SRC]MMFILES.INC', @                          %INCLUDE 'PMDF_ROOT:[SRC]QUFILES.INC');  E (*******************************************************************) E (*                                                                 *) E (*      Authors:   Ned Freed (ned@ymir.bitnet)                     *) E (*                 Mark London (mrl%mit.mfenet@nmfecc.arpa)        *) E (*                 8/18/88                                         *) E (*                                                                 *) E (*******************************************************************)      CONST .        %INCLUDE 'PMDF_ROOT:[SRC]UTILCONST.INC',        %INCLUDE 'PMDF_ROOT:[SRC]OSCONST.INC',        %INCLUDE 'PMDF_ROOT:[SRC]APCONST.INC',        %INCLUDE 'PMDF_ROOT:[SRC]MMCONST.INC',        %INCLUDE 'PMDF_ROOT:[SRC]HECONST.INC'-        %INCLUDE 'PMDF_ROOT:[SRC]LOGCONST.INC' ,        %INCLUDE 'PMDF_ROOT:[SRC]SYCONST.INC'     TYPE-        %INCLUDE 'PMDF_ROOT:[SRC]UTILTYPE.INC' +        %INCLUDE 'PMDF_ROOT:[SRC]OSTYPE.INC' +        %INCLUDE 'PMDF_ROOT:[SRC]APTYPE.INC' +        %INCLUDE 'PMDF_ROOT:[SRC]SYTYPE.INC' +        %INCLUDE 'PMDF_ROOT:[SRC]MMTYPE.INC' +        %INCLUDE 'PMDF_ROOT:[SRC]HETYPE.INC' ,        %INCLUDE 'PMDF_ROOT:[SRC]LOGTYPE.INC'  '   string = varying [alfa_size] of char;      VAR ,        %INCLUDE 'PMDF_ROOT:[SRC]UTILVAR.INC'*        %INCLUDE 'PMDF_ROOT:[SRC]OSVAR.INC'*        %INCLUDE 'PMDF_ROOT:[SRC]APVAR.INC'*        %INCLUDE 'PMDF_ROOT:[SRC]QUVAR.INC'*        %INCLUDE 'PMDF_ROOT:[SRC]MMVAR.INC'*        %INCLUDE 'PMDF_ROOT:[SRC]HEVAR.INC'+        %INCLUDE 'PMDF_ROOT:[SRC]LOGVAR.INC'           outbound : text;   3   (* Place to store the channel we are servicing *) (    mail_channel : mm_channel_ptr := nil;     (* MM status control flag *)  N   mm_status          : (uninitialized, initialized, sending) := uninitialized;     filename       : vstring;   C   (* Place to store the protocol that we are providing/servicing *) '   protocol_name : varying [10] of char;   '   %INCLUDE 'PMDF_ROOT:[SRC]UTILDEF.INC' %   %INCLUDE 'PMDF_ROOT:[SRC]OSDEF.INC' %   %INCLUDE 'PMDF_ROOT:[SRC]APDEF.INC' %   %INCLUDE 'PMDF_ROOT:[SRC]HEDEF.INC' &   %INCLUDE 'PMDF_ROOT:[SRC]LOGDEF.INC'%   %INCLUDE 'PMDF_ROOT:[SRC]MMDEF.INC' %   %INCLUDE 'PMDF_ROOT:[SRC]QUDEF.INC'   .   (* Declare interface routines to BULLETIN *)     procedure INIT_MESSAGE_ADD (B     in_folder : [class_s] packed array [l1..u1 : integer] of char;@     in_from : [class_s] packed array [l2..u2 : integer] of char;C     in_descrip : [class_s] packed array [l3..u3 : integer] of char;      var ier : boolean); extern;       procedure WRITE_MESSAGE_LINE (I     in_line : [class_s] packed array [l1..u1 : integer] of char); extern;   '   procedure FINISH_MESSAGE_ADD; extern;   ;   PROCEDURE warn_master (message : varying [len1] of char);        BEGIN (* warn_master *)        writeln;!       os_write_datetime (output);        writeln (message);       END; (* warn_master *)     (* abort program. *)  <   PROCEDURE abort_master (message : varying [len1] of char);       BEGIN (* abort_master *)       warn_master (message);       halt;        END; (* abort_master *)   N (* activate_mm fires up the MM package and performs related startup chores. *)  9 function activate_mm (is_master : boolean) : rp_replyval;    var M   mm_init_reply : rp_replyval; found : boolean; mail_chan_text : ch_chancode;    stat : integer;    begin (* activate_mm *) B   (* Set up the name of the protocol we are servicing/providing *)-   stat := $TRNLOG (lognam := 'PMDF_PROTOCOL', 0                    rslbuf := protocol_name.body,3                    rsllen := protocol_name.length); I   if (not odd (stat)) or (stat = SS$_NOTRAN) then protocol_name := 'IN%';    mm_status := initialized;    mm_init_reply := mm_init; #   mail_chan_text := '            '; G   stat := $TRNLOG (lognam := 'PMDF_CHANNEL', rslbuf := mail_chan_text); 1   if (not odd (stat)) or (stat = SS$_NOTRAN) then %     mail_chan_text := 'l           '; )   if rp_isgood (mm_init_reply) then begin 7     mail_channel := mm_lookup_channel (mail_chan_text); @     if mail_channel = nil then mail_channel := mm_local_channel;,   end else mail_channel := mm_local_channel;   activate_mm := mm_init_reply;  end; (* activate_mm *)  (   (* initialize outbound, mm_ and qu_ *)     PROCEDURE init;        VAR fnam : vstring;          i : integer;       BEGIN (* init *)       os_jacket_access := true; *       (* Initialize subroutine packages *),       IF rp_isbad (activate_mm (false)) THEN8         abort_master ('Can''t initialize MM_ routines');        IF rp_isbad (qu_init) THEN8         abort_master ('Can''t initialize QU_ routines');       fnam.length := 0; ?       IF NOT os_open_file (outbound, fnam, exclusive_read) THEN 3         abort_master ('Can''t open outbound file');        END; (* init *)     : procedure return_bad_messages (var bad_address : vstring);   label    100;   var    line : vstring; .   bigline : bigvstring; result : rp_bufstruct;   pmdfenvelopefrom : vstring;    temp_line : vstringlptr;  A   procedure try_something (rp_error : integer; routine : string);      begin (* try_something *) %     if rp_isbad (rp_error) then begin 3       mm_wkill; mm_status := initialized; goto 100;      end;   end; (* try_something *)   begin (* return_bad_messages *) #   if mm_status = uninitialized then 3     try_something (activate_mm (false), 'mm_init');    mm_status := sending; )   try_something (mm_sbinit, 'mm_sbinit'); D   initstring (line, 'postmaster@                             ', 11);9   catvstring (line, mm_local_channel^.official_hostname); F   try_something (mm_winit (mail_channel^.chancode, line), 'mm_winit');   initstring (line, >               'postmaster                              ', 10);:   try_something (mm_wadr (mail_channel^.official_hostname,.                             line), 'mm_wadr');0   try_something (mm_rrply (result), 'mm_rrply');=   try_something (result.rp_val, 'mm_rrply structure return'); '   try_something (mm_waend, 'mm_waend'); D   initstring (line, 'From: PMDF Mail Server <Postmaster@     ', 35);9   catvstring (line, mm_local_channel^.official_hostname);    catchar (line, '>');   catchar (line, chr (chr_lf)); ,   try_something (mm_wtxt (line), 'mm_wtxt');D   initstring (line, 'To: Postmaster                          ', 14);   catchar (line, chr (chr_lf)); ,   try_something (mm_wtxt (line), 'mm_wtxt');D   initstring (line, 'Subject: Undeliverable mail             ', 27);   catchar (line, chr (chr_lf)); ,   try_something (mm_wtxt (line), 'mm_wtxt');C   initstring (line, 'Date:                                   ', 6);    os_cnvtdate (line);    catchar (line, chr (chr_lf)); ,   try_something (mm_wtxt (line), 'mm_wtxt');1   line.length := 1; line.body[1] := chr (chr_lf); ,   try_something (mm_wtxt (line), 'mm_wtxt');D   initstring (line, 'The message could not be delivered to:  ', 38);   catchar (line, chr (chr_lf)); ,   try_something (mm_wtxt (line), 'mm_wtxt');1   line.length := 1; line.body[1] := chr (chr_lf); ,   try_something (mm_wtxt (line), 'mm_wtxt');D   initstring (line, 'Addressee:                              ', 11);!   catvstring (line, bad_address);    catchar (line, chr (chr_lf)); ,   try_something (mm_wtxt (line), 'mm_wtxt');D   initstring (line, 'Reason: No such bulletin folder.        ', 32);   catchar (line, chr (chr_lf)); ,   try_something (mm_wtxt (line), 'mm_wtxt');1   line.length := 1; line.body[1] := chr (chr_lf); ,   try_something (mm_wtxt (line), 'mm_wtxt');D   initstring (line, '----------------------------------------', 40);   catchar (line, chr (chr_lf));    catchar (line, chr (chr_lf)); ,   try_something (mm_wtxt (line), 'mm_wtxt');'   try_something (qu_rkill, 'qu_rkill'); D   try_something (qu_rinit (filename, pmdfenvelopefrom), 'qu_rinit');0   while rp_isgood (qu_radr (line)) do begin end;(   while rp_isgood (qu_rtxt (bigline)) do4     try_something (mm_bigwtxt (bigline), 'mm_wtxt');   mm_status := initialized;R'   try_something (mm_wtend, 'mm_wtend'); 0   try_something (mm_rrply (result), 'mm_rrply');=   try_something (result.rp_val, 'mm_rrply structure return');R 100: end; (* return_bad_messages *)  #   (* submit messages to BULLETIN *)N     PROCEDURE dosubmit;*  1     VAR fromaddr, toaddr, tombox, name : vstring;          retval : rp_replyval;          line : bigvstring;         ier, done : boolean;         i : integer;       BEGIN (* dosubmit *)'       WHILE NOT eof (outbound) DO BEGINi,         readvstring (outbound, filename, 0);?         IF rp_isgood (qu_rinit (filename, fromaddr)) THEN BEGIN            done := false;*           FOR i := 1 TO fromaddr.length DO>             fromaddr.body[i] := upper_case (fromaddr.body[i]);4           IF rp_isgood (qu_radr (toaddr)) THEN BEGIN             REPEAT'               retval := qu_radr (name); &               UNTIL rp_isbad (retval);D             mm_parse_address (toaddr, name, tombox, TRUE, FALSE, 0);*             FOR i := 1 TO tombox.length DO<               tombox.body[i] := upper_case (tombox.body[i]);E             INIT_MESSAGE_ADD (substr (tombox.body, 1, tombox.length), 6                               protocol_name,' ', ier);L (* The parameter with 'IN%', causes bulletin to search for the From line: *)L (*                            substr (fromaddr.body, 1, fromaddr.length), *)             IF ier THEN BEGINP7               WHILE rp_isgood (qu_rtxt (line)) DO BEGINzJ                 IF line.length > 0 THEN line.length := pred (line.length);H                 WRITE_MESSAGE_LINE (substr (line.body, 1, line.length));                  END; (* while *)!               FINISH_MESSAGE_ADD;P               done := true;              END ELSE BEGIN- 	      warn_master ('Error opening folder ' +VF                               substr (tombox.body, 1, tombox.length));# 	      return_bad_messages(tombox);                done := true;              END; 	  END@           ELSE warn_master ('Can''t read To: address in file ' +H                             substr (filename.body, 1, filename.length));-           if done then qu_rend else qu_rkill;            ENDm5         ELSE warn_master ('Can''t open queue file ' +CF                           substr (filename.body, 1, filename.length));         END; (* while *)       END; (* dosubmit *)D     BEGIN (* bulletin_master *)S	     init;N     dosubmit;'     mm_end (true);     qu_end;C     END. (* bulletin_master *) $eod *+ $copy/log sys$input BULLETIN_MASTER.PAS_V32  $deckd$ %INCLUDE 'PMDF_ROOT:[SRC]ATTRIB.INC'> PROGRAM bulletin_master (%INCLUDE 'PMDF_ROOT:[SRC]APFILES.INC'>                          %INCLUDE 'PMDF_ROOT:[SRC]MMFILES.INC'>                          %INCLUDE 'PMDF_ROOT:[SRC]QUFILES.INC'#                          outbound);r       E (*******************************************************************)tE (*                                                                 *) E (*      Authors:   Ned Freed (ned@ymir.claremont.edu)              *)IE (*                 Mark London (mrl@nerus.pfc.mit.edu)             *) E (*                 12/28/90                                        *)pE (*                                                                 *)rE (*******************************************************************)           CONST;.        %INCLUDE 'PMDF_ROOT:[SRC]UTILCONST.INC',        %INCLUDE 'PMDF_ROOT:[SRC]OSCONST.INC',        %INCLUDE 'PMDF_ROOT:[SRC]APCONST.INC',        %INCLUDE 'PMDF_ROOT:[SRC]SYCONST.INC',        %INCLUDE 'PMDF_ROOT:[SRC]HECONST.INC',        %INCLUDE 'PMDF_ROOT:[SRC]MMCONST.INC'-        %INCLUDE 'PMDF_ROOT:[SRC]LOGCONST.INC'       t   TYPE-        %INCLUDE 'PMDF_ROOT:[SRC]UTILTYPE.INC'l+        %INCLUDE 'PMDF_ROOT:[SRC]OSTYPE.INC' +        %INCLUDE 'PMDF_ROOT:[SRC]APTYPE.INC' +        %INCLUDE 'PMDF_ROOT:[SRC]SYTYPE.INC'(+        %INCLUDE 'PMDF_ROOT:[SRC]HETYPE.INC'r+        %INCLUDE 'PMDF_ROOT:[SRC]MMTYPE.INC'l,        %INCLUDE 'PMDF_ROOT:[SRC]LOGTYPE.INC'  '   string = varying [alfa_size] of char;N     VARa/ (*     %INCLUDE 'PMDF_ROOT:[SRC]UTILVAR.INC' *) *        %INCLUDE 'PMDF_ROOT:[SRC]OSVAR.INC'- (*     %INCLUDE 'PMDF_ROOT:[SRC]APVAR.INC' *) - (*     %INCLUDE 'PMDF_ROOT:[SRC]QUVAR.INC' *) *        %INCLUDE 'PMDF_ROOT:[SRC]MMVAR.INC'- (*     %INCLUDE 'PMDF_ROOT:[SRC]HEVAR.INC' *)h. (*     %INCLUDE 'PMDF_ROOT:[SRC]LOGVAR.INC' *)      m        outbound : text;a$        fromaddr, filename : vstring;"        bull_chan : mm_channel_ptr;$        bull_chan_text : ch_chancode;,        protocol_name : varying [10] of char;  '   %INCLUDE 'PMDF_ROOT:[SRC]UTILDEF.INC'c%   %INCLUDE 'PMDF_ROOT:[SRC]OSDEF.INC'z%   %INCLUDE 'PMDF_ROOT:[SRC]APDEF.INC's%   %INCLUDE 'PMDF_ROOT:[SRC]HEDEF.INC' &   %INCLUDE 'PMDF_ROOT:[SRC]LOGDEF.INC'%   %INCLUDE 'PMDF_ROOT:[SRC]SYDEF.INC'H%   %INCLUDE 'PMDF_ROOT:[SRC]MMDEF.INC'a%   %INCLUDE 'PMDF_ROOT:[SRC]QUDEF.INC'        .   (* Declare interface routines to BULLETIN *)      a   procedure INIT_MESSAGE_ADD (B     in_folder : [class_s] packed array [l1..u1 : integer] of char;@     in_from : [class_s] packed array [l2..u2 : integer] of char;C     in_descrip : [class_s] packed array [l3..u3 : integer] of char;u     var ier : boolean); extern;t           procedure WRITE_MESSAGE_LINE (I     in_line : [class_s] packed array [l1..u1 : integer] of char); extern;*      m'   procedure FINISH_MESSAGE_ADD; extern;e       ;   PROCEDURE warn_master (message : varying [len1] of char);n      n     BEGIN (* warn_master *)i        writeln (os_output_file^);*       os_write_datetime (os_output_file^);)       writeln (os_output_file^, message);        END; (* warn_master *)      h(   (* initialize outbound, mm_ and qu_ *)      e   PROCEDURE init;             VAR fnam : vstring;          i, stat : integer;       BEGIN (* init *)       os_insure_open_output;       os_jacket_access := true; *       (* Initialize subroutine packages *)        IF rp_isbad (mm_init) THEN*         mm_abort_program (os_output_file^,A           'Can''t initialize MM_                    ', 20, true);i        IF rp_isbad (qu_init) THEN*         mm_abort_program (os_output_file^,B           'Can''t initialize QU_                    ', 20, false);2       bull_chan := mm_my_channel (bull_chan_text);F       (* Set up the name of the protocol we are servicing/providing *)1       stat := $TRNLOG (lognam := 'PMDF_PROTOCOL','4                        rslbuf := protocol_name.body,7                        rsllen := protocol_name.length);PM       IF (not odd (stat)) OR (stat = SS$_NOTRAN) THEN protocol_name := 'IN%';        fnam.length := 0;i?       IF NOT os_open_file (outbound, fnam, exclusive_read) THENl*         mm_abort_program (os_output_file^,B           'Can''t open outbound file                ', 24, false);       END; (* init *)        <   PROCEDURE return_bad_messages (var bad_address : vstring);     LABEL(     100;     VARo     line, errorsto : vstring;x0     bigline : bigvstring; result : rp_bufstruct;     header : he_header;m     i : integer;  C     PROCEDURE try_something (rp_error : integer; routine : string);'       BEGIN (* try_something *)_'       IF rp_isbad (rp_error) THEN BEGIN'P         warn_master ('Routine ' + routine + ' failed while returning message.');         mm_wkill; goto 100;          END; (* if *)e       end; (* try_something *)  !   BEGIN (* return_bad_messages *)d     he_init_header (header);+     try_something (mm_sbinit, 'mm_sbinit');,F     initstring (line, 'postmaster@                             ', 11);;     catvstring (line, mm_local_channel^.official_hostname); @     try_something (mm_winit (bull_chan_text, line), 'mm_winit');)     try_something (qu_rbtxt, 'qu_rbtxt');iG     try_something (he_read_header (header, qu_rtxt), 'he_read_header');-     errorsto.length := 0;nE     IF header[he_errors_to] <> NIL THEN WITH header[he_errors_to]^ DOm-       IF ltext.length <= ALFA_SIZE THEN BEGIN_(         errorsto.length := ltext.length;K         FOR i := 1 TO errorsto.length DO errorsto.body[i] := ltext.body[i];(         END; (* if *) %     IF errorsto.length > 0 THEN BEGIN M       try_something (mm_wadr (mm_local_channel^.official_hostname, errorsto),d)                               'mm_wadr'); 4       try_something (mm_rrply (result), 'mm_rrply');	       ENDn      ELSE result.rp_val := RP_NO;*     IF rp_isbad (result.rp_val) THEN BEGIN'       copyvstring (errorsto, fromaddr);TB       try_something (mm_wadr (mm_local_channel^.official_hostname,4                               fromaddr), 'mm_wadr');4       try_something (mm_rrply (result), 'mm_rrply');       END; (* if *);A     IF bull_chan^.sendpost or rp_isbad (result.rp_val) THEN BEGINI       initstring (line,oB                   'postmaster                              ', 10);N       try_something (mm_wadr (bull_chan^.official_hostname, line), 'mm_wadr');4       try_something (mm_rrply (result), 'mm_rrply');A       try_something (result.rp_val, 'mm_rrply structure return');N       END; (* if *)E)     try_something (mm_waend, 'mm_waend');)F     initstring (line, 'From: PMDF Mail Server <Postmaster@     ', 35);;     catvstring (line, mm_local_channel^.official_hostname);=     catchar (line, '>');!     catchar (line, chr (chr_lf));_.     try_something (mm_wtxt (line), 'mm_wtxt');E     initstring (line, 'To:                                     ', 4);       catvstring (line, errorsto);!     catchar (line, chr (chr_lf));u.     try_something (mm_wtxt (line), 'mm_wtxt');F     initstring (line, 'Subject: Undeliverable bulletin         ', 31);!     catchar (line, chr (chr_lf)); .     try_something (mm_wtxt (line), 'mm_wtxt');E     initstring (line, 'Date:                                   ', 6);e     os_catdatetime (line);!     catchar (line, chr (chr_lf));1.     try_something (mm_wtxt (line), 'mm_wtxt');3     line.length := 1; line.body[1] := chr (chr_lf); .     try_something (mm_wtxt (line), 'mm_wtxt');F     initstring (line, 'The message could not be delivered to:  ', 38);!     catchar (line, chr (chr_lf));n.     try_something (mm_wtxt (line), 'mm_wtxt');3     line.length := 1; line.body[1] := chr (chr_lf); .     try_something (mm_wtxt (line), 'mm_wtxt');F     initstring (line, 'Addressee:                              ', 11);#     catvstring (line, bad_address); !     catchar (line, chr (chr_lf)); .     try_something (mm_wtxt (line), 'mm_wtxt');F     initstring (line, 'Reason: No such bulletin folder.        ', 32);!     catchar (line, chr (chr_lf));h.     try_something (mm_wtxt (line), 'mm_wtxt');3     line.length := 1; line.body[1] := chr (chr_lf); .     try_something (mm_wtxt (line), 'mm_wtxt');F     initstring (line, '----------------------------------------', 40);!     catchar (line, chr (chr_lf));.!     catchar (line, chr (chr_lf));L.     try_something (mm_wtxt (line), 'mm_wtxt');L     try_something (he_write_header (header, mm_bigwtxt), 'he_write_header');3     line.length := 1; line.body[1] := chr (chr_lf); .     try_something (mm_wtxt (line), 'mm_wtxt');*     WHILE rp_isgood (qu_rtxt (bigline)) DO6       try_something (mm_bigwtxt (bigline), 'mm_wtxt');)     try_something (mm_wtend, 'mm_wtend');N2     try_something (mm_rrply (result), 'mm_rrply');?     try_something (result.rp_val, 'mm_rrply structure return');    100:"     END; (* return_bad_messages *)  #   (* submit messages to BULLETIN *)           PROCEDURE dosubmit;        '     VAR toaddr, tombox, name : vstring;*         retval : rp_replyval;*         line : bigvstring;         ier, done : boolean;         i : integer;$         chan_dummy : mm_channel_ptr;      O     BEGIN (* dosubmit *)'       WHILE NOT eof (outbound) DO BEGINL,         readvstring (outbound, filename, 0);?         IF rp_isgood (qu_rinit (filename, fromaddr)) THEN BEGIN]           done := false;4           IF rp_isgood (qu_radr (toaddr)) THEN BEGIN             REPEAT'               retval := qu_radr (name); &               UNTIL rp_isbad (retval);A             chan_dummy := mm_parse_address (toaddr, name, tombox,]?                                             TRUE, FALSE, 0, 0); *             FOR i := 1 TO tombox.length DO<               tombox.body[i] := upper_case (tombox.body[i]);E             INIT_MESSAGE_ADD (substr (tombox.body, 1, tombox.length),A7                               protocol_name, ' ', ier);*             IF ier THEN BEGINP7               WHILE rp_isgood (qu_rtxt (line)) DO BEGIN*J                 IF line.length > 0 THEN line.length := pred (line.length);H                 WRITE_MESSAGE_LINE (substr (line.body, 1, line.length));                  END; (* while *)!               FINISH_MESSAGE_ADD;                done := true;;               ENDt             ELSE BEGIN- 	      warn_master ('Error opening folder ' +IC                            substr (tombox.body, 1, tombox.length));F$ 	      return_bad_messages (tombox);               done := true;O               END;             ENDR@           ELSE warn_master ('Can''t read To: address in file ' +H                             substr (filename.body, 1, filename.length));4           IF done THEN qu_rend ELSE qu_rkill (true);           ENDr5         ELSE warn_master ('Can''t open queue file ' +aF                           substr (filename.body, 1, filename.length));         END; (* while *)       END; (* dosubmit *)l      p   BEGIN (* bulletin_master *)o	     init;      dosubmit;l     mm_end (true);     qu_end;r     END. (* bulletin_master *) $eod c $copy/log sys$input MASTER.COM $deck B $ ! MASTER.COM - Initiate delivery of messages queued on a channel $ ! O $ ! Modification history and parameter definitions are at the end of this file.I $ !w
 $ set noon $ ! : $ ! Clean up and set up channel name, if on hold just exit $ !t1 $ channel_name = f$edit(p1, "COLLAPSE,LOWERCASE") N $ hold_list = "," + f$edit(f$logical("PMDF_HOLD"), "COLLAPSE,LOWERCASE") + ","9 $ if f$locate("," + channel_name + ",", hold_list) .lt. -g"      f$length(hold_list) then exit/ $ define/process pmdf_channel "''channel_name'"  $ ! 7 $ ! Save state information, set up environment properlye $ !a+ $ save_directory = f$environment("DEFAULT")  $ set default pmdf_root:[queue]i/ $ save_protection = f$environment("PROTECTION") , $ set protection=(s:rwed,o:rwed,g,w)/default' $ save_privileges = f$setprv("NOSHARE")o $ !_E $ if f$logical("PMDF_DEBUG") .eqs. "" then on control_y then goto oute $ ! 6 $ ! Create listing of messages queued on this channel. $ !t' $ if p3 .eqs. "" then p3 = "1-JAN-1970"cH $ dirlst_file = "pmdf_root:[log]" + channel_name + "_master_dirlst_" + -   F$GETJPI ("", "PID") + ".tmp"o' $ define/process outbound 'dirlst_file'lL $ directory/noheader/notrailer/column=1/since="''p3'"/output='dirlst_file' -(   pmdf_root:[queue]'channel_name'_*.%%;* $ !n= $ ! Determine whether or not connection should really be madee $ !) $ if p2 .nes. "POLL" .and. -@      f$file_attributes(dirlst_file, "ALQ") .eq. 0 then goto out1 $ ! % $ ! Handle various channels specially  $ ! 3 $ if channel_name .eqs. "l" then goto local_channel:B $ if channel_name .eqs. "d" then goto DECnet_compatibility_channel9 $ if channel_name .eqs. "directory" then goto dir_channel H $ if f$extract(0,5,channel_name) .eqs. "anje_"  then goto BITNET_channelH $ if f$extract(0,4,channel_name) .eqs. "bit_"   then goto BITNET_channelJ $ if f$extract(0,5,channel_name) .eqs. "bull_"  then goto BULLETIN_channelD $ if f$extract(0,3,channel_name) .eqs. "cn_"    then goto CN_channelF $ if f$extract(0,5,channel_name) .eqs. "ctcp_"  then goto CTCP_channelH $ if f$extract(0,3,channel_name) .eqs. "dn_"    then goto DECnet_channelG $ if f$extract(0,6,channel_name) .eqs. "dsmtp_" then goto DSMTP_channel F $ if f$extract(0,5,channel_name) .eqs. "etcp_"  then goto ETCP_channelF $ if f$extract(0,5,channel_name) .eqs. "ftcp_"  then goto FTCP_channelE $ if f$extract(0,4,channel_name) .eqs. "ker_"   then goto KER_channelhF $ if f$extract(0,5,channel_name) .eqs. "mail_"  then goto MAIL_channelF $ if f$extract(0,5,channel_name) .eqs. "mtcp_"  then goto MTCP_channelF $ if f$extract(0,5,channel_name) .eqs. "px25_"  then goto PX25_channelE $ if f$extract(0,4,channel_name) .eqs. "tcp_"   then goto TCP_channel F $ if f$extract(0,5,channel_name) .eqs. "test_"  then goto TEST_channelF $ if f$extract(0,5,channel_name) .eqs. "uucp_"  then goto UUCP_channelF $ if f$extract(0,5,channel_name) .eqs. "wtcp_"  then goto WTCP_channelG $ if f$extract(0,6,channel_name) .eqs. "xsmtp_" then goto XSMTP_channelN $ ! H $ ! This must be a PhoneNet channel (the default); set up and use MASTER> $ !  Read the list of valid connection types for each channel. $ !a $ cnt = f$integer("0")J $ open/read/error=regular_master pmdf_data pmdf_root:[table]phone_list.dat $       list_loop:0 $               read/end=eof_list pmdf_data line $ !  Ignore comment lines.< $               if (f$extract (0, 1, line) .eqs. "!") then -&                         goto list_loop: $               line = f$edit (line, "COMPRESS,LOWERCASE")- $ !  Get the channel name from the line read.d? $               chan = f$extract (0, f$locate(" ", line), line) 3 $               if (chan .nes. channel_name) then -u& $                       goto list_loop $ !  Get the connection nameP $               name = f$edit(f$extract(f$locate(" ",line),255,line),"COLLAPSE")" $ !  If none, then ignore the line' $               if name .eqs. "" then -'&                         goto list_loop $ !  Found at least one to try., $               cnt = cnt + 1i5 $               @pmdf_root:[exe]all_master.com 'name' % $               define PMDF_DEVICE TTc $ !l $ ! Define other logical names $ !nO $ define/user script             pmdf_root:[table.'channel_name']'name'_script.lP $ define/user ph_current_message pmdf_root:[log]'channel_name'_master_curmsg.tmpH $ define/user option_file        pmdf_root:[table]'channel_name'_option.L $ define/user di_transcript      pmdf_root:[log]di_'channel_name'_master.trnL $ define/user ph_logfile         pmdf_root:[log]ph_'channel_name'_master.logL $ define/user di_errfile         pmdf_root:[log]di_'channel_name'_master.log $ ! L $ !   This check attempts to verify that we are in fact the owner process ofD $ !   the device, TT.  If the device is sharable, then we ignore the $ !   owner. $ ! ; $ if (f$getdvi("TT","pid") .nes. f$getjpi(0,"pid")) .and. -t0      (f$getdvi("TT","shr") .eqs. "FALSE") then -         goto list_loop $ ! # $ !  Run master to deliver the mail  $ !d $ run pmdf_root:[exe]masterc $ exit_stat = $status_ $ !h< $ ! Activate optional cleanup script to reset terminal/modem $ ! C $ if f$search("pmdf_root:[exe]''name'_cleanup.com") .nes. "" then -)3      @pmdf_root:[exe]'name'_cleanup.com 'exit_stat'  $ deallocate TT1 $ deassign TT: $ deassign PMDF_DEVICE $ !eG $ !  If master does not exit normally, then try a different connection.- $ !-) $ if exit_stat .ne. 1 then goto list_loopn $ eof_list:f $ close pmdf_datal $ !cI $ !  If we found at least one connection type for this channel, then skipe3 $ !  the attempt to use the conventional mechanism.e $ !e& $ if cnt .gt. 0 then goto out_phonenet $ !h $ regular_master:r+ $ @pmdf_root:[exe]'channel_name'_master.com  $ define PMDF_DEVICE TT( $ !n $ !  Define logical names  $ !iH $ define/user script             pmdf_root:[table]'channel_name'_script.P $ define/user ph_current_message pmdf_root:[log]'channel_name'_master_curmsg.tmpH $ define/user option_file        pmdf_root:[table]'channel_name'_option.L $ define/user di_transcript      pmdf_root:[log]di_'channel_name'_master.trnL $ define/user ph_logfile         pmdf_root:[log]ph_'channel_name'_master.logL $ define/user di_errfile         pmdf_root:[log]di_'channel_name'_master.log $ !  $ run pmdf_root:[exe]mastere $ exit_stat = $statusI $ !d= $ !  Activate optional cleanup script to reset terminal/modeme $ !r< $ if f$search("''channel_name'_cleanup.com") .nes. "" then -;      @pmdf_root:[exe]'channel_name'_cleanup.com 'exit_stat'  $ deallocate TTo $ deassign TTa $ deassign PMDF_DEVICE $ !  $ out_phonenet: ' $ if P4 .eqs. "POST" then wait 00:00:30  $ goto out1i $ !( $ ! Directory channelh $ !m $ dir_channel: $ !s $ run pmdf_root:[exe]dir_master  $ goto out1  $ ! 6 $ ! This is a DECnet channel; set up and use DN_MASTER $ !T $ DECnet_channel:  $ !  $ ! Define other logical names $ !(4 $ node_name = f$edit(channel_name - "dn_", "UPCASE")P $ define/user ph_current_message pmdf_root:[log]'channel_name'_master_curmsg.tmpH $ define/user option_file        pmdf_root:[table]'channel_name'_option.L $ define/user di_transcript      pmdf_root:[log]di_'channel_name'_master.trnL $ define/user ph_logfile         pmdf_root:[log]ph_'channel_name'_master.logL $ define/user di_errfile         pmdf_root:[log]di_'channel_name'_master.log: $ define/user pmdf_node          "''node_name'::""PMDF=""" $ !  $ run pmdf_root:[exe]dn_master $ goto out1r $ !e+ $ ! This is a BITNET channel; use BN_MASTERs $ !  $ BITNET_channel:m $ !e> $ if channel_name .eqs. "bit_gateway" then goto BITNET_gateway $ run pmdf_root:[exe]bn_master $ goto out1  $ ! 6 $ ! This is the BITNET gateway channel; use BN_GATEWAY $ !' $ BITNET_gateway:  $ !  $ run pmdf_root:[exe]bn_gatewayi $ goto out1) $ ! 3 $ ! This is a BULLETIN channel; use BULLETIN_MASTER  $ !  $ BULLETIN_channel:w $ !a$ $ run pmdf_root:[exe]bulletin_master $ goto out1  $ ! 3 $ ! This is a Tektronix TCP channel; use TCP_MASTER  $ !N $ TCP_channel: $ !  $ run pmdf_root:[exe]tcp_masterE $ goto out1i $ !t8 $ ! This is a CMU/Tektronix TCP channel; use CTCP_MASTER $ !e $ CTCP_channel:  $ !t  $ run pmdf_root:[exe]ctcp_master $ goto out1R $ ! 5 $ ! This is a Wollongong TCP channel; use WTCP_MASTERq $ !  $ WTCP_channel:  $ !  $ ! Define other logical names $ !f  $ run pmdf_root:[exe]wtcp_master $ goto out1  $ !o3 $ ! This is a MultiNet TCP channel; use MTCP_MASTER  $ !j $ MTCP_channel:  $ !e  $ run pmdf_root:[exe]mtcp_master $ goto out1o $ !s2 $ ! This is a Excelan TCP channel; use ETCP_MASTER $ !A $ ETCP_channel:f $ !t  $ run pmdf_root:[exe]etcp_master $ goto out1  $ !f6 $ ! This is an NRC Fusion TCP channel; use FTCP_MASTER $ !' $ FTCP_channel:  $ !   $ run pmdf_root:[exe]ftcp_master $ goto out1p $ !l $ CN_channel:e $ !c $ ! Define other logical names $ !eH $ define/user script             pmdf_root:[table]'channel_name'_script.4 $ ! following may vary: should point to cnio's groupK $ define/table=lnm$process_directory lnm$temporary_mailbox lnm$group_000277q $ ! - $ run/nodeb'p5' pmdf_root:[exe]cn_smtp_mastera $ goto out1  $ !g $ KER_channel: $ !nK $ ! kermit protocol is slave only. If we get here there has been a mistake.o/ $ ! however we will just exit and no harm done.  $ goto out1" $ !D> $ ! This is a PhoneNet X25 channel; set up and use PX25_MASTER $ !o $ PX25_channel:c $ != $ ! Define other logical names $ !-P $ define/user ph_current_message pmdf_root:[log]'channel_name'_master_curmsg.tmpH $ define/user option_file        pmdf_root:[table]'channel_name'_option.L $ define/user di_transcript      pmdf_root:[log]'channel_name'_di_master.trnL $ define/user ph_logfile         pmdf_root:[log]'channel_name'_ph_master.logL $ define/user di_errfile         pmdf_root:[log]'channel_name'_di_master.log $ !c  $ run pmdf_root:[exe]PX25_master $ goto out1n $ ! ; $ ! This is a DEC/Shell channel; set up and use UUCP_MASTERN $ !a $ UUCP_channel:a $ !4 $ ! Define other logical names $ !t' $ uucp_to_host = channel_name - "uucp_"n2 $ define/user uucp_to_host       "''uucp_to_host'"$ $ define/user uucp_current_message -1   pmdf_root:[log]'channel_name'_master_curmsg.tmpcM $ define/user uucp_logfile       pmdf_root:[log]'channel_name'_master.logfilen $ !.  $ run pmdf_root:[exe]UUCP_master) $ uupoll = "$shell$:[usr.lib.uucp]uupoll". $ uupoll 'uucp_to_host'_ $ goto out1f $ !t< $ ! This is a X.25 SMTP channel; set up and use XSMTP_MASTER $ !f $ XSMTP_channel: $ !m! $ run pmdf_root:[exe]xsmtp_mastera $ goto out1e $ !t> $ ! This is a DECNET SMTP channel; set up and use DSMTP_MASTER $ !a $ DSMTP_channel: $ !q! $ run pmdf_root:[exe]dsmtp_master  $ goto out1t $ !c= $ ! Handle delivery on the local channel, MAIL_ channels, anda$ $ ! the DECnet compatibility channel $ !t $ MAIL_channel:  $ local_channel: $ DECnet_compatibility_channel:g$ $ open/read queue_file 'dirlst_file' $ local_loop:qN $   read/end=exit_local_loop/error=exit_local_loop  queue_file file_to_process* $   priv_list = f$setprv("SYSPRV, DETACH")0 $   mail/protocol=pmdf_mailshr 'file_to_process'# $   priv_list = f$setprv(priv_list)) $ goto local_loopn $ !  $ exit_local_loop: $ close queue_file $ goto out1n $ !t5 $ ! This is a SMTP test channel, use TEST_SMTP_MASTERo $ !i $ TEST_channel:s $ !e8 $ ! Typically some form of redirection is needed here... $ deassign sys$input% $ run pmdf_root:[exe]test_smtp_master  $ goto out1l $ !  $ out1:  $ delete 'dirlst_file';* $ !t- $ ! Common exit point - clean up things first  $ !f $ out:B $ if f$logical("OUTBOUND") .nes. "" then deassign/process outboundJ $ if f$logical("PMDF_CHANNEL") .nes. "" then deassign/process pmdf_channel9 $ if f$logical("PMDF_DATA") .nes. "" then close pmdf_datan8 $ if f$logical("PMDF_DEVICE") .eqs. "" then goto restore $ deallocate TT. $ deassign TTt $ deassign PMDF_DEVICE
 $ restore: $ !_ $ ! Restore saved stufft $ !a, $ set protection=('save_protection')/default $ set default 'save_directory'& $ set process/priv=('save_privileges') $ !  $ exit $ !  $ ! Modification history:  $ ! * $ ! This version by Ned Freed, 20-Jul-1986 $ !sM $ ! Modified by Gregg Wonderly to allow multiple connections for each channel] $ !   10-Oct-1986.* $ ! Some additions by Ned Freed 30-Oct-86.D $ ! Added CMU/Tektronix TCP channel (CTCP) /Kevin Carosso 6-Mar-1987< $ ! Added Multinet TCP channel (MTCP) /Ned Freed 10-Mar-19876 $ ! Added directory save/restore /Ned Freed 1-Jun-1987: $ ! Added Excelan TCP channel (ETCP) /Ned Freed 9-Jul-1987: $ ! Added MAIL, CNIO, KERMIT channel /Bob Smart 4-Jul-1987D $ ! Added Warwick Jackson's PhoneNet X25 support /Ned Freed 5-Sep-87K $ ! Added X25 SMTP channel SX25_ /Goeran Bengtsson, Mats Sundvall 24-Jul-87eB $ ! Added NRC Fusion TCP channel (FTCP) /Kevin Carosso 12-Jan-1988K $ ! Added a variant of Randy McGee's code to put a list of channels on hold  $ !   /Ned Freed 9-Feb-1988eH $ ! Made this procedure save and restore a little more state informationH $ !   than it used to, including default protection and privileges. AlsoG $ !   moved a bunch of the logical name assignments around to eliminatel? $ !   redundant code all over the place. /Ned Freed 10-Feb-1988 C $ ! Modified to allow P3 date/time paramter. /Ned Freed 23-Feb-1988lJ $ ! Added support for Dennis Boylan's UUCP channel. /Ned Freed 28-Mar-1988B $ ! Added Robert Smart's directory channel. /Ned Freed 21-Apr-1988D $ ! Added support for Warwick Jackson's SMTP over X.25 and SMTP over- $ !   DECnet channels. /Ned Freed 26-May-1988 6 $ ! Added P4 and P5 parameters. /Ned Freed 10-Jun-1988N $ ! Added code to call the TEST_SMTP_MASTER for testing. /Ned Freed 1-Jul-1988= $ ! Added preliminary support for ANJE. /Ned Freed 7-Jul-1988 C $ ! Removed extra dispatch for WTCP_ channel. /Ned Freed 3-Sep-1988_< $ ! Added dispatch for BULL_ channel. /Ned Freed 28-Nov-1988I $ ! Cleaned up error recovered and emergency exit -- close PHONE_LIST.DATe0 $ !   file when aborting. /Ned Freed 13-Dec-1988I $ ! Additional error recovery cleanup -- use PMDF_DEVICE instead of TT tot< $ !   allow deallocation on an abort. /Ned Freed 14-Dec-1988 $ !  $ ! Parameters:a $ !cB $ !   P1 - Name of the channel whose messages are to be delivered.F $ !   P2 - Activity type. If P2 .eqs. "POLL", establish the connectionF $ !        unconditionally, otherwise only establish the connection if- $ !        messages are waiting in the queue. J $ !   P3 - Earliest possible date/time for message(s). Messages older than' $ !        this time are not processed./J $ !   P4 - Environment. P4 .eqs. "POST" if MASTER is being called from theI $ !        POST.COM procedure or some other procedure that invokes MASTERTI $ !        more than once. This parameter is used to insert delays before 5 $ !        returning if hardware needs time to reset. 8 $ !   P5 - Parameter reserved for channel-specific uses. $eod : $copy/log sys$input PMDF.TXT $deck K This describes the procedure necessary to use BULLETIN with PMDF.  You mustlH be using at least PMDF V3.1.  If using V3.2 you will instead have to useO BULLETIN_MASTER.PAS_V32.  V3.2 does come with it's own BULLETIN_MASTER.PAS, butnL there is a small bug in it.  If you are using V4.0 or later, use the commandI procedure PMDF_ROOT:[SRC]PMDF_BULLETIN.COM and ignore the files that are ' distributed with BULLETIN.  K BULLETIN_MASTER.PAS and MASTER.COM are the files you need to run a BULLETINeM channel.  Put BULLETIN_MASTER.PAS in a subdirectory of PMDF_ROOT:[SRC] (I useiM the directory PMDF_ROOT:[SRC.BULLETIN]). Compile it there and then link it aseP follows.  This might result in undefined reference errors.  You can ignore them,N as these are routines that are used for connecting to USENET NEWS, and are not' used by the BULLETIN_MASTER executable.r  	 For V3.1:   .     LINK /EXE=PMDF_ROOT:[EXE]BULLETIN_MASTER -<     BULLETIN_MASTER,[EXE]PMDFLIB/LIB,BULL_SOURCE:BULL/LIB, -     PMDF_ROOT:[EXE]VAXC/OPT)  	 For V3.2:h  .     LINK /EXE=PMDF_ROOT:[EXE]BULLETIN_MASTER -C     BULL_DIR:BULLETIN_MASTER,PMDF_ROOT:[EXE]PMDFSHR_LINK.OPT/OPT, - G     [EXE]IDENT.OPT/OPT,BULL_SOURCE:BULL.OLB/LIB,PMDF_ROOT:[EXE]VAXC/OPT   K If you need to, put the new MASTER.COM in PMDF_ROOT:[EXE]. NOTE: Check yourtN MASTER.COM, as the latest version of PMDF contains the code necessary to checkJ for bulletin mail.  However, it will not necessary have the latest copy of BULLETIN_MASTER.PAS. l  K You then need a channel definition like the following in your configurations file PMDF.CNF:       bull_local single loggingo     BULLETIN-DAEMONi   And a rewrite rule of the form:M  A     BULLETIN                          $U%BULLETIN@BULLETIN-DAEMONr  M Then you put an alias in your ALIASES. file for each mailing list you want to ' process this way. I have the following:e       info-vax: info-vax@bulletin      tex-hax: tex-hax@bulletinn"     xmailer-list: xmailer@bulletin     mail-l: mail-l@bulletino     jnet-l: jnet-l@bulletint     policy-l: policy-l@bulletin      future-l: future-l@bulletine     mon-l: mon-l@bulletin      ug-l: ug-l@bulletinc  F Then mail sent to info-vax@localhost will be routed to a folder called* info-vax. In general, an alias of the form       a : b@bulletin  < will route mail sent to a@localhost to folder b in BULLETIN.  J NOTE: If you have BBOARD set for a folder that you convert to be deliveredH directly to PMDF, remember to do a SET NOBBOARD for that folders (unlessO using the LISTSERV option.  See HELP SET BBOARD LISTSERV for more info).  After . doing so, restart BULLCP using BULLETIN/START. $eod  