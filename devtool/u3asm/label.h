/*
 * U3ASM
 * $Header: /cvsroot/uuu/devtool/u3asm/label.h,v 2.3 2003/06/24 01:48:51 daboy Exp $
 * Copyright 2003 by Phil Frost; see file "License".
 */

/** \file label.h
 *
 * class \c Label definition. Actually, the definition is in \c
 * label_definition.h. The reason for the split is due to the interdependencies
 * with assembler.h.  */

#ifndef __LABEL_H__
#define __LABEL_H__

#include "label_definition.h"
#include "assembler.h"



inline Label::Label( Assembler &assembler ) :
defined(false),
    children(0),
    parent(this),
    ref_id( assembler.get_unique_refid() )
{ }



#endif
