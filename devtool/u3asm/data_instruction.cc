/*
 * U3ASM
 * $Header: /cvsroot/uuu/devtool/u3asm/data_instruction.cc,v 2.5 2003/06/18 04:18:32 daboy Exp $
 * Copyright 2003 by Phil Frost; see file "License".
 */

/** \file data_instruction.cc
 *
 * class \c Data_instruction implementation. */

#include "operand.h"
#include "assembler.h"



bool Data_instruction::encode( Assembler &assembler, std::string const &mnemonic, unsigned operand_count, Operand *operands)
{
    char data_size;		// size of data, in bytes

    switch( mnemonic[1] ) {
	case '0':	data_size = 1; break;
	case '1':	data_size = 2; break;
	// '2' goes to default
	case '3':	data_size = 8; break;
	default:	data_size = 4; break;
    }

    while( operands != 0 )
    {
	switch( operands->type )
	{
	    case Operand::type_int:
	    case Operand::type_float:
	    case Operand::type_label:
		assembler.output_immediate( data_size, *operands );
		break;
	    default:
		assembler.disp_error() << "invalid type of arguement to d" << mnemonic[1] << std::endl;
		return -1;
	}
	operands = operands->next;
    }
    return true;
}
