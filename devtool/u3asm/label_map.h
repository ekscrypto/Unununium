/*
 * U3ASM
 * $Header: /cvsroot/uuu/devtool/u3asm/label_map.h,v 2.4 2003/06/17 04:33:53 daboy Exp $
 * Copyright 2003 by Phil Frost; see file "License".
 */

/** \file label_map.h
 *
 * class \c Label_map definition. */

#ifndef __LABEL_MAP_H__
#define __LABEL_MAP_H__

#include <map>
#include <string>

class Label;



/** A map that associates label names with \c Label classes. All the labels
 * referenced will be deleted upon the map's destruction. */

struct Label_map : std::map< std::string const, Label * >
{
    ~Label_map() {
	for( iterator i = begin() ; i != end() ; ++i )
	    delete i->second;
    }
};



#endif
