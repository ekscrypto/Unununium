/*
 * U3ASM
 * $Header: /cvsroot/uuu/devtool/u3asm/program_options.h,v 2.5 2003/06/24 01:48:51 daboy Exp $
 * Copyright 2003 by Phil Frost; see file "License".
 */

/** \file program_options.h
 *
 * class \c Program_options interface. */

#ifndef __PROGRAM_OPTIONS_H__
#define __PROGRAM_OPTIONS_H__

#include <stdio.h>
#include <string>



/** represents the options given to u3asm on the command line. */

class Program_options
{
    /// should statistics be printed upon program exit?
    bool print_stats;



    public:

    /** verbosity level. Can be negative to indicate quiteness. Settable by the
     * \c -v (less verbose) and the \c +v (more verbose) options. */
    char verbosity;

    /** file to which to output assembly listing. This is \c 0 if no listing
     * should be generated. This is settable by the \c =l option. */

    FILE *list_file;


    /** the base output filename. This is used as the first part of the output
     * file names and is settable by the \c =o option. */

    std::string prefix;


    /** dertime if a blurb of stats should be printed upon program exit. This
     * is settable by the \c +s (do print stats) or \c -s (do not) options.
     *
     * \return true if they should be printed, false otherwise. */

    bool do_print_stats() const { return print_stats; }


    /** construct a new \c Program_options from given command line arguments.
     * The \c argc and \c argv variables of the caller will be modified to
     * contain only the non-option arguements. */

    Program_options( int &argc, char **&argv );
};



#endif
