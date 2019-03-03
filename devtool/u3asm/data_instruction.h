/*
 * U3ASM
 * $Header: /cvsroot/uuu/devtool/u3asm/data_instruction.h,v 2.2 2003/06/15 01:45:55 daboy Exp $
 * Copyright 2003 by Phil Frost; see file "License".
 */

/** \file data_instruction.h
 *
 * class \c Data_instruction definition. */

#ifndef __DATA_INSTRUCTION_H__
#define __DATA_INSTRUCTION_H__

#include "instruction.h"



/** a type of instruction not corresponding to an opcode, yet directly
 * generating output. Examples are \c d0, \c d1, etc. */

struct Data_instruction : Instruction {
    bool encode( Assembler &assembler, std::string const &mnemonic, unsigned operand_count, Operand *operands);
};



#endif
