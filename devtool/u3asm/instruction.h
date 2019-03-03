/*
 * U3ASM
 * $Header: /cvsroot/uuu/devtool/u3asm/instruction.h,v 2.2 2003/06/15 01:45:55 daboy Exp $
 * Copyright 2003 by Phil Frost; see file "License".
 */

/** \file instruction.h
 *
 * class \c Instruction definition. */

#ifndef __INSTRUCTION_H__
#define __INSTRUCTION_H__

class Operand;
class Assembler;

#include <string>



/** any instruction, or fake instruction. This pure abstract class represents
 * anything that is syntactically like an instruction, which includes real
 * instructions like \c addi0, fake ones like \c d2, and in the future, perhaps
 * macros. */

struct Instruction
{
    /** a function called to encode the instruction. This function should
     * perform any validation of arguements required. If an error is
     * encountered, \c disp_error() should be called by this function and \c
     * false returned. This function can use the \c output() function to
     * generate output to the binary, although this is not a requirement.
     *
     * \param assembler		the \c Assembler to use for output, displaying
     * errors, etc.
     *
     * \param mnemonic		the mnemonic used to invoke the instruction.
     *
     * \param operand_count	the number of operands present in the invocation
     * of the instruction.
     *
     * \param operands		linked list of operands used in the invocation
     * of the instruction.
     *
     * \return true if the instruction was successfully encoded, false
     * otherwise.
     *
     * \todo convert the operand lists to use some STL container.  */

    virtual bool
	encode(
		Assembler &assembler,
		std::string const &mnemonic,
		unsigned operand_count = 0,
		Operand *operands = 0
	      ) = 0;
};



#endif
