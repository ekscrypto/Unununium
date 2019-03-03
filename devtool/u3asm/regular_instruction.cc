/*
 * U3ASM
 * $Header: /cvsroot/uuu/devtool/u3asm/regular_instruction.cc,v 2.7 2003/06/18 04:19:23 daboy Exp $
 * Copyright 2003 by Phil Frost; see file "License".
 */

/** \file regular_instruction.cc
 *
 * class \c Regular_instruction implementation. */

#include "regular_instruction.h"
#include "assembler.h"
#include "operand.h"



bool Regular_instruction::encode( Assembler &assembler, std::string const &mnemonic, unsigned operand_count, Operand *operands)
{
    unsigned octets_out = 0;	// number of octets that have been output by the instruction

    // check for correct number of operands //

    {
	if( operand_count != this->get_operand_count() ) {
	    assembler.disp_error()
		<< '\'' << mnemonic.c_str()
		<< "' used with "
		<< operand_count
		<< " operands, but requires "
		<< get_operand_count()
		<< std::endl;
	    return false;
	}
    }


    // encode the operands //

    {
	Operand *cur_operand = operands;

	for( unsigned i = operand_count; i != 0; --i )
	{
	    assert( cur_operand != 0 );

	    assembler.output_operand( *cur_operand );
	    ++octets_out;

	    cur_operand = cur_operand->next;
	}
    }


    // pad unused operands and encode the opcode //

    {
	if( operand_count == 3 )
	{
	    while( octets_out < 3 ) {
		assembler.output( 1, 0 );
		++octets_out;
	    }
	    assembler.output( 1, opcode );
	}
	else
	{
	    while( octets_out < 2 ) {
		assembler.output( 1, 0 );
		++octets_out;
	    }
	    assembler.output( 1, opcode );
	    assembler.output( 1, 0 );
	}
    }


    // encode immediate operands and add final padding //

    {
	char data_size;		// size of data, in bytes

	switch( mnemonic[mnemonic.size()-1] ) {
	    case '0':	data_size = 1; break;
	    case '1':	data_size = 2; break;
			// '2' goes to default
	    case '3':	data_size = 8; break;
	    default:	data_size = 4; break;
	}

	Operand *cur_operand = operands;
	octets_out = 0;

	for( unsigned i = operand_count; i != 0; --i )
	{
	    assert( cur_operand != 0 );

	    octets_out += assembler.output_immediate( data_size, *cur_operand );

	    cur_operand = cur_operand->next;
	}

	while( octets_out & 3 ) {
	    assembler.output( 1, 0 );
	    ++octets_out;
	}
    }

    return true;
}
