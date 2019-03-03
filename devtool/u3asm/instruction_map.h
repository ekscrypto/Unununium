/*
 * U3ASM
 * $Header: /cvsroot/uuu/devtool/u3asm/instruction_map.h,v 2.4 2003/07/01 00:33:30 daboy Exp $
 * Copyright 2003 by Phil Frost; see file "License".
 */

/** \file instruction_map.h
 *
 * class \c Instruction_map interface */

#ifndef __INSTRUCTION_MAP_H__
#define __INSTRUCTION_MAP_H__

#include <map>



/** A map which associates mnemonics with \c Instruction classes. All the
 * instructions reference in the table will be deleted on destruction of this.
 */

struct Instruction_map : std::map< std::string const, class Instruction * >
{

    /** get an entry in this map.
     *
     * \param mnemonic	the mnominc coresponding to the instruction to be found.
     * Zero terminated.
     *
     * \return pointer to the matching \c Instruction, or \c 0 if no such
     * instruction exists. */

    Instruction *get( std::string const &mnemonic ) const
    {
	Instruction_map::const_iterator i = find( mnemonic );
	if( i == end() ) { return 0; }
	else return i->second;
    }



    ~Instruction_map() {
	for( iterator i = begin() ; i != end() ; ++i )
	    delete i->second;
    }



    /** add an instruction to this map. If the instruction is already defined,
     * the old definition will be replaced.
     *
     * \param mnemonic	full mnemonic for the instruction. Zero terminated. This
     * will be copied and need not remain valid.
     *
     * \param inst		the \c Instruction to add. */

    void add( std::string const &mnemonic, Instruction *inst )
    {
	std::pair< iterator, bool > i = insert( std::pair< std::string const, class Instruction * >( mnemonic, inst ) );
	if( ! i.second ) {
	    delete i.first->second;
	    i.first->second = inst;
	}
    }
};



#endif
