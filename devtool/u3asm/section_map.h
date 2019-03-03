/*
 * U3ASM
 * $Header: /cvsroot/uuu/devtool/u3asm/section_map.h,v 2.1 2003/06/16 05:03:06 daboy Exp $
 * Copyright 2003 by Phil Frost; see file "License".
 */

/** \file section_map.h
 *
 * class \c Section_map definition. */

#ifndef __SECTION_MAP_H__
#define __SECTION_MAP_H__

#include "section.h"

#include <map>
#include <string>



/** A map that associates section names with \c Section classes. All the
 * sections within the map will be deleted upon the map's destruction. */

struct Section_map : std::map< std::string const, Section * >
{
    ~Section_map() {
	for( iterator i = begin() ; i != end() ; ++i )
	    delete i->second;
    }
};



#endif
