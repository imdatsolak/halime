/*
 * Configuration file for nn version of nntp inews.  Written by
 * Steve Simmons (scs@lokkur.dexter.mi.us), Dec 19, 1989.  Placed
 * in the public domain by the author.  This file rationalizes
 * the stock NNTP release of inews with the definitions for NN.
 * The rationalization was done as of NN version 6.3.10 and NNTP
 * version 1.5.7.
 *
 * You must edit this file to reflect your local configuration
 * and environment.
 *
 * Follow the instructions given in the comments.  See the file
 * README for more comments.
 *
 * $RCSfile: conf.h,v $	$Revision: 1.1.1.1 $
 *
 * $Author: fp $	$Date: 1996/06/06 19:41:07 $
 *
 * $State: Exp $	$Locker:  $
 *
 * $Log: conf.h,v $
 * Revision 1.1.1.1  1996/06/06 19:41:07  fp
 * UUDeview put under revision control
 *
 * Revision 1.1  89/12/20  17:43:03  news
 * Initial revision
 *
 * May 1st, 1990, Kim Storm
 * Modifications to get hostname for free (see README.NN)
 */

#ifndef	NNINEWSCONF_H
#define	NNINEWSCONF_H

/* #include	"config.h" */
/*
 *  added by Montulli@ukanaix.cc.ukans.edu
 *  to replace the need for config.h
 */

#include <stdio.h>
#include <ctype.h>


/*
 *      Define NNTP_SERVER to the name of a file containing the name of the
 *      nntp server.
 *
 *      It is vital that both the nnmaster and all nn users on a machine
 *      uses the same nntp server, because the nn database is synchronized
 *      with a specific news active file.
 *
 *      If the file name does not start with a slash, it is relative to
 *      LIB_DIRECTORY defined below.
 *      NOTE: If you plan to use the included inews, it MUST be a full pathname
 */

#define NNTP_SERVER     "/usr/local/etc/nntpserver"
/* #define NNTP_SERVER     "/usr/lib/nntp_server" */


#ifndef NNTP
/* WHY DO YOU WANT TO MAKE MINI-INEWS WHEN YOU DONT USE NNTP */
#endif

/*
 *  Define your local domain name.  You *must* define something, either
 *  here, in config.h, or elsewhere according to your local standards.
 *  See comment below on HIDDENNET.
 *
 *  You are not strictly *required* to have a domain name; nonetheless
 *  it's a good idea.  If you are on the Internet or otherwise have a
 *  valid domain name, use it (except see HIDDENNET below).  If you're
 *  a uucp-only site, use ".uucp" for now and go get a real name.
 *
 *  Note that if you imbed your domain name in the hostname and you don't
 *  use HIDDENNET, you may get a period on the end of your fully qualified
 *  domian name (FQDN) in postings.  In that case, use HIDDENNET and
 *  define DOMAIN to be your FQDN.
 */

#ifndef DOMAIN
#define	DOMAIN	"UUEnview.Default.Domain" 
#endif

/*
 *  If you define this, the hostname will not appear in the posting
 *  data except on the path.  Items will be from user@DOMAIN (with
 *  DOMAIN as defined above).  If you don't want this, comment it out.
 */
#ifndef HIDDENNET
/* #define	HIDDENNET  1 */
#endif

/*
 *  You shouldn't need to touch anything below this line.
 */

/*
 *  This is the code needed to get the proper hostname.
 *
 *	nn provides a gethostname function for generic use.
 *	we fake uname() for inews.c using this:
 */

#define	uname(str) gethostname(str, sizeof(str))

/*
 *  Stock nntp inews and nn use some different #define names for the
 *  same general functions.  This synchronises them.
 */

#define	SERVER_FILE	NNTP_SERVER

/*
 *	Reverse engineering (nn got this the other way around)....
 */

/*
 *  Sanity checks (You know.  Checks you get from Sanity Claus)
 */

#ifdef	HIDDENNET
#ifndef	DOMAIN
YOU_BLEW_IT READ_THE_INSTRUCTIONS_AGAIN
#endif
#endif

#endif	/* of ifdef NNINEWSCONF_H */
