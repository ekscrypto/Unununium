/*
 * U3ASM
 * $Header: /cvsroot/uuu/devtool/u3asm/operand.h,v 2.2 2003/06/24 01:48:51 daboy Exp $
 * Copyright 2003 by Phil Frost; see file "License".
 */

/** \file operand.h
 *
 * classes and functions pertaining to the manipulation of instruction operands.
 *
 * \todo update this system to be more C++ish. */

#ifndef __OPERAND_H__
#define __OPERAND_H__

#include "conf.h"

class Label;



struct Operand_int;
struct Operand_float;
struct Operand_label;
struct Operand_register;



/** an instruction operand. */

struct Operand
{
    Operand		*next;

    enum types {
	type_int,
	type_float,
	type_label,
	type_register,
    } type;

    Operand( types type ) : next(0), type(type) { }

    Operand_int const &to_int() const {
	assert( type == type_int );
	return *(Operand_int *)this;
    }

    Operand_float const &to_float() const {
	assert( type == type_float );
	return *(Operand_float *)this;
    }

    Operand_label const &to_label() const {
	assert( type == type_label );
	return *(Operand_label *)this;
    }

    Operand_register const &to_register() const {
	assert( type == type_register );
	return *(Operand_register *)this;
    }
};



struct Operand_int : Operand {
    Operand_int() : Operand(Operand::type_int) { }
    immtype		value;
};

struct Operand_float : Operand
{
    Operand_float() : Operand(Operand::type_float) { }
    double		value;
};

struct Operand_label : Operand
{
    Operand_label() : Operand(Operand::type_label) { }
    Label		*label;
    Operand_int		offset;
};

struct Operand_register : Operand
{
    Operand_register() : Operand(Operand::type_register) { }
    unsigned char	value;
};


#endif
