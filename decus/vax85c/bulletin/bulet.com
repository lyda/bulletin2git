$open/read input bullet.mai
$open/write output AAAREADME.TXT
$n = 0
$again:
$read input input
$write output input
$ n = n + 1
$ if n .lt. 73 then goto again
$ close output
$open/write output BBOARD.COM
$n = 0
$again:
$read input input
$write output input
$ n = n + 1
$ if n .lt. 5 then goto again
$ close output
$open/write output BULLCOM.CLD
$n = 0
$again:
$read input input
$write output input
$ n = n + 1
$ if n .lt. 36 then goto again
$ close output
$open/write output BULLCOMS.HLP
$n = 0
$again:
$read input input
$write output input
$ n = n + 1
$ if n .lt. 135 then goto again
$ close output
$open/write output BULLDIR.INC
$n = 0
$again:
$read input input
$write output input
$ n = n + 1
$ if n .lt. 8 then goto again
$ close output
$open/write output BULLETIN.COM
$n = 0
$again:
$read input input
$write output input
$ n = n + 1
$ if n .lt. 2 then goto again
$ close output
$open/write output BULLETIN.HLP
$n = 0
$again:
$read input input
$write output input
$ n = n + 1
$ if n .lt. 17 then goto again
$ close output
$open/write output BULLETIN.LNK
$n = 0
$again:
$read input input
$write output input
$ n = n + 1
$ if n .lt. 2 then goto again
$ close output
$open/write output BULLETIN.TXT
$n = 0
$again:
$read input input
$write output input
$ n = n + 1
$ if n .lt. 49 then goto again
$ close output
$open/write output BULLFILES.INC
$n = 0
$again:
$read input input
$write output input
$ n = n + 1
$ if n .lt. 27 then goto again
$ close output
$open/write output BULLFLAG.INC
$n = 0
$again:
$read input input
$write output input
$ n = n + 1
$ if n .lt. 23 then goto again
$ close output
$open/write output BULLMAIN.CLD
$n = 0
$again:
$read input input
$write output input
$ n = n + 1
$ if n .lt. 4 then goto again
$ close output
$open/write output BULLSTART.COM
$n = 0
$again:
$read input input
$write output input
$ n = n + 1
$ if n .lt. 3 then goto again
$ close output
$open/write output BULLUSER.INC
$n = 0
$again:
$read input input
$write output input
$ n = n + 1
$ if n .lt. 8 then goto again
$ close output
$open/write output CLIDEF.MAR
$n = 0
$again:
$read input input
$write output input
$ n = n + 1
$ if n .lt. 3 then goto again
$ close output
$open/write output CREATE.COM
$n = 0
$again:
$read input input
$write output input
$ n = n + 1
$ if n .lt. 10 then goto again
$ close output
$open/write output HPWD.MAR
$n = 0
$again:
$read input input
$write output input
$ n = n + 1
$ if n .lt. 223 then goto again
$ close output
$open/write output INSTALL.COM
$n = 0
$again:
$read input input
$write output input
$ n = n + 1
$ if n .lt. 8 then goto again
$ close output
$open/write output INSTRUCT.TXT
$n = 0
$again:
$read input input
$write output input
$ n = n + 1
$ if n .lt. 6 then goto again
$ close output
$open/write output LOGIN.COM
$n = 0
$again:
$read input input
$write output input
$ n = n + 1
$ if n .lt. 2 then goto again
$ close output
$open/write output SETUIC.MAR
$n = 0
$again:
$read input input
$write output input
$ n = n + 1
$ if n .lt. 54 then goto again
$ close output
$open/write output SETUSER.MAR
$n = 0
$again:
$read input input
$write output input
$ n = n + 1
$ if n .lt. 83 then goto again
$ close output
$open/write output STARTUP.COM
$n = 0
$again:
$read input input
$write output input
$ n = n + 1
$ if n .lt. 10 then goto again
$ close output
$open/write output USEROPEN.MAR
$n = 0
$again:
$read input input
$write output input
$ n = n + 1
$ if n .lt. 154 then goto again
$ close output
$ close input
