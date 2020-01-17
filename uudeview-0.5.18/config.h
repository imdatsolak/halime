/* config.h.in.  Generated automatically from configure.in by autoheader.  */

/* Define to `unsigned' if <sys/types.h> doesn't define.  */
/* #undef size_t */

/* Define if you have the ANSI C header files.  */
#define STDC_HEADERS 1

/* Define if you can safely include both <sys/time.h> and <time.h>.  */
#define TIME_WITH_SYS_TIME 1

/*
 * If your system is kinda special
 */
/* #undef SYSTEM_DOS */
/* #undef SYSTEM_QUICKWIN */
/* #undef SYSTEM_WINDLL */
/* #undef SYSTEM_OS2 */

/*
 * If your system has stdin/stdout/stderr
 */
/* #undef HAVE_STDIO */

/*
 * how to declare functions that are exported from the UU library
 */
#define UUEXPORT 

/*
 * how to declare functions that are exported from the UUTCL library
 */
#define UUTCLEXPORT 

/*
 * how to declare functions that are exported from the fptools library
 */
#define TOOLEXPORT 

/*
 * how to declare functions that are interfaced with TCL
 */
#define UUTCLFUNC 

/*
 * define if your compiler supports function prototypes
 */
#define PROTOTYPES 1

/*
 * define if you have TCL version 7.5 or later
 */
/* #undef HAVE_TCL */

/* 
 * define if you HAVE_TCL and TK version 4.1 or later 
 */
/* #undef HAVE_TK */

/*
 * define if Tcl_Main or Tk_Main needs Tcl_AppInit as third parameter 
 */
/* #undef TMAIN_THREE */

/*
 * Replacement functions.
 * #define strerror _FP_strerror
 * #define tempnam  _FP_tempnam
 * if you don't have these functions
 */
/* #undef strerror */
/* #undef tempnam */

/*
 * your system's directory separator (usually "/")
 */
#define DIRSEPARATOR "/"

/* 
 * your mailing program. full path and the necessary parameters.
 * the recepient address is added to the command line (with a leading
 * space) without any further options
 */
#define PROG_MAILER "/usr/sbin/sendmail"

/* 
 * define if the mailer needs to have the subject set on the command
 * line with -s "Subject". Preferredly, we send the subject as a header.
 */
/* #undef MAILER_NEEDS_SUBJECT */

/* 
 * define if posting is enabled. Do not edit.
 */
#define HAVE_NEWS 1

/*
 * your local news posting program. full path and parameters, so that
 * the article and all its headers are read from stdin
 */
#define PROG_INEWS "/usr/local/news/bin/inews -h"

/*
 * the name of your local domain. only needed when using minews
 */
/* #undef DOMAINNAME */

/* 
 * your local NNTP news server. only needed when using minews
 * can be overridden by $NNTPSERVER at runtime
 */
/* #undef NNTPSERVER */

/*
 * defined when we use minews, so that we know that we must define
 * the NNTPSERVER environment variable to be able to post
 */
/* #undef NEED_NNTPSERVER */

/* Define if you have the getcwd function.  */
#define HAVE_GETCWD 1

/* Define if you have the gettimeofday function.  */
#define HAVE_GETTIMEOFDAY 1

/* Define if you have the isatty function.  */
#define HAVE_ISATTY 1

/* Define if you have the popen function.  */
#define HAVE_POPEN 1

/* Define if you have the <direct.h> header file.  */
/* #undef HAVE_DIRECT_H */

/* Define if you have the <errno.h> header file.  */
#define HAVE_ERRNO_H 1

/* Define if you have the <fcntl.h> header file.  */
#define HAVE_FCNTL_H 1

/* Define if you have the <io.h> header file.  */
/* #undef HAVE_IO_H */

/* Define if you have the <malloc.h> header file.  */
/* #undef HAVE_MALLOC_H */

/* Define if you have the <memory.h> header file.  */
#define HAVE_MEMORY_H 1

/* Define if you have the <pwd.h> header file.  */
/* #undef HAVE_PWD_H */

/* Define if you have the <stdarg.h> header file.  */
/* #undef HAVE_STDARG_H */

/* Define if you have the <sys/time.h> header file.  */
#define HAVE_SYS_TIME_H 1

/* Define if you have the <unistd.h> header file.  */
#define HAVE_UNISTD_H 1

/* Define if you have the <varargs.h> header file.  */
/* #undef HAVE_VARARGS_H */
