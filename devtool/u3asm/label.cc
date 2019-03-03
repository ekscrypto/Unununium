/*
 * U3ASM
 * $Header: /cvsroot/uuu/devtool/u3asm/label.cc,v 2.3 2003/06/29 13:39:52 daboy Exp $
 * Copyright 2003 by Phil Frost; see file "License".
 */

/** \file label.cc
 *
 * class \c Label implementation. */

#include "label.h"
#include "label_map.h"

#include <stdio.h>



void Label::dump_children( unsigned indent, std::string const &name, std::vector<char> &delim ) const
{
    fprintf( stderr, "%3u %p", this->ref_id, this );
    fprintf( stderr, "\tvalue: " );
    if( is_defined() )
	fprintf( stderr, "%.16llX", get_value() );
    else
	fprintf( stderr, "(  undefined   )" );
    fprintf( stderr, "\tchildren: %p  ", children );
    fprintf( stderr, "\tparent: %p\t", parent );

    if( indent ) {
	for( unsigned j = 0 ; j < indent - 1 ; j++ ) {
	    fprintf( stderr, "%c   ", delim[j] );
	}
	fprintf( stderr, "%c-- ", delim[indent-1] );
    }

    fprintf( stderr, "%s\n", name.c_str() );

    if( indent > 0 && delim[indent-1] == '`' ) {
	delim[indent-1] = ' ';
    }

    if( children )
    {
	unsigned count = 1;

	for( Label_map::iterator i = children->begin() ; i != children->end() ; ++i )
	{
	    Label *label = i->second;

	    if( delim.size() <= indent ) delim.push_back('|');

	    if( count == children->size() )
		delim[indent] = '`';
	    else
		delim[indent] = '|';

	    label->dump_children( indent + 1, i->first, delim );

	    ++count;
	}
    }
}



Label *Label::get_child( std::string const &name )
{
    if( name[0] == '.' ) {
	if( name[1] == '.' && name[2] == '\0' )
	    return parent;
	if( name[1] == '\0' )
	    return this;
    }

    if( children == 0 ) return 0;

    Label_map::iterator i = children->find( name );
    if( i == children->end() ) return 0;
    return i->second;
}



bool Label::add_child( std::string const &name, Label &child )
{
    if( children == 0 ) children = new Label_map;

    bool added = children->insert( Label_map::value_type( name, &child ) ).second;
    if( added ) child.parent = this;
    return added;
}
