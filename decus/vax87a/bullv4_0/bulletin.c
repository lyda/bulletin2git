/*
 *	  -------------------------------------------------------
 *        Neither  York  University,   Department  of   Computer
 *        Science   nor   the  authors assume any responsibility
 *        for the use or reliability of this software.
 *
 *        Copyright (C) 1986, York University
 *                            Department of Computer Science
 *
 *        General permission to copy  or  modify,  but  not  for
 *        profit,  is  hereby granted, provided  that  the above
 *        copyright notice is included  and  reference  made  to
 *        the fact that reproduction  privileges  were   granted
 *        by the York University, Department of Computer Science.
 *	  -------------------------------------------------------
 *
 *	  Written by: Edward Fung and James P. Lewis
 *		      Department of Computer Science
 *		      York University
 *		      1984, 1985, 1986
 *
 */

/*
 * Facility:  Bulletin
 *
 * Environment:  User mode, non-privileged code.
 *
 * Modified by:
 *
 * 1-000 - EF   ??-???-1984
 * 2-000 - JPL  ??-???-1984
 * 3-000 - JPL  01-JAN-1986
 * 4-000 - JPL  10-JUL-1986
 *
 */

#module bulletin

#include        ssdef.h
#include        "bull.h"

main()
{
        char    helplib[QUAL_LEN],
		key[KEY_LEN];
        long    status,
		video_type;
	struct	bull_lst_struct	*bull_lst;

        get_term(&video_type, &status);	/* Video terminal? */

        if (get_val(HELP_QUAL, 0, 0) & SS$_NORMAL) {	/* /HELP */
                if (trn_lnm("LNM$SYSTEM_TABLE", 0, "USER_HELPLIB", 0, 
		    helplib, QUAL_LEN) == SS$_NORMAL) 
                        help(helplib, USER_HELPSTR);
                else    help(USER_HELPLIB, USER_HELPSTR); 
        }
        else {
		bull_lst = (struct bull_lst_struct *)
			   malloc(sizeof(struct bull_lst_struct));
		get_bull(bull_lst, TRUE);

                if (get_val(BRIEF_QUAL, 0, 0) & SS$_NORMAL)	/* /BRIEF */
                        brief_bull(bull_lst);
                else 
		if (get_val(NEW_QUAL, 0, 0) & SS$_NORMAL)	/* /NEW */
                        new_bull(bull_lst);
                else 
		if (get_val(READ_QUAL, 0, 0) & SS$_NORMAL) {	/* /READ */
                        get_val(READ_QUAL, key, KEY_LEN - 1);
			lowcase(key);

                        if (video_type && (status & SS$_NORMAL)) 
                                scr_brwsbull(bull_lst, key, ALL);
                        else    lin_brwsbull(bull_lst, key, ALL);
                }
                else 
		if (get_val(SRCH_QUAL, 0, 0) & SS$_NORMAL) {	/* /SEARCH */
                        get_val(SRCH_QUAL, key, KEY_LEN - 1);
			lowcase(key);

                        if (video_type && (status & SS$_NORMAL))
                                scr_brwsbull(bull_lst, key, LIB);
                        else    lin_brwsbull(bull_lst, key, LIB);
                }
                else {
                        if (video_type && (status & SS$_NORMAL))
                                scr_brwsbull(bull_lst, "", NEW);
                        else    lin_brwsbull(bull_lst, "", NEW);
                }
        }
}
