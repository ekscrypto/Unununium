/*
 * U3ASM
 * $Header: /cvsroot/uuu/devtool/u3asm/mem_stats.h,v 2.2 2003/06/23 23:42:05 daboy Exp $
 * Copyright 2003 by Phil Frost; see file "License".
 */

/** \file mem_stats.h
 *
 * redefines operators \c new and \c delete and defines a class that contains
 * memory statistics. */

#ifndef __MEM_STATS_H__
#define __MEM_STATS_H__

#include <malloc.h>
#include <stdexcept>



class Mem_stats
{
    friend void *operator new( size_t size ) throw( std::bad_alloc );
    friend void operator delete( void *stuff ) throw();

    unsigned news, deletes;

    public:

    unsigned new_count() { return news; }
    unsigned delete_count() { return deletes; }

    /** reset the counts. This should be called first thing in in \c main() so
     * allocations before \c main() is called don't affect the counts. */
    void reset() {
	news = deletes = 0;
    }
};



extern Mem_stats mem_stats;



inline void *operator new( std::size_t size ) throw( std::bad_alloc )
{
    void *stuff = malloc( size );
    if( !stuff )
	throw std::bad_alloc();
    ++mem_stats.news;
    return stuff;
}



inline void operator delete( void *stuff ) throw()
{
    free( stuff );
    ++mem_stats.deletes;
}



#endif
