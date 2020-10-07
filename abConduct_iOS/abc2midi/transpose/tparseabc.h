/* parseabc.h - interface file for abc parser */
/* used by abc2midi, abc2abc and yaps */

/* abc.h must be #included before this file */
/* functions and variables provided by parseabc.c */

/* for Microsoft Visual C++ 6 */
#ifdef _MSC_VER
#define KANDR
#endif

/* the arg list to event_voice keeps growing; if we put the args into a structure
and pass that around, routines that don't need the new ones need not be altered.
NB. event_voice is *called* from parseabc.c, the actual procedure is linked
in from the program-specific file */
/* added middle= stuff */
#define V_STRLEN 64
struct voice_params {
	int gotclef;
	int gotoctave;
        int gotttranspose;
	int gotname;
	int gotsname;
	int gotmiddle;
        int gotother;  /* [SS] 2011-04-18 */
        int octave;
	int ttranspose;
	char clefname[V_STRLEN+1];
	char namestring[V_STRLEN+1];
	char snamestring[V_STRLEN+1];
	char middlestring[V_STRLEN+1];
        char other[V_STRLEN+1]; /* [SS] 2011-04-18 */
	};

/* holds a fraction */
struct fraction {
  int num;
  int denom;
};


#ifndef KANDR
extern int readnump(char **p);
extern int readsnump(char **p);
extern int readnumf(char *num);
extern void tskipspace(char **p);
extern int readsnumf(char *s);
extern void readstr(char out[], char **in, int limit);
extern int getarg(char *option, int argc, char *argv[]);
extern int *checkmalloc(int size);
extern char *addstring(char *s);
extern char *concatenatestring(char *s1, char *s2);
extern char *lookup_abbreviation(char symbol);
extern int istmicrotone(char **p, int dir);
extern void tevent_normal_tone(void);
extern void print_inputtline(void);
extern void print_inputline_nolinefeed(void);
#else
extern int readnump();
extern int readsnump();
extern int readnumf();
extern void tskipspace();
extern int readsnumf();
extern void readstr();
extern int getarg();
extern int *checkmalloc();
extern char *addstring();
extern char *concatenatestring();
extern char *lookup_abbreviation();
extern int istmicrotone();
extern void tevent_normal_tone();
extern void print_inputline_nolinefeed();
#endif
extern void tparseron();
extern void tparseroff();

extern int lineno;

/* event_X() routines - these are called from parseabc.c       */
/* the program that uses the parser must supply these routines */
#ifndef KANDR
extern void tevent_init(int argc, char *argv[], char **filename);
extern void tevent_text(char *s);
extern void tevent_reserved(char p);
extern void tevent_tex(char *s);
extern void tevent_linebreak(void);
extern void tevent_startmusicline(void);
extern void tevent_endmusicline(char endchar);
extern void tevent_eof(void);
extern void tevent_comment(char *s);
extern void tevent_specific(char *package, char *s);
extern void tevent_specific_in_header(char *package, char *s);
extern void tevent_startinline(void);
extern void tevent_closeinline(void);
extern void tevent_field(char k, char *f);
extern void tevent_words(char *p, int continuation);
extern void tevent_part(char *s);


extern void tevent_voice(int n, char *s, struct voice_params *params);
extern void tevent_length(int n);
extern void tevent_blankline(void);
extern void tevent_refno(int n);
extern void tevent_tempo(int n, int a, int b, int rel, char *pre, char *post);
extern void tevent_timesig(int n, int m, int dochecking);
extern void tevent_octave(int num, int local);
extern void tevent_info_key(char *key, char *value);
extern void tevent_info(char *s);
extern void tevent_key(int sharps, char *s, int modeindex,
               char modmap[7], int modmul[7], struct fraction modmicro[7],
               int gotkey, int gotclef, char *clefname,
               int octave, int ttranspose, int gotoctave, int gotttranspose,
               int explict);
extern void tevent_microtone(int dir, int a, int b);
extern void tevent_graceon(void);
extern void tevent_graceoff(void);
extern void tevent_rep1(void);
extern void tevent_rep2(void);
extern void tevent_playonrep(char *s);
extern void tevent_tie(void);
extern void tevent_slur(int t);
extern void tevent_sluron(int t);
extern void tevent_sluroff(int t);
extern void tevent_rest(int tdecorators[DECSIZE],int n,int m,int type);
extern void tevent_mrest(int n,int m,char c);
extern void tevent_spacing(int n, int m);
extern void tevent_bar(int type, char *replist);
extern void tevent_space(void);
extern void tevent_lineend(char ch, int n);
extern void tevent_broken(int type, int mult);
extern void tevent_tuple(int n, int q, int r);
extern void tevent_chord(void);
extern void tevent_chordon(int chordtdecorators[DECSIZE]);
extern void tevent_chordoff(int, int);
extern void tevent_instruction(char *s);
extern void tevent_gchord(char *s);
extern void tevent_note(int tdecorators[DECSIZE], char accidental, int mult,
                       char note, int xoctave, int n, int m);
extern void tevent_abbreviation(char symbol, char *string, char container);
extern void tevent_acciaccatura();
extern void tevent_start_extended_overlay();
extern void tevent_stop_extended_overlay();
extern void tevent_split_voice();
extern void print_voicecodes(void);
extern void init_abbreviations();
extern void free_abbreviations();
extern void tparsefile();
extern int parsetune();
#else
extern void tevent_init();
extern void tevent_text();
extern void tevent_reserved();
extern void tevent_tex();
extern void tevent_linebreak();
extern void tevent_startmusicline();
extern void tevent_endmusicline();
extern void tevent_eof();
extern void tevent_comment();
extern void tevent_specific();
extern void tevent_specific_in_header();
extern void tevent_startinline();
extern void tevent_closeinline();
extern void tevent_field();
extern void tevent_words();
extern void tevent_part();
extern void tevent_voice();
extern void tevent_length();
extern void tevent_blankline();
extern void tevent_refno();
extern void tevent_tempo();
extern void tevent_timesig();
extern void tevent_octave();
extern void tevent_info_key();
extern void tevent_info();
extern void tevent_key();
extern void tevent_microtone();
extern void tevent_graceon();
extern void tevent_graceoff();
extern void tevent_rep1();
extern void tevent_rep2();
extern void tevent_playonrep();
extern void tevent_tie();
extern void tevent_slur();
extern void tevent_sluron();
extern void tevent_sluroff();
extern void tevent_rest();
extern void tevent_mrest();
extern void tevent_spacing();
extern void tevent_bar();
extern void tevent_space();
extern void tevent_lineend();
extern void tevent_broken();
extern void tevent_tuple();
extern void tevent_chord();
extern void tevent_chordon();
extern void tevent_chordoff();
extern void tevent_instruction();
extern void tevent_gchord();
extern void tevent_note();
extern void tevent_abbreviation();
extern void tevent_acciaccatura();
extern void tevent_start_extended_overlay();
extern void tevent_stop_extended_overlay();
extern void tevent_split_voice();
extern void print_voicecodes();
extern void init_abbreviations();
extern void free_abbreviations();
extern void tparsefile();
extern int parsetune();
#endif
