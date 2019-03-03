/*
 * U3ASM
 * $Header: /cvsroot/uuu/devtool/u3asm/yystype.h,v 2.2 2003/06/15 01:45:56 daboy Exp $
 * Copyright 2003 by Phil Frost; see file "License".
 */

/** \file yystype.h
 *
 * defines union \c yystype */

#ifndef __U3ASM_H__
#define __U3ASM_H__

#include "conf.h"

#include <string>

class Label;
class Instruction;



/** the semantical value of tokens used by the parser. See documentation for
 * the program \c bison, which generates the parser, for more information. */

union yystype {
    immtype		immediate;
    double		float_imm;
    Label		*label;
    std::string		*string;
    unsigned		reg;
    class Operand	*operand;
    struct {
	Instruction	*inst;
	std::string	*mnemonic;
    } instruction;
};

#define YYSTYPE union yystype



#endif
