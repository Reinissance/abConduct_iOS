/* 
 * tparseabc.c - code to tparse an abc file. This file is used by the
 * following 3 programs :
 * abc2midi - program to convert abc files to MIDI files.
 * abc2abc  - program to manipulate abc files.
 * yaps     - program to convert abc to PostScript music files.
 * Copyright (C) 1999 James Allwright
 * e-mail: J.R.Allwright@westminster.ac.uk
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA
 *
 */


/* Macintosh port 30th July 1996 */
/* DropShell integration   27th Jan  1997 */
/* Wil Macaulay (wil@syndesis.com) */


#define TAB 9
#include "tabc.h"
#include "tparseabc.h"
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#import "utilities.h"

/* #define SIZE_ABBREVIATIONS ('Z' - 'H' + 1) [SS] 2016-09-20 */
#define SIZE_ABBREVIATIONS 58

/* [SS] 2015-09-28 changed _snprintf_s to _snprintf */
#ifdef _MSC_VER
#define snprintf _snprintf
#endif


#ifdef _MSC_VER
#define ANSILIBS
#define casecmp stricmp
#define _CRT_SECURE_NO_WARNINGS
#else
#define casecmp strcasecmp
#endif
#define	stringcmp	strcmp

#ifdef __MWERKS__
#define __MACINTOSH__ 1
#endif /* __MWERKS__ */

#ifdef __MACINTOSH__
#define main macabc2midi_main
#define STRCHR
#endif /* __MACINTOSH__ */

/* define USE_INDEX if your C libraries have index() instead of strchr() */
#ifdef USE_INDEX
#define strchr index
#endif

#ifdef ANSILIBS
#include <ctype.h>
#include <stdlib.h>
#include <string.h>
#else
//extern char *malloc ();
extern char *strchr ();
#endif

int tlineno;
int ttparsing_started = 0;
int tparsing, tslur;
int ignore_tline = 0; /* [SS] 2017-04-12 */
int tinhead, intbody;
int tparserinchord;
int ttingrace = 0;
int chordtdecorators[DECSIZE];
char tdecorations[] = ".MLRH~Tuv";
char *tabbreviation[SIZE_ABBREVIATIONS];

int tvoicecodes = 0;
/* [SS] 2015-03-16 allow 24 voices */
/*char tvoicecode[16][30];       for interpreting V: string */
char tvoicecode[24][30];		/*for interpreting V: string */

int tdecorators_passback[DECSIZE];
/* this global array is linked as an external to store.c and 
 * yaps.tree.c and is used to pass back decorator information
 * from event_instruction to tparsenote.
*/

char inputtline[512];		/* [SS] 2011-06-07 2012-11-22 */
char *tlinestart;		/* [SS] 2011-07-18 */
int tlineposition;		/* [SS] 2011-07-18 */
char ttimesigstring[16];		/* [SS] 2011-08-19 links with stresspat.c */

int tnokey = 0;			/* K: none was encountered */
int tnokeysig = 0;               /* links with toabc.c [SS] 2016-03-03 */
int tchord_n, tchord_m;		/* for event_chordoff */
int filetline_number = 1;
int tintune = 1;
int trinchordflag;		/* [SS] 2012-03-30 */
struct fraction settmicrotone;	/* [SS] 2014-01-07 */
int tmicrotone;			/* [SS] 2014-01-19 */


extern programname fileprogram;
int toldchordconvention = 0;
char * tabcversion = "2.0"; /* [SS] 2014-08-11 */
char tlastfieldcmd = ' '; /* [SS] 2014-08-15 */

char *tmode[10] = { "maj", "min", "m",
  "aeo", "loc", "ion", "dor", "phr", "lyd", "mix"
};

int tmodeshift[10] = { 0, -3, -3,
  -3, -5, 0, -2, -4, 1, -1
};

int tmodeminor[10] = { 0, 1, 1,
  1, 0, 0, 0, 0, 0, 0
};
int tmodekeyshift[10] = { 0, 5, 5, 5, 6, 0, 1, 2, 3, 4 };

int *
tcheckmalloc (bytes)
/* malloc with error checking */
     int bytes;
{
  int *p;

  p = (int *) malloc (bytes);
  if (p == NULL)
    {
      printf ("Out of memory error - malloc failed!\n");
      exit (0);
    };
  return (p);
}

char *
taddstring (s)
/* create space for string and store it in memory */
     char *s;
{
  char *p;

  p = (char *) tcheckmalloc (strlen (s) + 1);
  strcpy (p, s);
  return (p);
}

/* [SS] 2014-08-16 */
char * tconcatenatestring(s1,s2)
   char * s1;
   char * s2;
{  char *p;
  p = (char *) tcheckmalloc (strlen(s1) + strlen(s2) + 1);
  snprintf(p,sizeof p, "%s%s",s1,s2);
  return p;
}


void
inittvstring (s)
     struct vstring *s;
/* initialize vstring (variable length string data structure) */
{
  s->len = 0;
  s->limit = 40;
  s->st = (char *) tcheckmalloc (s->limit + 1);
  *(s->st) = '\0';
}

void
extendtvstring (s)
     struct vstring *s;
/* doubles character space available in string */
{
  char *p;

  if (s->limit > 0)
    {
      s->limit = s->limit * 2;
      p = (char *) tcheckmalloc (s->limit + 1);
      strcpy (p, s->st);
      free (s->st);
      s->st = p;
    }
  else
    {
      inittvstring (s);
    };
}

void
taddch (ch, s)
     char ch;
     struct vstring *s;
/* appends character to vstring structure */
{
  if (s->len >= s->limit)
    {
      extendtvstring (s);
    };
  *(s->st + s->len) = ch;
  *(s->st + (s->len) + 1) = '\0';
  s->len = (s->len) + 1;
}

void
taddtext (text, s)
     char *text;
     struct vstring *s;
/* appends a string to vstring data structure */
{
  int newlen;

  newlen = s->len + strlen (text);
  while (newlen >= s->limit)
    {
      extendtvstring (s);
    };
  strcpy (s->st + s->len, text);
  s->len = newlen;
}

void
cleartvstring (s)
     struct vstring *s;
/* set string to empty */
/* does not deallocate memory ! */
{
  *(s->st) = '\0';
  s->len = 0;
}

void
freetvstring (s)
     struct vstring *s;
/* deallocates memory allocated for string */
{
  if (s->st != NULL)
    {
      free (s->st);
      s->st = NULL;
    };
  s->len = 0;
  s->limit = 0;
}

void
tparseron ()
{
  tparsing = 1;
  tslur = 0;
  ttparsing_started = 1;
}

void
tparseroff ()
{
  tparsing = 0;
  tslur = 0;
}

/* [SS] 2017-04-12 */
void handle_abc2midi_tparser (tline)
char *tline;
{
char *p;
p = tline;
if (strncmp(p,"%%MidiOff",9) == 0) {
  ignore_tline = 1;
  printf("ignore_tline = 1\n");
  }
if (strncmp(p,"%%MidiOn",8) == 0) {
  ignore_tline = 0;
  printf("ignore_tline = 0\n");
  }
}


int
tgetarg (option, argc, argv)
/* look for argument 'option' in command tline */
     char *option;
     char *argv[];
     int argc;
{
  int j, place;

  place = -1;
  for (j = 0; j < argc; j++)
    {
      if (strcmp (option, argv[j]) == 0)
	{
	  place = j + 1;
	};
    };
  return (place);
}

void
tskipspace (p)
     char **p;
{
  /* skip space and tab */
  while (((int) **p == ' ') || ((int) **p == TAB))
    *p = *p + 1;
}

void
tskiptospace (p)
     char **p;
{
  while (((int) **p != ' ') && ((int) **p != TAB) && (int) **p != '\0')
    *p = *p + 1;
}


int
tisnumberp (p)
     char **p;
/* returns 1 if positive number, returns 0 if not a positive number */
/* ie -4 or 1A both return 0. This function is needed to get the    */
/* voice number.                                                    */
{
  char **c;
  c = p;
  while (( **c != ' ') && ( **c != TAB) &&  **c != '\0')
    {
      if (( *c >= 0) &&  (*c <= 9))
	*c = *c + 1;
      else
	return 0;
    }
  return 1;
}



int
readtnumf (num)
     char *num;
/* read integer from string without advancing character pointer */
{
  int t;
  char *p;

  p = num;
  if (!isdigit (*p))
    {
      tevent_error ("Missing Number");
    };
  t = 0;
  while (((int) *p >= '0') && ((int) *p <= '9'))
    {
      t = t * 10 + (int) *p - '0';
      p = p + 1;
    };
  return (t);
}

int
readstnumf (s)
     char *s;
/* reads signed integer from string without advancing character pointer */
{
  char *p;

  p = s;
  if (*p == '-')
    {
      p = p + 1;
      tskipspace (&p);
      return (-readtnumf (p));
    }
  else
    {
      return (readtnumf (p));
    }
}

int
readtnump (p)
     char **p;
/* read integer from string and advance character pointer */
{
  int t;

  t = 0;
  while (((int) **p >= '0') && ((int) **p <= '9'))
    {
      t = t * 10 + (int) **p - '0';
      *p = *p + 1;
    };
  return (t);
}

int
readstnump (p)
     char **p;
/* reads signed integer from string and advance character pointer */
{
  if (**p == '-')
    {
      *p = *p + 1;
      tskipspace (p);
      return (-readtnump (p));
    }
  else
    {
      return (readtnump (p));
    }
}

void
treadsig (a, b, sig)
     int *a, *b;
     char **sig;
/* read time signature (meter) from M: field */
{
  int t;
  char c; /* [SS] 2015-08-19 */

  /* [SS] 2012-08-08  cut time (C| or c|) is 2/2 not 4/4 */
  if ((*(*sig + 1) == '|') && ((**sig == 'C') || (**sig == 'c')))
    {
      *a = 2;
      *b = 2;
      return;
    }

  if ((**sig == 'C') || (**sig == 'c'))
    {
      *a = 4;
      *b = 4;
      return;
    };
  *a = readtnump (sig);

  /* [SS] 2015-08-19 */
  while ((int) **sig == '+') {
    *sig = *sig + 1;
    c = readtnump (sig);
    *a = *a + c;
    }

  if ((int) **sig != '/')
    {
      tevent_error ("Missing / ");
    }
  else
    {
      *sig = *sig + 1;
    };
  *b = readtnump (sig);
  if ((*a == 0) || (*b == 0))
    {
      tevent_error ("Expecting fraction in form A/B");
    }
  else
    {
      t = *b;
      while (t > 1)
	{
	  if (t % 2 != 0)
	    {
	      tevent_error ("divisor must be a power of 2");
	      t = 1;
	      *b = 0;
	    }
	  else
	    {
	      t = t / 2;
	    };
	};
    };
}

void
treadlen (a, b, p)
     int *a, *b;
     char **p;
/* read length part of a note and advance character pointer */
{
  int t;

  *a = readtnump (p);
  if (*a == 0)
    {
      *a = 1;
    };
  *b = 1;
  if (**p == '/')
    {
      *p = *p + 1;
      *b = readtnump (p);
      if (*b == 0)
	{
	  *b = 2;
	  while (**p == '/')
	    {
	      *b = *b * 2;
	      *p = *p + 1;
	    };
	};
    };
  t = *b;
  while (t > 1)
    {
      if (t % 2 != 0)
	{
	  tevent_warning ("divisor not a power of 2");
	  t = 1;
	}
      else
	{
	  t = t / 2;
	};
    };
}

void
treadlen_nocheck (a, b, p)
     int *a, *b;
     char **p;
/* read length part of a note and advance character pointer */
{
  int t;

  *a = readtnump (p);
  if (*a == 0)
    {
      *a = 1;
    };
  *b = 1;
  if (**p == '/')
    {
      *p = *p + 1;
      *b = readtnump (p);
      if (*b == 0)
	{
	  *b = 2;
	  while (**p == '/')
	    {
	      *b = *b * 2;
	      *p = *p + 1;
	    };
	};
    };
  t = *b;
  while (t > 1)
    {
      if (t % 2 != 0)
	{
	  /*event_warning("divisor not a power of 2"); */
	  t = 1;
	}
      else
	{
	  t = t / 2;
	};
    };
}

int
istmicrotone (p, dir)
     char **p;
     int dir;
{
  int a, b;
  treadlen_nocheck (&a, &b, p);
  if (b != 1)
    {
      tevent_microtone (dir, a, b);
      return 1;
    }
  settmicrotone.num = 0;
  settmicrotone.denom = 0;
  return 0;
}




int
tisclef (s, gotoctave, octave, strict)
     char *s;
     int *gotoctave, *octave;
     int strict;
/* part of K: tparsing - looks for a clef in K: field                 */
/* format is K:string where string is treble, bass, baritone, tenor, */
/* alto, mezzo, soprano or K:clef=arbitrary                          */
{
  int gotclef;

  s = s;
  gotclef = 0;
  if (strncmp (s, "bass", 4) == 0)
    {
      gotclef = 1;
    };
  if (strncmp (s, "treble", 6) == 0)
    {
      gotclef = 1;
      if (fileprogram == ABC2MIDI && *gotoctave != 1 && *octave != 1)
        {
        /* [SS] 2015-07-02 */
	tevent_warning ("clef= is overriding octave= setting");
        *gotoctave = 1;		/* [SS] 2011-12-19 */
        *octave = 0;
        }
    };
  if (strncmp (s, "treble+8", 8) == 0)
    {
      gotclef = 1;
      if (fileprogram == ABC2MIDI && *gotoctave != 1 && *octave != 1)
        {
	tevent_warning ("clef= is overriding octave= setting");
        /* [SS] 2015-07-02 */
        *gotoctave = 1;
        *octave = 1;
        }
    };
  if (strncmp (s, "treble-8", 8) == 0)
    {
      gotclef = 1;
      if (fileprogram == ABC2MIDI && *gotoctave == 1 && *octave != -1)
        {
	tevent_warning ("clef= is overriding octave= setting");
        *gotoctave = 1;
        *octave = -1;
        }
    };
  if (strncmp (s, "baritone", 8) == 0)
    {
      gotclef = 1;
    };
  if (strncmp (s, "tenor", 5) == 0)
    {
      gotclef = 1;
    };
  if (strncmp (s, "tenor-8", 7) == 0)
    {
      gotclef = 1;
      if (fileprogram == ABC2MIDI && *gotoctave == 1 && *octave != -1) {
	tevent_warning ("clef= is overriding octave= setting");
        *gotoctave = 1;
        *octave = -1;
        }
    };
  if (strncmp (s, "alto", 4) == 0)
    {
      gotclef = 1;
    };
  if (strncmp (s, "mezzo", 5) == 0)
    {
      gotclef = 1;
    };
  if (strncmp (s, "soprano", 7) == 0)
    {
      gotclef = 1;
    };
/*
 * only clef=F or clef=f is allowed, or else
 * we get a conflict with the key signature
 * indication K:F
*/

  if (strncmp (s, "f", 1) == 0 && strict == 0)
    {
      gotclef = 1;
    }
  if (strncmp (s, "F", 1) == 0 && strict == 0)
    {
      gotclef = 1;
    }
  if (strncmp (s, "g", 1) == 0 && strict == 0)
    {
      gotclef = 1;
    }
  if (strncmp (s, "G", 1) == 0 && strict == 0)
    {
      gotclef = 1;
    }
  if (strncmp (s, "perc", 1) == 0 && strict == 0)
    {
      gotclef = 1;
    }				/* [SS] 2011-04-17 */

  if (!strict && !gotclef)
    {
      gotclef = 1;
      tevent_warning ("cannot recognize clef indication");
    }

  return (gotclef);
}



char *
treadword (word, s)
/* part of tparsekey, extracts word from input tline */
/* besides the space, the symbols _, ^, and = are used */
/* as separators in order to handle key signature modifiers. */
/* [SS] 2010-05-24 */
     char word[];
     char *s;
{
  char *p;
  int i;

  p = s;
  i = 0;
  /* [SS] 2015-04-08 */
  while ((*p != '\0') && (*p != ' ') && (*p != '\t') && ((i == 0) ||
							 ((*p != '='))))
    {
    if (i >1 && *p == '^') break; /* allow for double sharps and flats */
    if (i >1 && *p == '_') break;
      if (i < 29)
	{
	  word[i] = *p;
	  i = i + 1;
	};
      p = p + 1;
    };
  word[i] = '\0';
  return (p);
}

void
tlcase (s)
/* convert word to lower case */
     char *s;
{
  char *p;

  p = s;
  while (*p != '\0')
    {
      if (isupper (*p))
	{
	  *p = *p + 'a' - 'A';
	};
      p = p + 1;
    };
}


void
init_tvoicecode ()
{
  int i;
  for (i = 0; i < 24; i++) /* [SS} 2015-03-15 */
    tvoicecode[i][0] = 0;
  tvoicecodes = 0;
}

void
print_tvoicecodes ()
{
  int i;
  if (tvoicecodes == 0)
    return;
  printf ("voice mapping:\n");
  for (i = 0; i < tvoicecodes; i++)
    {
      if (i % 4 == 3)
	printf ("\n");
      printf ("%s  %d   ", tvoicecode[i], i + 1);
    }
  printf ("\n");
}

int
tinterpret_voicestring (char *s)
{
/* if V: is followed  by a string instead of a number
 * we check to see if we have encountered this string
 * before. We assign the number associated with this
 * string and add it to tvoicecode if it was not encountered
 * before. If more than 16 distinct strings were encountered
 * we report an error -1.
*/
  int i;
  char code[32];
  char msg[80];			/* [PHDM] 2012-11-22 */
  char *c;
  c = treadword (code, s);

/* [PHDM] 2012-11-22 */
  if (*c != '\0' && *c != ' ' && *c != ']')
    {
      sprintf (msg, "invalid character `%c' in Voice ID", *c);
      tevent_error (msg);
    }
/* [PHDM] 2012-11-22 */

  if (code[0] == '\0')
    return 0;
  if (tvoicecodes == 0)
    {
      strcpy (tvoicecode[tvoicecodes], code);
      tvoicecodes++;
      return tvoicecodes;
    }
  for (i = 0; i < tvoicecodes; i++)
    if (stringcmp (code, tvoicecode[i]) == 0)
      return (i + 1);
  if ((tvoicecodes + 1) > 23) /* [SS] 2015-03-16 */
    return -1;
  strcpy (tvoicecode[tvoicecodes], code);
  tvoicecodes++;
  return tvoicecodes;
}

/* The following three functions tparseclefs, tparsettranspose,
 * tparseoctave are used to tparse the K: field which not
 * only specifies the key signature but also other descriptors
 * used for producing a midi file or postscript file.
 *
 * The char* word contains the particular token that
 * is being interpreted. If the token can be understood,
 * other parameters are extracted from char ** s and
 * s is advanced to point to the next token.
 */

int
tparseclef (s, word, gotclef, clefstr, gotoctave, octave)
     char **s;
     char *word;
     int *gotclef;
     char *clefstr;
     int *gotoctave, *octave;
/* extracts string clef= something */
{
  int successful;
  tskipspace (s);
  *s = treadword (word, *s);
  successful = 0;
  if (casecmp (word, "clef") == 0)
    {
      tskipspace (s);
      if (**s != '=')
	{
	  tevent_error ("clef must be followed by '='");
	}
      else
	{
	  *s = *s + 1;
	  tskipspace (s);
	  *s = treadword (clefstr, *s);
	  if (tisclef (clefstr, gotoctave, octave, 0))
	    {
	      *gotclef = 1;
	    };
	};
      successful = 1;
    }
  else if (tisclef (word, gotoctave, octave, 1))
    {
      *gotclef = 1;
      strcpy (clefstr, word);
      successful = 1;
    };
  return successful;
}


int
tparsettranspose (s, word, gotttranspose, ttranspose)
/* tparses string ttranspose= number */
     char **s;
     char *word;
     int *gotttranspose;
     int *ttranspose;
{
  if (casecmp (word, "ttranspose") != 0)
    return 0;
  tskipspace (s);
  if (**s != '=')
    {
      tevent_error ("ttranspose must be followed by '='");
    }
  else
    {
      *s = *s + 1;
      tskipspace (s);
      *ttranspose = readstnump (s);
      *gotttranspose = 1;
    };
  return 1;
};


int
tparseoctave (s, word, gotoctave, octave)
/* tparses string octave= number */
     char **s;
     char *word;
     int *gotoctave;
     int *octave;
{
  if (casecmp (word, "octave") != 0)
    return 0;
  tskipspace (s);
  if (**s != '=')
    {
      tevent_error ("octave must be followed by '='");
    }
  else
    {
      *s = *s + 1;
      tskipspace (s);
      *octave = readstnump (s);
      *gotoctave = 1;
    };
  return 1;
};


int
tparsename (s, word, gotname, namestring, maxsize)
/* tparses string name= "string" in V: command
   for compatability of abc2abc with abcm2ps
*/
     char **s;
     char *word;
     int *gotname;
     char namestring[];
     int maxsize;
{
  int i;
  i = 0;
  if (casecmp (word, "name") != 0)
    return 0;
  tskipspace (s);
  if (**s != '=')
    {
      tevent_error ("name must be followed by '='");
    }
  else
    {
      *s = *s + 1;
      tskipspace (s);
      if (**s == '"')		/* string enclosed in double quotes */
	{
	  namestring[i] = (char) **s;
	  *s = *s + 1;
	  i++;
	  while (i < maxsize && **s != '"' && **s != '\0')
	    {
	      namestring[i] = (char) **s;
	      *s = *s + 1;
	      i++;
	    }
	  namestring[i] = (char) **s;	/* copy double quotes */
	  i++;
	  namestring[i] = '\0';
	}
      else			/* string not enclosed in double quotes */
	{
	  while (i < maxsize && **s != ' ' && **s != '\0')
	    {
	      namestring[i] = (char) **s;
	      *s = *s + 1;
	      i++;
	    }
	  namestring[i] = '\0';
	}
      *gotname = 1;
    }
  return 1;
};

int
tparsesname (s, word, gotname, namestring, maxsize)
/* tparses string name= "string" in V: command
   for compatability of abc2abc with abcm2ps
*/
     char **s;
     char *word;
     int *gotname;
     char namestring[];
     int maxsize;
{
  int i;
  i = 0;
  if (casecmp (word, "sname") != 0)
    return 0;
  tskipspace (s);
  if (**s != '=')
    {
      tevent_error ("name must be followed by '='");
    }
  else
    {
      *s = *s + 1;
      tskipspace (s);
      if (**s == '"')		/* string enclosed in double quotes */
	{
	  namestring[i] = (char) **s;
	  *s = *s + 1;
	  i++;
	  while (i < maxsize && **s != '"' && **s != '\0')
	    {
	      namestring[i] = (char) **s;
	      *s = *s + 1;
	      i++;
	    }
	  namestring[i] = (char) **s;	/* copy double quotes */
	  i++;
	  namestring[i] = '\0';
	}
      else			/* string not enclosed in double quotes */
	{
	  while (i < maxsize && **s != ' ' && **s != '\0')
	    {
	      namestring[i] = (char) **s;
	      *s = *s + 1;
	      i++;
	    }
	  namestring[i] = '\0';
	}
      *gotname = 1;
    }
  return 1;
};

int
tparsemiddle (s, word, gotmiddle, middlestring, maxsize)
/* tparse string middle=X in V: command
 for abcm2ps compatibility
*/
     char **s;
     char *word;
     int *gotmiddle;
     char middlestring[];
     int maxsize;
{
  int i;
  i = 0;
  if (casecmp (word, "middle") != 0)
    return 0;
  tskipspace (s);
  if (**s != '=')
    {
      tevent_error ("middle must be followed by '='");
    }
  else
    {
      *s = *s + 1;
      tskipspace (s);
/* we really ought to check the we have a proper note name; for now, just copy non-space
characters */
      while (i < maxsize && **s != ' ' && **s != '\0')
	{
	  middlestring[i] = (char) **s;
	  *s = *s + 1;
	  ++i;
	}
      middlestring[i] = '\0';
      *gotmiddle = 1;
    }
  return 1;
}

int
tparseother (s, word, gotother, other, maxsize)	/* [SS] 2011-04-18 */
/* tparses any left overs in V: command (eg. stafftlines=1) */
     char **s;
     char *word;
     int *gotother;
     char other[];
     int maxsize;
{
  if (word[0] != '\0')
    {
      if ( (int) strlen (other) < maxsize) /* [SS] 2015-10-08 added (int) */
	strncat (other, word, maxsize);
      if (**s == '=')
	{			/* [SS] 2011-04-19 */
	  *s = treadword (word, *s);
	  if ( (int) strlen (other) < maxsize) /* [SS] 2015-10-08 added (int) */
	    strncat (other, word, maxsize);
	}
      strncat (other, " ", maxsize);	/* in case other codes follow */
      *gotother = 1;
      return 1;
    }
  return 0;
}

int
tparsekey (str)
/* tparse contents of K: field */
/* this works by picking up a strings and trying to tparse them */
/* returns 1 if valid key signature found, 0 otherwise */
     char *str;
{
  char *s;
  char word[30];
  int tparsed;
  int gotclef, gotkey, gotoctave, gotttranspose;
  int explict;			/* [SS] 2010-05-08 */
  int modnotes;			/* [SS] 2010-07-29 */
  int foundtmode;
  int ttranspose, octave;
  char clefstr[30];
  char tmodestr[30];
  char msg[80];
  char *moveon;
  int sf = -1, minor = -1;
  char modmap[7];
  int modmul[7];
  struct fraction modtmicrotone[7];
  int i, j;
  int cgotoctave, coctave;
  char *key = "FCGDAEB";
  int tmodeindex;
  int a, b;			/* for tmicrotones [SS] 2014-01-06 */
  int success;
  char c;

  clefstr[0] = (char) 0;
  tmodestr[0] = (char) 0;
  s = str;
  ttranspose = 0;
  gotttranspose = 0;
  octave = 0;
  gotkey = 0;
  gotoctave = 0;
  gotclef = 0;
  cgotoctave = 0;
  coctave = 0;
  tmodeindex = 0;
  explict = 0;
  modnotes = 0;
  tnokey = tnokeysig; /* [SS] 2016-03-03 */
  for (i = 0; i < 7; i++)
    {
      modmap[i] = ' ';
      modmul[i] = 1;
      modtmicrotone[i].num = 0;	/* [SS] 2014-01-06 */
      modtmicrotone[i].denom = 0;
    };
  while (*s != '\0')
    {
      tparsed = tparseclef (&s, word, &gotclef, clefstr, &cgotoctave, &coctave);
      /* tparseclef also scans the s string using readword(), placing */
      /* the next token  into the char array word[].                   */
      if (!tparsed)
	tparsed = tparsettranspose (&s, word, &gotttranspose, &ttranspose);

      if (!tparsed)
	tparsed = tparseoctave (&s, word, &gotoctave, &octave);

      if ((tparsed == 0) && (casecmp (word, "Hp") == 0))
	{
	  sf = 2;
	  minor = 0;
	  gotkey = 1;
	  tparsed = 1;
	};

      if ((tparsed == 0) && (casecmp (word, "none") == 0))
	{
	  gotkey = 1;
	  tparsed = 1;
	  tnokey = 1;
	  minor = 0;
	  sf = 0;
	}

      if (casecmp (word, "exp") == 0)
	{
	  explict = 1;
	  tparsed = 1;
	}

      if ((tparsed == 0) && ((word[0] >= 'A') && (word[0] <= 'G')))
	{
	  gotkey = 1;
	  tparsed = 1;
	  /* tparse key itself */
	  sf = strchr (key, word[0]) - key - 1;
	  j = 1;
	  /* deal with sharp/flat */
	  if (word[1] == '#')
	    {
	      sf += 7;
	      j = 2;
	    }
	  else
	    {
	      if (word[1] == 'b')
		{
		  sf -= 7;
		  j = 2;
		};
	    }
	  minor = 0;
	  foundtmode = 0;
	  if ((int) strlen (word) == j)
	    {
	      /* look at next word for tmode */
	      tskipspace (&s);
	      moveon = treadword (tmodestr, s);
	      tlcase (tmodestr);
	      for (i = 0; i < 10; i++)
		{
		  if (strncmp (tmodestr, tmode[i], 3) == 0)
		    {
		      foundtmode = 1;
		      sf = sf + tmodeshift[i];
		      minor = tmodeminor[i];
		      tmodeindex = i;
		    };
		};
	      if (foundtmode)
		{
		  s = moveon;
		};
	    }
	  else
	    {
	      strcpy (tmodestr, &word[j]);
	      tlcase (tmodestr);
	      for (i = 0; i < 10; i++)
		{
		  if (strncmp (tmodestr, tmode[i], 3) == 0)
		    {
		      foundtmode = 1;
		      sf = sf + tmodeshift[i];
		      minor = tmodeminor[i];
		      tmodeindex = i;
		    };
		};
	      if (!foundtmode)
		{
		  sprintf (msg, "Unknown tmode '%s'", &word[j]);
		  tevent_error (msg);
		  tmodeindex = 0;
		};
	    };
	};
      if (gotkey)
	{
	  if (sf > 7)
	    {
	      tevent_warning ("Unusual key representation");
	      sf = sf - 12;
	    };
	  if (sf < -7)
	    {
	      tevent_warning ("Unusual key representation");
	      sf = sf + 12;
	    };
	};
      if ((word[0] == '^') || (word[0] == '_') || (word[0] == '='))
	{
	  modnotes = 1;
	  if ((strlen (word) == 2) && (word[1] >= 'a') && (word[1] <= 'g'))
	    {
	      j = (int) word[1] - 'a';
	      modmap[j] = word[0];
	      modmul[j] = 1;
	      tparsed = 1;
	    }
	  else
	    {			/*double sharp or double flat */
	      if ((strlen (word) == 3) && (word[0] != '=')
		  && (word[0] == word[1]) && (word[2] >= 'a')
		  && (word[2] <= 'g'))
		{
		  j = (int) word[2] - 'a';
		  modmap[j] = word[0];
		  modmul[j] = 2;
		  tparsed = 1;
		};
	    };
	};

/*   if (explict)  for compatibility with abcm2ps 2010-05-08  2010-05-20 */
      if ((word[0] == '^') || (word[0] == '_') || (word[0] == '='))
	{
	  modnotes = 1;
	  if ((strlen (word) == 2) && (word[1] >= 'A') && (word[1] <= 'G'))
	    {
	      j = (int) word[1] - 'A';
	      modmap[j] = word[0];
	      modmul[j] = 1;
	      tparsed = 1;
	    }
	  else if		/*double sharp or double flat */
	    ((strlen (word) == 3) && (word[0] != '=') && (word[0] == word[1])
	     && (word[2] >= 'A') && (word[2] <= 'G'))
	    {
	      j = (int) word[2] - 'A';
	      modmap[j] = word[0];
	      modmul[j] = 2;
	      tparsed = 1;
	    };
	  /* tmicrotone? */
	  success = sscanf (&word[1], "/%d%c", &b, &c);
	  if (success == 2) /* [SS] 2016-04-10 */
	    a = 1;
	  else
	    success = sscanf (&word[1], "%d/%d%c", &a, &b, &c);
	  if (success == 3) /* [SS] 2016-04-10 */
	    {
	      tparsed = 1;
	      j = (int) c - 'A';
              if (j > 7) j = (int) c - 'a';
              if (j > 7 || j < 0) {printf("invalid j = %d\n",j); exit(-1);}
	      if (word[0] == '_')
		a = -a;
	      /*printf("a/b = %d/%d for %c\n",a,b,c);*/ 
	      modmap[j] = word[0];
	      modtmicrotone[j].num = a;
	      modtmicrotone[j].denom = b;
	    }
	}
    }
  if ((tparsed == 0) && (strlen (word) > 0))
    {
      sprintf (msg, "Ignoring string '%s' in K: field", word);
      tevent_warning (msg);
    };
  if (cgotoctave)
    {
      gotoctave = 1;
      octave = coctave;
    }
  if (modnotes & !gotkey)
    {				/*[SS] 2010-07-29 for explicit key signature */
      sf = 0;
      /*gotkey = 1; [SS] 2010-07-29 */
      explict = 1;		/* [SS] 2010-07-29 */
    }
  tevent_key (sf, str, tmodeindex, modmap, modmul, modtmicrotone, gotkey,
	     gotclef, clefstr, octave, ttranspose, gotoctave, gotttranspose,
	     explict);
  return (gotkey);
}


void
tparsevoice (s)
     char *s;
{
  int num;			/* voice number */
  struct voice_params vparams;
  char word[30];
  int tparsed;
  int coctave, cgotoctave;

  vparams.ttranspose = 0;
  vparams.gotttranspose = 0;
  vparams.octave = 0;
  vparams.gotoctave = 0;
  vparams.gotclef = 0;
  cgotoctave = 0;
  coctave = 0;
  vparams.gotname = 0;
  vparams.gotsname = 0;
  vparams.gotmiddle = 0;
  vparams.gotother = 0;		/* [SS] 2011-04-18 */
  vparams.other[0] = '\0';	/* [SS] 2011-04-18 */

  tskipspace (&s);
  if (tisnumberp (&s) == 1)
    {
      num = readtnump (&s);
    }
  else
    {
      num = tinterpret_voicestring (s);
      if (num == 0)
	tevent_error ("No voice number or string in V: field");
      if (num == -1)
	{
	  tevent_error ("More than 16 voices encountered in V: fields");
	  num = 0;
	}
      tskiptospace (&s);
    };
  tskipspace (&s);
  while (*s != '\0')
    {
      tparsed =
	tparseclef (&s, word, &vparams.gotclef, vparams.clefname, &cgotoctave,
		   &coctave);
      if (!tparsed)
	tparsed =
	  tparsettranspose (&s, word, &vparams.gotttranspose,
			  &vparams.ttranspose);
      if (!tparsed)
	tparsed = tparseoctave (&s, word, &vparams.gotoctave, &vparams.octave);
      if (!tparsed)
	tparsed =
	  tparsename (&s, word, &vparams.gotname, vparams.namestring,
		     V_STRLEN);
      if (!tparsed)
	tparsed =
	  tparsesname (&s, word, &vparams.gotsname, vparams.snamestring,
		      V_STRLEN);
      if (!tparsed)
	tparsed =
	  tparsemiddle (&s, word, &vparams.gotmiddle, vparams.middlestring,
		       V_STRLEN);
      if (!tparsed)
	tparsed = tparseother (&s, word, &vparams.gotother, vparams.other, V_STRLEN);	/* [SS] 2011-04-18 */
    }
  /* [SS] 2015-05-13 allow octave= to change the clef= octave setting */
  /* cgotoctave may be set to 1 by a clef=. vparams.gotoctave is set  */
  /* by octave= */

  if (cgotoctave && vparams.gotoctave == 0)
    {
      vparams.gotoctave = 1;
      vparams.octave = coctave;
    }
  tevent_voice (num, s, &vparams);

/*
if (gotttranspose) printf("ttranspose = %d\n", vparams.ttranspose);
 if (gotoctave) printf("octave= %d\n", vparams.octave);
 if (gotclef) printf("clef= %s\n", vparams.clefstr);
if (gotname) printf("tparsevoice: name= %s\n", vparams.namestring);
if(gotmiddle) printf("tparsevoice: middle= %s\n", vparams.middlestring);
*/
}


void
tparsenote (s)
     char **s;
/* tparse abc note and advance character pointer */
{
  int tdecorators[DECSIZE];
  int i, t;
  int mult;
  char accidental, note;
  int octave, n, m;
  char msg[80];

  mult = 1;
  tmicrotone = 0;
  accidental = ' ';
  note = ' ';
  for (i = 0; i < DECSIZE; i++)
    {
      tdecorators[i] = tdecorators_passback[i];
      if (!trinchordflag)
	tdecorators_passback[i] = 0;	/* [SS] 2012-03-30 */
    }
  while (strchr (tdecorations, **s) != NULL)
    {
      t = strchr (tdecorations, **s) - tdecorations;
      tdecorators[t] = 1;
      *s = *s + 1;
    };
  /*check for decorated chord */
  if (**s == '[')
    {
      tlineposition = *s - tlinestart;	/* [SS] 2011-07-18 */
      if (fileprogram == YAPS)
	tevent_warning ("decorations applied to chord");
      for (i = 0; i < DECSIZE; i++)
	chordtdecorators[i] = tdecorators[i];
      tevent_chordon (chordtdecorators);
      if (fileprogram == ABC2ABC)
	for (i = 0; i < DECSIZE; i++)
	  tdecorators[i] = 0;
      tparserinchord = 1;
      *s = *s + 1;
      tskipspace (s);
    };
  if (tparserinchord)
    {
      /* inherit decorators */
      if (fileprogram != ABC2ABC)
	for (i = 0; i < DECSIZE; i++)
	  {
	    tdecorators[i] = tdecorators[i] | chordtdecorators[i];
	  };
    };

/* [SS] 2011-12-08 to catch fermata H followed by a rest */

  if (**s == 'z')
    {
      *s = *s + 1;
      treadlen (&n, &m, s);
      tevent_rest (tdecorators, n, m, 0);
      return;
    }
  if (**s == 'x')
    {
      *s = *s + 1;
      treadlen (&n, &m, s);
      tevent_rest (tdecorators, n, m, 1);
      return;
    }

  /* read accidental */
  switch (**s)
    {
    case '_':
      accidental = **s;
      *s = *s + 1;
      if (**s == '_')
	{
	  *s = *s + 1;
	  mult = 2;
	};
      tmicrotone = istmicrotone (s, -1);
      if (tmicrotone)
	{
	  if (mult == 2)
	    mult = 1;
	  else
	    accidental = ' ';
	}
      break;
    case '^':
      accidental = **s;
      *s = *s + 1;
      if (**s == '^')
	{
	  *s = *s + 1;
	  mult = 2;
	};
      tmicrotone = istmicrotone (s, 1);
      if (tmicrotone)
	{
	  if (mult == 2)
	    mult = 1;
	  else
	    accidental = ' ';
	}

      break;
    case '=':
      accidental = **s;
      *s = *s + 1;
      /* if ((**s == '^') || (**s == '_')) {
         accidental = **s;
         }; */
      if (**s == '^')
	{
	  accidental = **s;
	  *s = *s + 1;
	  tmicrotone = istmicrotone (s, 1);
	  if (tmicrotone == 0)
	    accidental = '^';
	}
      else if (**s == '_')
	{
	  accidental = **s;
	  *s = *s + 1;
	  tmicrotone = istmicrotone (s, -1);
	  if (tmicrotone == 0)
	    accidental = '_';
	}
      break;
    default:
      tmicrotone = istmicrotone (s, 1);		/* [SS] 2014-01-19 */
      break;
    };
  if ((**s >= 'a') && (**s <= 'g'))
    {
      note = **s;
      octave = 1;
      *s = *s + 1;
      while ((**s == '\'') || (**s == ','))
	{
	  if (**s == '\'')
	    {
	      octave = octave + 1;
	      *s = *s + 1;
	    };
	  if (**s == ',')
	    {
	      sprintf (msg, "Bad pitch specifier , after note %c", note);
	      tevent_error (msg);
	      octave = octave - 1;
	      *s = *s + 1;
	    };
	};
    }
  else
    {
      octave = 0;
      if ((**s >= 'A') && (**s <= 'G'))
	{
	  note = **s + 'a' - 'A';
	  *s = *s + 1;
	  while ((**s == '\'') || (**s == ','))
	    {
	      if (**s == ',')
		{
		  octave = octave - 1;
		  *s = *s + 1;
		};
	      if (**s == '\'')
		{
		  sprintf (msg, "Bad pitch specifier ' after note %c",
			   note + 'A' - 'a');
		  tevent_error (msg);
		  octave = octave + 1;
		  *s = *s + 1;
		};
	    };
	};
    };
  if (note == ' ')
    {
      tevent_error ("Malformed note : expecting a-g or A-G");
    }
  else
    {
      treadlen (&n, &m, s);
      tevent_note (tdecorators, accidental, mult, note, octave, n, m);
      if (!tmicrotone)
	tevent_normal_tone ();	/* [SS] 2014-01-09 */
    };
}

char *
tgetrep (p, out)
     char *p;
     char *out;
/* look for number or list following [ | or :| */
{
  char *q;
  int digits;
  int done;
  int count;

  q = p;
  count = 0;
  done = 0;
  digits = 0;
  while (!done)
    {
      if (isdigit (*q))
	{
	  out[count] = *q;
	  count = count + 1;
	  q = q + 1;
	  digits = digits + 1;
	  /* [SS] 2013-04-21 */
	  if (count > 50)
	    {
	      tevent_error ("malformed repeat");
	      break;
	    }
	}
      else
	{
	  if (((*q == '-') || (*q == ',')) && (digits > 0)
	      && (isdigit (*(q + 1))))
	    {
	      out[count] = *q;
	      count = count + 1;
	      q = q + 1;
	      digits = 0;
	      /* [SS] 2013-04-21 */
	      if (count > 50)
		{
		  tevent_error ("malformed repeat");
		  break;
		}
	    }
	  else
	    {
	      done = 1;
	    };
	};
    };
  out[count] = '\0';
  return (q);
}

int
tcheckend (s)
     char *s;
/* returns 1 if we are at the end of the tline 0 otherwise */
/* used when we encounter '\' '*' or other special tline end characters */
{
  char *p;
  int atend;

  p = s;
  tskipspace (&p);
  if (*p == '\0')
    {
      atend = 1;
    }
  else
    {
      atend = 0;
    };
  return (atend);
}

void
treadstr (out, in, limit)
     char out[];
     char **in;
     int limit;
/* copy across alpha string */
{
  int i;

  i = 0;
  while ((isalpha (**in)) && (i < limit - 1))
    {
      out[i] = **in;
      i = i + 1;
      *in = *in + 1;
    };
  out[i] = '\0';
}

/* [SS] 2015-06-01 required for tparse_mididef() in store.c */
/* Just like readstr but also allows anything except white space */
int treadaln (out, in, limit)
     char out[];
     char **in;
     int limit;
/* copy across alphanumeric string */
{
  int i;

  i = 0;
  while ((!isspace (**in)) && (**in) != 0 && (i < limit - 1))
    {
      out[i] = **in;
      i = i + 1;
      *in = *in + 1;
    };
  out[i] = '\0';
  return i;
}

void
tparse_precomment (s)
     char *s;
/* handles a comment field */
{
  char package[40];
  char *p;
  int success;

  success = sscanf (s, "%%abc-version %s", &tabcversion); /* [SS] 2014-08-11 */
  if (*s == '%')
    {
      p = s + 1;
      treadstr (package, &p, 40);
      tevent_specific (package, p);
    }
  else
    {
      tevent_comment (s);
    };
}

void
tparse_tempo (place)
     char *place;
/* tparse tempo descriptor i.e. Q: field */
{
  char *p;
  int a, b;
  int n;
  int relative;
  char *pre_string;
  char *post_string;

  relative = 0;
  p = place;
  pre_string = NULL;
  if (*p == '"')
    {
      p = p + 1;
      pre_string = p;
      while ((*p != '"') && (*p != '\0'))
	{
	  p = p + 1;
	};
      if (*p == '\0')
	{
	  tevent_error ("Missing closing double quote");
	}
      else
	{
	  *p = '\0';
	  p = p + 1;
	  place = p;
	};
    };
  while ((*p != '\0') && (*p != '='))
    p = p + 1;
  if (*p == '=')
    {
      p = place;
      tskipspace (&p);
      if (((*p >= 'A') && (*p <= 'G')) || ((*p >= 'a') && (*p <= 'g')))
	{
	  relative = 1;
	  p = p + 1;
	};
      treadlen (&a, &b, &p);
      tskipspace (&p);
      if (*p != '=')
	{
	  tevent_error ("Expecting = in tempo");
	};
      p = p + 1;
    }
  else
    {
      a = 1;			/* [SS] 2013-01-27 */
      /*a = 0;  [SS] 2013-01-27 */
      b = 4;
      p = place;
    };
  tskipspace (&p);
  n = readtnump (&p);
  post_string = NULL;
  if (*p == '"')
    {
      p = p + 1;
      post_string = p;
      while ((*p != '"') && (*p != '\0'))
	{
	  p = p + 1;
	};
      if (*p == '\0')
	{
	  tevent_error ("Missing closing double quote");
	}
      else
	{
	  *p = '\0';
	  p = p + 1;
	};
    };
  tevent_tempo (n, a, b, relative, pre_string, post_string);
}

void appendfield(char *); /* links with store.c and yapstree.c */

void tappend_fieldcmd (key, s)  /* [SS] 2014-08-15 */
char key;
char *s;
{
appendfield(s);
} 

void
pretparse_words (s)
     char *s;
/* takes a tline of lyrics (w: field) and strips off */
/* any continuation character */
{
  int continuation;
  int l;

  /* printf("tparsing %s\n", s); */
  /* strip off any trailing spaces */
  l = strlen (s) - 1;
  while ((l >= 0) && (*(s + l) == ' '))
    {
      *(s + l) = '\0';
      l = l - 1;
    };
  if (*(s + l) != '\\')
    {
      continuation = 0;
    }
  else
    {
      /* [SS] 2014-08-14 */
      tevent_warning ("\\n continuation no longer supported in w: tline");
      continuation = 1;
      /* remove continuation character */
      *(s + l) = '\0';
      l = l - 1;
      while ((l >= 0) && (*(s + l) == ' '))
	{
	  *(s + l) = '\0';
	  l = l - 1;
	};
    };
  tevent_words (s, continuation);
}

void
init_tabbreviations ()
/* initialize mapping of H-Z to strings */
{
  int i;

  /* for (i = 0; i < 'Z' - 'H'; i++) [SS] 2016-09-25 */
  for (i = 0; i < 'z' - 'A'; i++) /* [SS] 2016-09-25 */
    {
      tabbreviation[i] = NULL;
    };
}

void
record_tabbreviation (char symbol, char *string)
/* update record of abbreviations when a U: field is encountered */
{
  int index;

  /* if ((symbol < 'H') || (symbol > 'Z')) [SS] 2016-09-20 */
     if ((symbol < 'A') || (symbol > 'z'))
    {
      return;
    };
  index = symbol - 'A';
  if (tabbreviation[index] != NULL)
    {
      free (tabbreviation[index]);
    };
  tabbreviation[index] = taddstring (string);
}

char *
lookup_tabbreviation (char symbol)
/* return string which s abbreviates */
{
  /* if ((symbol < 'H') || (symbol > 'Z'))  [SS] 2016-09-25 */
  if ((symbol < 'A') || (symbol > 'z'))
    {
      return (NULL);
    }
  else
    {
      return (tabbreviation[symbol - 'A']); /* [SS] 2016-09-20 */
    };
}

void
free_tabbreviations ()
/* free up any space taken by abbreviations */
{
  int i;

  for (i = 0; i < SIZE_ABBREVIATIONS; i++)
    {
      if (tabbreviation[i] != NULL)
	{
	  free (tabbreviation[i]);
	};
    };
}

void
tparsefield (key, field)
     char key;
     char *field;
/* top-level routine handling all tlines containing a field */
{
  char *comment;
  char *place;
  char *xplace;
  int iscomment;
  int foundkey;

  if (key == 'X')
    {
      int x;

      xplace = field;
      tskipspace (&xplace);
      x = readtnumf (xplace);
      if (tinhead)
	{
	  tevent_error ("second X: field in header");
	};
      tevent_refno (x);
      ignore_tline =0; /* [SS] 2017-04-12 */
      init_tvoicecode ();	/* [SS] 2011-01-01 */
      tinhead = 1;
      intbody = 0;
      tparserinchord = 0;
      return;
    };

  if (tparsing == 0)
    return;

  /*if ((intbody) && (strchr ("EIKLMPQTVdswW", key) == NULL)) [SS] 2014-08-15 */
  if ((intbody) && (strchr ("EIKLMPQTVdrswW+", key) == NULL)) /* [SS] 2015-05-11 */
    {
      tevent_error ("Field not allowed in tune tbody");
    };
  comment = field;
  iscomment = 0;
  while ((*comment != '\0') && (*comment != '%'))
    {
      comment = comment + 1;
    };
  if (*comment == '%')
    {
      iscomment = 1;
      *comment = '\0';
      comment = comment + 1;
    };
  place = field;
  tskipspace (&place);
  switch (key)
    {
    case 'K':
      foundkey = tparsekey (place);
      if (tinhead || intbody)
	{
	  if (foundkey)
	    {
	      intbody = 1;
	      tinhead = 0;
	    }
	  else
	    {
	      if (tinhead)
		{
		  tevent_error ("First K: field must specify key signature");
		};
	    };
	}
      else
	{
	  tevent_error ("No X: field preceding K:");
	};
      break;
    case 'M':
      {
	int num, denom;

	strncpy (ttimesigstring, place, 16);	/* [SS] 2011-08-19 */
	if (strncmp (place, "none", 4) == 0)
	  {
	    tevent_timesig (4, 4, 0);
	  }
	else
	  {
	    treadsig (&num, &denom, &place);
	    if ((*place == 's') || (*place == 'l'))
	      {
		tevent_error ("s and l in M: field not supported");
	      };
	    if ((num != 0) && (denom != 0))
	      {
		/* [code contributed by Larry Myerscough 2015-11-5]
		 * Specify checkbars = 1 for numeric time signature
		 * or checkbars = 2 for 'common' time signature to
		 * remain faithful to style of input abc file.
		 */
		tevent_timesig (num, denom, 1 + ((*place == 'C') || (*place == 'c')));
	      };
	  };
	break;
      };
    case 'L':
      {
	int num, denom;

	treadsig (&num, &denom, &place);
	if (num != 1)
	  {
	    tevent_error ("Default length must be 1/X");
	  }
	else
	  {
	    if (denom > 0)
	      {
		tevent_length (denom);
	      }
	    else
	      {
		tevent_error ("invalid denominator");
	      };
	  };
	break;
      };
    case 'P':
      tevent_part (place);
      break;
    case 'I':
      tevent_info (place);
      break;
    case 'V':
      tparsevoice (place);
      break;
    case 'Q':
      tparse_tempo (place);
      break;
    case 'U':
      {
	char symbol;
	char container;
	char *expansion;

	tskipspace (&place);
	/* if ((*place >= 'H') && (*place <= 'Z')) [SS] 2016-09-20 */
	if ((*place >= 'A') && (*place <= 'z'))  /* [SS] 2016-09-20 */
	  {
	    symbol = *place;
	    place = place + 1;
	    tskipspace (&place);
	    if (*place == '=')
	      {
		place = place + 1;
		tskipspace (&place);
		if (*place == '!')
		  {
		    place = place + 1;
		    container = '!';
		    expansion = place;
		    while ((!iscntrl (*place)) && (*place != '!'))
		      {
			place = place + 1;
		      };
		    if (*place != '!')
		      {
			tevent_error ("No closing ! in U: field");
		      };
		    *place = '\0';
		  }
		else
		  {
		    container = ' ';
		    expansion = place;
		    while (isalnum (*place))
		      {
			place = place + 1;
		      };
		    *place = '\0';
		  };
		if (strlen (expansion) > 0)
		  {
		    record_tabbreviation (symbol, expansion);
		    tevent_abbreviation (symbol, expansion, container);
		  }
		else
		  {
		    tevent_error ("Missing term in U: field");
		  };
	      }
	    else
	      {
		tevent_error ("Missing '=' U: field ignored");
	      };
	  }
	else
	  {
	    tevent_warning ("only 'H' - 'Z' supported in U: field");
	  };
      };
      break;
    case 'w':
      pretparse_words (place);
      break;
    case 'd':
      /* decoration tline in abcm2ps */
      tevent_field (key, place);	/* [SS] 2010-02-23 */
      break;
    case 's':
      tevent_field (key, place);	/* [SS] 2010-02-23 */
      break;
    case '+':
      if (tlastfieldcmd == 'w')
          tappend_fieldcmd (key, place); /*[SS] 2014-08-15 */
      break; /* [SS] 2014-09-07 */
    default:
      tevent_field (key, place);
    };
  if (iscomment)
    {
      tparse_precomment (comment);
    };
  if (key == 'w') tlastfieldcmd = 'w'; /* [SS] 2014-08-15 */
  else tlastfieldcmd = ' ';  /* [SS[ 2014-08-15 */
}

char *
tparseintlinefield (p)
     char *p;
/* tparse field within abc tline e.g. [K:G] */
{
  char *q;

  tevent_startinline ();
  q = p;
  while ((*q != ']') && (*q != '\0'))
    {
      q = q + 1;
    };
  if (*q == ']')
    {
      *q = '\0';
      tparsefield (*p, p + 2);
      q = q + 1;
    }
  else
    {
      tevent_error ("missing closing ]");
      tparsefield (*p, p + 2);
    };
  tevent_closeinline ();
  return (q);
}

/* this function is used by toabc.c [SS] 2011-06-10 */
void
tprint_inputtline_notlinefeed ()
{
  if (inputtline[sizeof inputtline - 1] != '\0')
    {
      /*
       * We are called exclusively by toabc.c,
       * and when we are called, event_error is muted,
       * so, event_error("input tline truncated") does nothing.
       * Simulate it with a plain printf. [PHDM 2012-12-01]
       */
      printf ("%%Error : input tline truncated\n");
    }
  printf ("%s", inputtline);
}

/* this function is used by toabc.c [SS] 2011-06-07 */
void
print_inputtline ()
{
  tprint_inputtline_notlinefeed ();
  printf ("\n");
}

void
tparsemusic (field)
     char *field;
/* tparse a tline of abc notes */
{
  char *p;
  char c; /* [SS] 2017-04-19 */
  char *comment;
  char endchar;
  int iscomment;
  int starcount;
  int i;
  char playonrep_list[80];
  int tdecorators[DECSIZE];

  for (i = 0; i < DECSIZE; i++)
    tdecorators[i] = 0;		/* [SS] 2012-03-30 */

  tevent_startmusicline ();
  endchar = ' ';
  comment = field;
  iscomment = 0;
  while ((*comment != '\0') && (*comment != '%'))
    {
      comment = comment + 1;
    };
  if (*comment == '%')
    {
      iscomment = 1;
      *comment = '\0';
      comment = comment + 1;
    };

  p = field;
  tskipspace (&p);
  while (*p != '\0')
    {
      tlineposition = p - tlinestart;	/* [SS] 2011-07-18 */

      if (*p == '.' && *(p+1) == '(') {  /* [SS] 2015-04-28 dotted tslur */
          p = p+1;
          tevent_sluron (1);
          p = p+1;
          }

      if (((*p >= 'a') && (*p <= 'g')) || ((*p >= 'A') && (*p <= 'G')) ||
	  (strchr ("_^=", *p) != NULL) || (strchr (tdecorations, *p) != NULL))
	{
	  tparsenote (&p);
	}
      else
	{
          c = *p; /* [SS] 2017-04-19 */
	  switch (*p)
	    {
	    case '"':
	      {
		struct vstring gchord;

		p = p + 1;
		inittvstring (&gchord);
		while ((*p != '"') && (*p != '\0'))
		  {
		    taddch (*p, &gchord);
		    p = p + 1;
		  };
		if (*p == '\0')
		  {
		    tevent_error ("Guitar chord name not properly closed");
		  }
		else
		  {
		    p = p + 1;
		  };
		tevent_gchord (gchord.st);
		freetvstring (&gchord);
		break;
	      };
	    case '|':
	      p = p + 1;
	      switch (*p)
		{
		case ':':
		  tevent_bar (BAR_REP, "");
		  p = p + 1;
		  break;
		case '|':
		  tevent_bar (DOUBLE_BAR, "");
		  p = p + 1;
		  break;
		case ']':
		  tevent_bar (THIN_THICK, "");
		  p = p + 1;
		  break;
		default:
		  p = tgetrep (p, playonrep_list);
		  tevent_bar (SINGLE_BAR, playonrep_list);
		};
	      break;
	    case ':':
	      p = p + 1;
	      switch (*p)
		{
		case ':':
		  tevent_bar (DOUBLE_REP, "");
		  p = p + 1;
		  break;
		case '|':
		  p = p + 1;
		  p = tgetrep (p, playonrep_list);
		  tevent_bar (REP_BAR, playonrep_list);
		  if (*p == ']')
		    p = p + 1;	/* [SS] 2013-10-31 */
		  break;
		default:
		  tevent_error ("Single colon in bar");
		};
	      break;
	    case ' ':
	      tevent_space ();
	      tskipspace (&p);
	      break;
	    case TAB:
	      tevent_space ();
	      tskipspace (&p);
	      break;
	    case '(':
	      p = p + 1;
	      {
		int t, q, r;

		t = 0;
		q = 0;
		r = 0;
		t = readtnump (&p);
		if ((t != 0) && (*p == ':'))
		  {
		    p = p + 1;
		    q = readtnump (&p);
		    if (*p == ':')
		      {
			p = p + 1;
			r = readtnump (&p);
		      };
		  };
		if (t == 0)
		  {
                    if (*p == '&') {
                       p = p+1;
                       tevent_start_extended_overlay(); /* [SS] 2015-03-23 */
                       }
                    else
		       tevent_sluron (1);
		  }
		else  /* t != 0 */
		  {
		    tevent_tuple (t, q, r);
		  };
	      };
	      break;
	    case ')':
	      p = p + 1;
	      tevent_sluroff (0);
	      break;
	    case '{':
	      p = p + 1;
	      tevent_graceon ();
	      ttingrace = 1;
	      break;
	    case '}':
	      p = p + 1;
	      tevent_graceoff ();
	      ttingrace = 0;
	      break;
	    case '[':
	      p = p + 1;
	      switch (*p)
		{
		case '|':
		  p = p + 1;
		  tevent_bar (THICK_THIN, "");
		  if (*p == ':')   /* [SS] 2015-04-13 */
		      tevent_bar (BAR_REP, "");
		      p = p + 1;
		  break;
		default:
		  if (isdigit (*p))
		    {
		      p = tgetrep (p, playonrep_list);
		      tevent_playonrep (playonrep_list);
		    }
		  else
		    {
		      if (isalpha (*p) && (*(p + 1) == ':'))
			{
			  p = tparseintlinefield (p);
			}
		      else
			{
			  tlineposition = p - tlinestart;	/* [SS] 2011-07-18 */
			  /* [SS] 2012-03-30 */
			  for (i = 0; i < DECSIZE; i++)
			    chordtdecorators[i] =
			      tdecorators[i] | tdecorators_passback[i];
			  tevent_chordon (chordtdecorators);
			  tparserinchord = 1;
			};
		    };
		  break;
		};
	      break;
	    case ']':
	      p = p + 1;
	      treadlen (&tchord_n, &tchord_m, &p);
	      tevent_chordoff (tchord_n, tchord_m);
	      tparserinchord = 0;
	      for (i = 0; i < DECSIZE; i++)
		{
		  chordtdecorators[i] = 0;
		  tdecorators_passback[i] = 0;	/* [SS] 2012-03-30 */
		}
	      break;
/*  hidden rest  */
	    case 'x':
	      {
		int n, m;

		p = p + 1;
		treadlen (&n, &m, &p);
/* in order to handle a fermata applied to a rest we must
 * pass decorators to event_rest.
 */
		for (i = 0; i < DECSIZE; i++)
		  {
		    tdecorators[i] = tdecorators_passback[i];
		    tdecorators_passback[i] = 0;
		  }
		tevent_rest (tdecorators, n, m, 1);
                tdecorators[FERMATA] = 0;  /* [SS] 2014-11-17 */
		break;
	      };
/*  regular rest */
	    case 'z':
	      {
		int n, m;

		p = p + 1;
		treadlen (&n, &m, &p);
/* in order to handle a fermata applied to a rest we must
 * pass decorators to event_rest.
 */
		for (i = 0; i < DECSIZE; i++)
		  {
		    tdecorators[i] = tdecorators_passback[i];
		    tdecorators_passback[i] = 0;
		  }
		tevent_rest (tdecorators, n, m, 0);
                tdecorators[FERMATA] = 0;  /* [SS] 2014-11-17 */
		break;
	      };
	    case 'y':		/* used by Barfly and abcm2ps to put space */
/* I'm sure I've seen somewhere that /something/ allows a length
 * specifier with y to enlarge the space length. Allow it anyway; it's
 * harmless.
 */
	      {
		int n, m;

		p = p + 1;
		treadlen (&n, &m, &p);
		tevent_spacing (n, m);
		break;
	      };
/* full bar rest */
	    case 'Z':
	    case 'X':		/* [SS] 2012-11-15 */

	      {
		int n, m;

		p = p + 1;
		treadlen (&n, &m, &p);
		if (m != 1)
		  {
		    tevent_error
		      ("X or Z must be followed by a whole integer");
		  };
		tevent_mrest (n, m, c);
                tdecorators[FERMATA] = 0;  /* [SS] 2014-11-17 */
		break;
	      };
	    case '>':
	      {
		int n;

		n = 0;
		while (*p == '>')
		  {
		    n = n + 1;
		    p = p + 1;
		  };
		if (n > 3)
		  {
		    tevent_error ("Too many >'s");
		  }
		else
		  {
		    tevent_broken (GT, n);
		  };
		break;
	      };
	    case '<':
	      {
		int n;

		n = 0;
		while (*p == '<')
		  {
		    n = n + 1;
		    p = p + 1;
		  };
		if (n > 3)
		  {
		    tevent_error ("Too many <'s");
		  }
		else
		  {
		    tevent_broken (LT, n);
		  };
		break;
	      };
	    case 's':
	      if (tslur == 0)
		{
		  tslur = 1;
		}
	      else
		{
		  tslur = tslur - 1;
		};
	      tevent_slur (tslur);
	      p = p + 1;
	      break;
	    case '-':
	      tevent_tie ();
	      p = p + 1;
	      break;
	    case '\\':
	      p = p + 1;
	      if (tcheckend (p))
		{
		  tevent_lineend ('\\', 1);
		  endchar = '\\';
		}
	      else
		{
		  tevent_error ("'\\' in middle of tline ignored");
		};
	      break;
	    case '+':
	      if (toldchordconvention)
		{
		  tlineposition = p - tlinestart;	/* [SS] 2011-07-18 */
		  tevent_chord ();
		  tparserinchord = 1 - tparserinchord;
		  if (tparserinchord == 0)
		    {
		      for (i = 0; i < DECSIZE; i++)
			chordtdecorators[i] = 0;
		    };
		  p = p + 1;
		  break;
		}
	      /* otherwise we fall through into the next case statement */
	    case '!':
	      {
		struct vstring instruction;
		char *s;
		char endcode;

		endcode = *p;
		p = p + 1;
		s = p;
		inittvstring (&instruction);
		while ((*p != endcode) && (*p != '\0'))
		  {
		    taddch (*p, &instruction);
		    p = p + 1;
		  };
		if (*p != endcode)
		  {
		    p = s;
		    if (tcheckend (s))
		      {
			tevent_lineend ('!', 1);
			endchar = '!';
		      }
		    else
		      {
			tevent_error ("'!' or '+' in middle of tline ignored");
		      };
		  }
		else
		  {
		    tevent_instruction (instruction.st);
		    p = p + 1;
		  };
		freetvstring (&instruction);
	      }
	      break;
	    case '*':
	      p = p + 1;
	      starcount = 1;
	      while (*p == '*')
		{
		  p = p + 1;
		  starcount = starcount + 1;
		};
	      if (tcheckend (p))
		{
		  tevent_lineend ('*', starcount);
		  endchar = '*';
		}
	      else
		{
		  tevent_error ("*'s in middle of tline ignored");
		};
	      break;
	    case '/':
	      p = p + 1;
	      if (ttingrace)
		tevent_acciaccatura ();
	      else
		tevent_error ("stray / not in grace sequence");
	      break;
	    case '&':
	      p = p + 1;
              if (*p == ')') {
                 p = p + 1;
                 tevent_stop_extended_overlay(); /* [SS] 2015-03-23 */
                 break;
                 }
              else
	        tevent_split_voice ();
	        break;
	    default:
	      {
		char msg[40];

		if ((*p >= 'A') && (*p <= 'z')) /* [SS] 2016-09-20 */
		  {
		    tevent_reserved (*p);
		  }
		else
		  {
		    sprintf (msg, "Unrecognized character: %c", *p);
		    tevent_error (msg);
		  };
	      };
	      p = p + 1;
	    };
	};
    };
  tevent_endmusicline (endchar);
  if (iscomment)
    {
      tparse_precomment (comment);
    };
}

void
tparsetline (tline)
     char *tline;
/* top-level routine for handling a tline in abc file */
{
  char *p, *q;

  handle_abc2midi_tparser (tline);  /* [SS] 2017-04-12 */
  if (ignore_tline == 1) return; /* [SS] 2017-04-12 */

  /*printf("%d tparsing : %s\n", tlineno, tline); */
  strncpy (inputtline, tline, sizeof inputtline);	/* [SS] 2011-06-07 [PHDM] 2012-11-27 */

  p = tline;
  tlinestart = p;		/* [SS] 2011-07-18 */
  ttingrace = 0;
  tskipspace (&p);
  if (strlen (p) == 0)
    {
      tevent_blankline ();
      tinhead = 0;
      intbody = 0;
      return;
    };
  if ((int) *p == '\\')
    {
      if (tparsing)
	{
	  tevent_tex (p);
	};
      return;
    };
  if ((int) *p == '%')
    {
      tparse_precomment (p + 1);
      if (!tparsing)
	tevent_linebreak ();
      return;
    };
  /*if (strchr ("ABCDEFGHIKLMNOPQRSTUVdwsWXZ", *p) != NULL) [SS] 2014-08-15 */
  if (strchr ("ABCDEFGHIKLMNOPQRSTUVdwsWXZ+", *p) != NULL)
    {
      q = p + 1;
      tskipspace (&q);
      if ((int) *q == ':')
	{
	  if (*(tline + 1) != ':')
	    {
	      tevent_warning ("whitespace in field declaration");
	    };
	  if ((*(q + 1) == ':') || (*(q + 1) == '|'))
	    {
	      tevent_warning ("Potentially ambiguous tline - either a :| repeat or a field command -- cannot distinguish.");
/*    [SS] 2013-03-20 */
/*     };             */
/*      tparsefield(*p,q+1); */

/*    [SS} 2013-03-20 start */
/*    malformed field command try processing it as a music tline */
	      if (intbody)
		{
		  if (tparsing)
		    tparsemusic (p);
		}
	      else
		{
		  if (tparsing)
		    tevent_text (p);
		};
	    }
	  else
	    tparsefield (*p, q + 1);	/* not field command malformed */
/*    [SS] 2013-03-20  end */

	}
      else
	{
	  if (intbody)
	    {
	      if (tparsing)
		tparsemusic (p);
	    }
	  else
	    {
	      if (tparsing)
		tevent_text (p);
	    };
	};
    }
  else
    {
      if (intbody)
	{
	  if (tparsing)
	    tparsemusic (p);
	}
      else
	{
	  if (tparsing)
	    tevent_text (p);
	};
    };
}

void
tparsefile (name)
     char *name;
/* top-level routine for tparsing file */
{
  FILE *fp;
  int reading;
  int filetline;
  struct vstring tline;
  /* char tline[MAXtline]; */
  int t;
  int lastch, done_eol;

  /* printf("tparsefile called %s\n", name); */
  /* The following code permits abc2midi to read abc from stdin */
  if ((strcmp (name, "stdin") == 0) || (strcmp (name, "-") == 0))
    {
      fp = stdin;
    }
  else
    {
      fp = fopen (name, "r");
    };
  if (fp == NULL)
    {
      printf ("Failed to open file %s\n", name);
      exit (1);
    };
  tinhead = 0;
  intbody = 0;
  tparseroff ();
  reading = 1;
  tline.limit = 4;
  inittvstring (&tline);
  filetline = 1;
  done_eol = 0;
  lastch = '\0';
  while (reading)
    {
      t = getc (fp);
      if (t == EOF)
	{
	  reading = 0;
	  if (tline.len > 0)
	    {
	      tparsetline (tline.st);
	      filetline = filetline + 1;
	      tlineno = filetline;
	      if (tparsing)
		tevent_linebreak ();
	    };
	}
      else
	{
	  /* recognize  \n  or  \r  or  \r\n  or  \n\r  as end of tline */
	  /* should work for DOS, unix and Mac files */
	  if ((t != '\n') && (t != '\r'))
	    {
	      taddch ((char) t, &tline);
	      done_eol = 0;
	    }
	  else
	    {
	      if ((done_eol) && (((t == '\n') && (lastch == '\r')) ||
				 ((t == '\r') && (lastch == '\n'))))
		{
		  done_eol = 0;
		  /* skip this character */
		}
	      else
		{
		  /* reached end of tline */
		  tparsetline (tline.st);
		  cleartvstring (&tline);
		  filetline = filetline + 1;
		  tlineno = filetline;
		  if (tparsing)
		    tevent_linebreak ();
		  done_eol = 1;
		};
	    };
	  lastch = t;
	};
    };
  fclose (fp);
  tevent_eof ();
  freetvstring (&tline);
  if (ttparsing_started == 0)
    tevent_error ("No tune processed. Possible missing X: field");
}


int
tparsetune (FILE * fp)
/* top-level routine for tparsing file */
{
  struct vstring tline;
  /* char tline[MAXtline]; */
  int t;
  int lastch, done_eol;

  tinhead = 0;
  intbody = 0;
  tparseroff ();
  tintune = 1;
  tline.limit = 4;
  inittvstring (&tline);
  done_eol = 0;
  lastch = '\0';
  do
    {
      t = getc (fp);
      if (t == EOF)
	{
	  if (tline.len > 0)
	    {
	      printf ("%s\n", tline.st);
	      tparsetline (tline.st);
	      filetline_number = filetline_number + 1;
	      tlineno = filetline_number;
	      tevent_linebreak ();
	    };
	  break;
	}
      else
	{
	  /* recognize  \n  or  \r  or  \r\n  or  \n\r  as end of tline */
	  /* should work for DOS, unix and Mac files */
	  if ((t != '\n') && (t != '\r'))
	    {
	      taddch ((char) t, &tline);
	      done_eol = 0;
	    }
	  else
	    {
	      if ((done_eol) && (((t == '\n') && (lastch == '\r')) ||
				 ((t == '\r') && (lastch == '\n'))))
		{
		  done_eol = 0;
		  /* skip this character */
		}
	      else
		{
		  /* reached end of tline */
		  tparsetline (tline.st);
		  cleartvstring (&tline);
		  filetline_number = filetline_number + 1;
		  tlineno = filetline_number;
		  tevent_linebreak ();
		  done_eol = 1;
		};
	    };
	  lastch = t;
	};
    }
  while (tintune);
  freetvstring (&tline);
  return t;
}

/*
int getline ()
{
  return (tlineno);
}
*/
