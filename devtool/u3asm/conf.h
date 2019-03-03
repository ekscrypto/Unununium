/*
 * U3ASM
 * $Header: /cvsroot/uuu/devtool/u3asm/conf.h,v 2.3 2003/06/24 01:48:51 daboy Exp $
 * Copyright 2003 by Phil Frost; see file "License".
 */

/** \file conf.h
 *
 * miscellaneous definitions that may be interesting to twiddle at compile time.
 */

#ifndef __CONF_H__
#define __CONF_H__



#include <inttypes.h>

/// type used internally to represent immediate values, label values, etc.
typedef uint64_t immtype;

/** the number of characters to which to pad the binary part of aasembly
 * listings */
const unsigned list_pad_len = 55;

/** type used to represent a reference. */
typedef uint32_t refid;

#ifndef U3ASM_VERSION
/** a string representing the version number of u3asm. This is merely a default,
 * and is overridden from the makefile when making a release. */
#  define U3ASM_VERSION "custom built on " __DATE__ " " __TIME__
#endif



#endif
