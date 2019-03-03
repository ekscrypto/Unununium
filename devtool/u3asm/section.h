/*
 * U3ASM
 * $Header: /cvsroot/uuu/devtool/u3asm/section.h,v 2.5 2003/06/24 01:48:51 daboy Exp $
 * Copyright 2003 by Phil Frost; see file "License".
 */

/** \file section.h
 *
 * class \c Section definition. */

#ifndef __SECTION_H__
#define __SECTION_H__

#include "conf.h"

#include <fstream>



/** a binary output section, as set by the \c #section directive. With each
 * section is associated two files, a binary and a symbol output file. */

class Section
{
    /// output file for the binary data
    std::ofstream	bin_file;

    /// the current offset; the value of \c $.
    immtype cur_offset;



    public:

    /** create a new section. The coresponding output files will be named \c
     * "prefix.name.bin" and "prefix.name.sym" for the binary and symbol files,
     * respectively.
     *
     * \param prefix	the prefix to the section name, usually the name of the
     * source file stripped of its extension. This effects nothing more than the
     * output filenames.
     *
     * \param name	the name of the section. This may affect entries in the
     * symbol table, so it should be the same name as used in the source. */

    Section( char const *prefix, char const *name );


    /** write an octet to the binary file.
     *
     * \param octet	the octet to write. */

    void put( uint8_t octet ) {
	bin_file.put( octet );
	++cur_offset;
    }


    /** get the current offset within the section (the value of $).
     *
     * \return the current offset within the section. */

    immtype get_offset() { return cur_offset; }


    /** set the current offset within the section (the value of $). Note this
     * doesn't actually move the assembly point; it only affects the values of
     * labels created.
     *
     * \param offset	the new offset to set */

    void set_offset( immtype offset ) { cur_offset = offset; }
};



#endif
