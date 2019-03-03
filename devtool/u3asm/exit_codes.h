/*
 * U3ASM
 * $Header: /cvsroot/uuu/devtool/u3asm/exit_codes.h,v 2.4 2003/06/17 04:33:53 daboy Exp $
 * Copyright 2003 by Phil Frost; see file "License".
 */

/** \file exit_codes.h
 *
 * defines the exit codes for the u3asm program and a general fatal error
 * exception. */

#ifndef __EXIT_CODES_H__
#define __EXIT_CODES_H__

#include <string>
#include <stdexcept>



/** all possible exit codes for u3asm. */

enum exit_code {
    /** this is what we would like to always be returned. */
    exit_clean = 0,

    /** a bad arguement was encountered while parsing the command-line options.
     */
    exit_bad_args,

    /** something bad happened when trying to write or open one of the output
     * files. */
    exit_file_output_error,

    /** something bad happened, but we arn't sure what. An #error directive can
     * cause this. */
    exit_unknown = -1
};



/** a general "something bad happened" exception. */

class Exception : public std::exception
{
    exit_code x;
    std::string wtf;

    public:

    /** construct an \c Exception with a given exit code and descriptive text.
     *
     * \param x		the \c exit_code to be returned by \c main(), should the
     * exception be fatal.
     *
     * \param what	descriptive text of what happened to cause the error. */

    Exception( exit_code x, std::string const &what ) : x(x), wtf( what ) { }


    /** get descriptive text for what happened.
     *
     * \return the descriptive text of what happened. */

    virtual char const *what() const throw() { return wtf.c_str(); }


    /** get the \c exit_code for the exception.
     *
     * \return \c exit_code that should be returned by main() if the exception
     * is fatal. */

    exit_code code() const { return x; }

    ~Exception() throw() { }
};



#endif
