/*
 * U3ASM
 * $Header: /cvsroot/uuu/devtool/u3asm/lexer.h,v 2.2 2003/06/15 01:45:55 daboy Exp $
 * Copyright 2003 by Phil Frost; see file "License".
 */

/** \file lexer.h
 *
 * class \c Lexer definition */

#ifndef __LEXER_H__
#define __LEXER_H__

#include "conf.h"
#include <FlexLexer.h>

class Assembler;



/** a lexicographical scanner derived from one generated by the program \c
 * flex. */

class Lexer : public yyFlexLexer
{
    unsigned comment_depth;
    Assembler &assembler;

    int process_identifier();

    immtype scan_binary( const char *text );

    public:

    Lexer( Assembler &assembler )
	: yyFlexLexer(), comment_depth(0), assembler(assembler)
    { }

    int yylex();
};



#endif
