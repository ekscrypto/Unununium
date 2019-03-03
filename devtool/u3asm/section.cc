/*
 * U3ASM
 * $Header: /cvsroot/uuu/devtool/u3asm/section.cc,v 2.3 2003/06/17 11:50:02 daboy Exp $
 * Copyright 2003 by Phil Frost; see file "License".
 */

/** \file section.cc
 *
 * class \c Section implementation. */

#include "section.h"
#include "exit_codes.h"



Section::Section( char const *prefix, char const *name ) : cur_offset(0)
{
    assert( prefix );
    assert( name );

    bin_file.exceptions( std::ios_base::badbit | std::ios_base::failbit );

    std::string filename( prefix );
    filename.append( "." );
    filename.append( name );
    filename.append( ".bin" );

    try {
	bin_file.open( filename.c_str() );
    }
    catch( std::ios_base::failure const &e ) {
	throw( Exception( exit_file_output_error, "unable to open " + filename + " for writing" ) );
    }
}

