/*
 * U3ASM
 * $Header: /cvsroot/uuu/devtool/u3asm/program_options.cc,v 2.6 2003/06/24 01:48:51 daboy Exp $
 * Copyright 2003 by Phil Frost; see file "License".
 */

/** \file program_options.cc
 *
 * class \c Program_options definition. */

#include "program_options.h"
#include "exit_codes.h"
#include "conf.h"

#include <errno.h>



namespace
{
    /** remove and return an operand from \p argv. It's up to the caller to
     * decrement \c argc, etc. */
    char *snarf_arg( int argc, char *argv[], int i )
    {
	char *arg;

	if( i >= argc ) return 0;

	arg = argv[i];

	for( ++i ; i < argc ; ++i )
	    argv[i-1] = argv[i];
	argv[i] = 0;

	return arg;
    }


    /** thrown to print usage help. */

    Exception usage( exit_clean,
"usage: u3asm [options] [--] [input file]\n\
\n\
options begin with one of '-' '+' or '='. '+' enables or increases an option,\n\
and '-' disables or decrements an option. '=' sets the value of options that\n\
take a string as an arguement. Multiple options may follow the prefix. For\n\
example, '+qqq =lo listfile outfile' increases the quietness thrice, generates\n\
a listing to 'listfile', and outputs to 'outfile'.\n\
\n\
=l file		generate an assembly listing to 'file'\n\
=o prefix	use 'prefix' as the prefix to the output files. By default the\n\
		prefix is the input filename less everything after the last '.'\n\
\n\
+/-q		increase / decrease the quietness. This may be specified up to\n\
		three times in either direction for full effect.\n\
+/-s		enable / disable the printing of statistics on exit.\n\
+/-v		print version information."
	    );


    /** thrown to indicate the version. */

    Exception version( exit_clean, U3ASM_VERSION );
}



Program_options::Program_options( int &argc, char **&argv )
    : print_stats(false), verbosity(0), list_file(0)
{
    for( int i = 1 ; i < argc ; ++i )
    {
	switch( argv[i][0] ) {

	    case '-':
		if( argv[i][1] == '-' &&
		    argv[i][2] == '\0' )
		    return;

		for( int j = 1 ; argv[i][j] != '\0' ; ++j ) {
		    switch( argv[i][j] ) {
			case 'q':
			    ++verbosity;
			    break;

			case 's':
			    print_stats = false;
			    break;

			case 'h':
			    throw( usage );
			    break;

			case 'v':
			    throw( version );
			    break;

			default:
			    throw( Exception( exit_bad_args, std::string("unknown option -") + argv[i][j] ) );
			    break;
		    }
		}

		snarf_arg( argc, argv, i--);
		--argc;

		break;

	    case '+':
		for( int j = 1 ; argv[i][j] != '\0' ; ++j )
		{
		    switch( argv[i][j] ) {
			case 'q':
			    --verbosity;
			    break;

			case 's':
			    print_stats = true;
			    break;

			case 'h':
			    throw( usage );
			    break;

			case 'v':
			    throw( version );
			    break;

			default:
			    throw( Exception( exit_bad_args, std::string("unknown option +") + argv[i][j] ) );
			    break;
		    }
		}

		snarf_arg( argc, argv, i--);
		--argc;

		break;

	    case '=':
		for( int j = 1 ; argv[i][j] != '\0' ; ++j )
		{
		    switch( argv[i][j] )
		    {
			char const *snarfed_arg;

			case 'l':
			    snarfed_arg = snarf_arg( argc--, argv, i+1 );
			    if( snarfed_arg == 0 ) {
				throw( Exception( exit_bad_args, "=l requires a following parameter" ) );
			    }
			    if( list_file != 0 ) fclose( list_file );
			    list_file = fopen( snarfed_arg, "w" );
			    if( list_file == 0 )
				throw( Exception( exit_bad_args, std::string("unable to open file '") + snarfed_arg + "' for assembly listing" ) );
			    break;

			case 'o':
			    snarfed_arg = snarf_arg( argc--, argv, i+1 );
			    if( snarfed_arg == 0 ) {
				throw( Exception( exit_bad_args, "=o requires a following parameter" ) );
			    }
			    prefix = snarfed_arg;
			    break;

			default:
			    throw( Exception( exit_bad_args, std::string("unknown option =") + argv[i][j] ) );
			    break;
		    }
		}

		snarf_arg( argc, argv, i--);
		--argc;

		break;
	}
    }

    if( prefix.empty() ) {
	if( argc == 1 ) prefix = "<stdin>";
	else {
	    prefix = argv[1];
	    std::string::size_type pos = prefix.rfind( '.' );
	    if( pos != std::string::npos )
		prefix.resize( pos );
	}
    }
}
