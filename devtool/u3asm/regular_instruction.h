/*
 * U3ASM
 * $Header: /cvsroot/uuu/devtool/u3asm/regular_instruction.h,v 2.2 2003/06/15 01:45:56 daboy Exp $
 * Copyright 2003 by Phil Frost; see file "License".
 */

/** \file regular_instruction.h
 *
 * class \c Regular_instruction definition. */

#ifndef __REGULAR_INSTRUCTION_H__
#define __REGULAR_INSTRUCTION_H__

#include "instruction.h"



/** an \c Instruction that coresponds directly with an opcode defined by the
 * Bismuth virtual machine. In Bismuth, unlike some other machines, instruction
 * mnemonics and opcodes corespond uniquely. Also, no distinction is made
 * between a given mnemonic with differing amounts of operands. */

class Regular_instruction : public Instruction
{
    /// coresponding opcode for encoding.
    unsigned char	opcode;

    /** number of operands required. From this is derived the encoding class. */
    unsigned		operand_count;

    public:

    /** create a new \c Regular_instruction with a given operand count and
     * opcode.
     *
     * \param operand_count	the number of operands taken by the
     * instruction.
     *
     * \param opcode		the opcode of the instruction. */

    Regular_instruction( unsigned operand_count, unsigned char opcode ) {
	this->operand_count = operand_count;
	this->opcode = opcode;
    }


    /** get the number of operands taken by this instruction.
     *
     * \return the number of operands taken by this instruction */
    unsigned get_operand_count() { return operand_count; }

    virtual bool encode( Assembler &assembler, std::string const &mnemonic, unsigned operand_count, Operand *operands);
};



#endif
