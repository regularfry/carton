/**
 * This file is, erm, "heavily inspired" by crate_boot.c in the crate
 * gem, written by Jeremey Hinegardner, in which the following notice
 * can be found:
 *
 **************************************************************************
 * Copyright (c) 2008, Jeremy Hinegardner
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
 * WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
 * AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR
 * CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
 * OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
 * NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
 * CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 **************************************************************************
 *
 * Additional bugs and modifications (c) 2011 Alex Young
 * <alex@bytemark.co.uk> 
 * Terms as above.
 */

#include <stdlib.h>
#include <getopt.h>
#include <ruby.h>

/** from ruby's original main.c **/
#if defined(__MACOS__) && defined(__MWERKS__)
#include <console.h>
#endif

/* We rely on CARTON_ENTRY being defined as the name of the ruby file
 * to load and eval as the entry point, which avoids restricting the
 * application to the file:A.foo pattern
 */

struct carton_app {
  char  *file_name;
  char  *class_name;
  VALUE  app_instance;
  char  *method_name;
  ID     run_method;
} ;

typedef struct carton_app carton_app; 

/* carton 'secret' options */
static struct option longopts[] = {
  { "carton-file",   required_argument, NULL, 1 },
  { "carton-class",  required_argument, NULL, 2 },
  { "carton-method", required_argument, NULL, 3 },
  { NULL,           0,                 NULL, 0 }
};

int carton_init_from_options(carton_app *ca, int argc, char** argv )
{
  int ch ;
  int done = 0;
  int old_opterr = opterr;

  /* turn off printing to stderr */
  opterr = 0;

  while ( !done && (ch = getopt_long( argc, argv, "", longopts, NULL ) ) != -1 ) {
    switch ( ch ) {
    case 1:
      free( ca->file_name );
      ca->file_name = strdup( optarg );
      break;

    case 2:
      free( ca->class_name );
      ca->class_name = strdup( optarg );
      break;

    case 3:
      free( ca->method_name );
      ca->method_name = strdup( optarg );
      break;

    default:
      /* if we have a non-option then we are done and be sure to decrement
       * optind so we keep the option that caused it to faile
       */
      done = 1;
      optind--;
      break;
    }
  }
 
  opterr = old_opterr;
  return optind;
}


/** 
 * Build a new Amalgalite::Requires instance.
 */
VALUE get_am_req_mem_new()
{
  VALUE opts_hsh     = rb_hash_new();
  rb_hash_aset(opts_hsh, 
	       ID2SYM(rb_intern("dbfile_name")),
	       rb_str_buf_new2(":memory:"));

  VALUE Amalgalite   = rb_const_get(rb_cObject, rb_intern("Amalgalite"));
  VALUE Requires     = rb_const_get(Amalgalite, rb_intern("Requires"));
  VALUE new_instance = rb_class_new_instance(1, &opts_hsh, Requires);
  
  return new_instance;
}

/**
 * Convert an in-memory buffer to a Ruby string.
 */
VALUE buffer_to_s(const char *start_ptr, const char *end_ptr)
{
  return rb_str_new( start_ptr,
		     end_ptr - start_ptr );
}

/**
 * Import the sql dump in sql_str to a new Amalgalite::Requires
 * instance.
 */
VALUE import_from_s(VALUE sql_str)
{
  VALUE am_req = get_am_req_mem_new();

  return rb_funcall(am_req, rb_intern("import"), 1, sql_str);
}


/**
 * Require the named file, sidestepping Kernel.require when we know it
 * can't work yet.
 */
VALUE am_require( VALUE filename )
{
  StringValue( filename );
  VALUE Amalgalite   = rb_const_get(rb_cObject, rb_intern("Amalgalite"));
  VALUE Requires     = rb_const_get(Amalgalite, rb_intern("Requires"));

  return rb_funcall( Requires, rb_intern("require"), 1, filename );
}

/**
 * When carton builds the stdlib, amalgalite and the app into a static
 * library, these are the symbols objcopy gives to the two binary
 * blobs we're interested in.
 */
extern char const _binary_lib_sql_start[];
extern char const _binary_lib_sql_end[];
extern char const _binary_app_sql_start[];
extern char const _binary_app_sql_end[];


/**
 * Make the actual application call, we call the application instance
 * with the method given and pass it ARGV and ENV in that order
 */
VALUE carton_wrap_app( VALUE arg )
{
  carton_app *ca = (carton_app*)arg;
  char       buf[BUFSIZ];
  char      *dot;
  VALUE      filename_str;

  /* Linked buffers */
  VALUE      s_lib_sql = buffer_to_s( _binary_lib_sql_start, 
				      _binary_lib_sql_end );
  VALUE      s_app_sql = buffer_to_s( _binary_app_sql_start, 
				      _binary_app_sql_end );
  char       file_name[] = CARTON_ENTRY;
 
  /* Load the SQL from the buffers  */
  import_from_s(s_lib_sql);
  import_from_s(s_app_sql);
		     
  /* require the entry point file, ditching any trailing extension
     N.B This will behave unexpectedly for some filenames containing
     dots.
   **/
  dot = strchr( file_name, '.');
  if ( NULL != dot ) { *dot = '\0' ; }
  
  filename_str = rb_str_new(file_name, strlen(file_name));


  /* Here we have two options: we can either call directly into
   * Amalgalite to require the app file, which will bypass the
   * filesystem, or we can call the overloaded top-level #require
   * method, which, even though Amalgalite is loaded, will go via
   * $LOAD_PATH.
   * 
   * What *doesn't* work is rb_funcalling Kernel.require, because that
   * bypasses the Amalgalite loader completely, despite it being
   * overridden in amalgalite/core_ext/kernel/require.
   */
  /* This is the first version: */
  /* am_require( filename_get ); */

  /* This is the second: */
  memset(buf, '\0', BUFSIZ);
  snprintf(buf, BUFSIZ, "require '%s'", file_name);
  return rb_eval_string(buf);
  /**/
}


static VALUE dump_backtrace( VALUE elem, VALUE n ) 
{
  fprintf( stderr, "\tfrom %s\n", RSTRING(elem)->ptr );
}

/**
 * ifdef items from ruby's original main.c
 */

/* to link startup code with ObjC support */
#if (defined(__APPLE__) || defined(__NeXT__)) && defined(__MACH__)
static void objcdummyfunction( void ) { objc_msgSend(); }
#endif

extern VALUE cARB;

void bootstrap()
{
  VALUE sql_str = buffer_to_s( _binary_lib_sql_start, _binary_lib_sql_end );

  am_bootstrap_lift_str( cARB, rb_ary_new3(1, sql_str) );
}


int main( int argc, char** argv ) 
{
  int state  = 0;
  int rc     = 0;
  int opt_mv = 0;

  carton_app ca;

  /** startup items from ruby's original main.c */
#ifdef _WIN32
  NtInitialize(&argc, &argv);
#endif
#if defined(__MACOS__) && defined(__MWERKS__)
  argc = ccommand(&argv);
#endif

  /* setup ruby */
  ruby_init();
  ruby_script( argv[0] );
  ruby_init_loadpath();

  /* strip out the carton specific arguments from argv using --carton- */
  opt_mv = carton_init_from_options( &ca, argc, argv );
  argc -= opt_mv;
  argv += opt_mv;
 
  /* make ARGV available */
  ruby_set_argv( argc, argv );

  /* initialize all extensions */
  Init_ext();

  /* load up the amalgalite libs */
  bootstrap();

  /* remove the current LOAD_PATH */
  rb_ary_clear( rb_gv_get( "$LOAD_PATH" ) );

  /* invoke the class / method passing in ARGV and ENV */
  rb_protect( carton_wrap_app, (VALUE)&ca, &state );

  /* check the results */
  if ( state ) {

    /* exception was raised, check the $! var */
    VALUE lasterr  = rb_gv_get("$!");
   
    /* system exit was called so just propogate that up to our exit */
    if ( rb_obj_is_instance_of( lasterr, rb_eSystemExit ) ) {

      rc = NUM2INT( rb_attr_get( lasterr, rb_intern("status") ) );
      /*printf(" Caught SystemExit -> $? will be %d\n", rc ); */

    } else {

      /* some other exception was raised so dump that out */
      VALUE klass     = rb_class_path( CLASS_OF( lasterr ) );
      VALUE message   = rb_obj_as_string( lasterr );
      VALUE backtrace = rb_funcall( lasterr, rb_intern("backtrace"), 0 );

      fprintf( stderr, "%s: %s\n", 
	       RSTRING( klass )->ptr, 
	       RSTRING( message )->ptr );
      rb_iterate( rb_each, backtrace, dump_backtrace, Qnil );

      rc = state;
    }
  } 

  free( ca.file_name );
  free( ca.class_name );
  free( ca.method_name );

  /* shut down ruby */
  ruby_finalize();

  /* exit the program */
  exit( rc );
}

