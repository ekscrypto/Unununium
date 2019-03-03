/*
 * U3ASM
 * $Header: /cvsroot/uuu/devtool/u3asm/label_definition.h,v 2.2 2003/06/29 13:39:52 daboy Exp $
 * Copyright 2003 by Phil Frost; see file "License".
 */

/** \file label_definition.h
 *
 * the real definition of class \c Label. Except in \c assembler.h, \c label.h
 * should be included instead. This weirdness is due to the interdependencies
 * between those two. */

#ifndef __LABEL_DEFINITION_H__
#define __LABEL_DEFINITION_H__

#include "conf.h"

#include <string>
#include <assert.h>
#include <vector>

class Assembler;
namespace std { template< class T, class U > class vector; }



/** a label, as created by the \c : and \c { operators. */

class Label
{
    /** the value of the label, valid iff \c is_defined(). */
    immtype value;

    /** true iff the value is defined. */
    bool defined;

    /** a map of the child labels. This is initially set to 0 and is created
     * on demand. The children '.' and '..' are handled specially and are not in
     * this table. */
    class Label_map *children;

    /** the parent of this label. Also, the label to which '..' referes. If this
     * is the root label, \c parent is a pointer to the root label. This should
     * never be \c 0. */
    Label *parent;

    /** the unique reference ID for this label. */
    refid ref_id;


    public:

    /** create a new undefined label. */

    inline Label( Assembler &assembler );


    /** determine if this label is defined.
     *
     * \return \c true iff label is defined */

    bool is_defined() const { return defined; };


    /** define or redefine this label's value.
     *
     * \param value the new value. */

    void define( immtype value ) {
	this->value = value;
	defined = true;
    }


    /** get the value of this label.
     *
     * \return value of this label. */

    immtype get_value() const { return value; }


    /** get a child label of this label by name.
     *
     * \param name	name of the label to get.
     *
     * \return pointer to said label, \c 0 if no such label exists. */

    Label *get_child( std::string const &name );


    /** get a child label of this label by name, or create it if it does not
     * exist.
     *
     * \param assembler	\c Assembler in which to create the label.
     *
     * \param name	name of the label to get.
     *
     * \return pointer to said label. If it does not exist, it is created with
     * an undefined value. */

    Label *get_or_create_child( Assembler &assembler, std::string const &name ) {
	Label *child = get_child( name );
	if( child == 0 ) {
	    child = new Label( assembler );
	    add_child( name, *child );
	}
	assert( child != 0 );
	return child;
    }


    /** add a label to the children of this label with a given name. If a label
     * by that name already exists, it will not be overwritten. A label may have
     * only one parent.
     *
     * \param name	name of the label to add.
     *
     * \param child	reference to the label to add.
     *
     * \return \c true if \p child was added, \c false if a label by \p name
     * already exists. */

    bool add_child( std::string const &name, Label &child );


    /** dump information for this label's children to \c stderr.
     *
     * \param indent	indentation level; used internally for recursion. Use
     * default of \c 0.
     *
     * \param name	name of the label; used internally for recursion.
     *
     * \param delim	delimiter to be used; used internally for recursion. */
    void dump_children( unsigned indent = 0, std::string const &name = "*", std::vector<char> &delim = *new std::vector<char> ) const;
};



#endif
