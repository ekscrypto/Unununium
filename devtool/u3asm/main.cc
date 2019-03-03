/*
 * U3ASM
 * $Header: /cvsroot/uuu/devtool/u3asm/main.cc,v 2.6 2003/06/18 04:18:32 daboy Exp $
 * Copyright 2003 by Phil Frost; see file "License".
 */

/** \file main.cc
 *
 * definition of \c main(). */

#include "assembler.h"

#include <iostream>



Mem_stats mem_stats;



int main( int argc, char *argv[] )
{
    mem_stats.reset();
    bool print_mem_stats = false;
    exit_code code = exit_clean;
    unsigned error_count = 0, warning_count = 0;

    try {
	Program_options options( argc, argv );

	if( options.do_print_stats() ) print_mem_stats = true;

	Assembler assembler( options );

	extern Assembler *yyparse_asmblr;
	yyparse_asmblr = &assembler;

	try {
	    assembler.run();
	}
	catch( Exception const &e )
	{
	    /** \todo i'd like any std::exception thrown from assembler.run()
	     * to be caught, but the virtual what() function doesn't seem to be
	     * doing the virtual thing as I just get "fatal bug: St9exception"
	     * rather than the "unable to open..." I'd expect...  */
	    assembler.disp_error();
	    error_count = assembler.error_count;
	    warning_count = assembler.warning_count;
	    throw( e );
	}

	error_count = assembler.error_count;
	warning_count = assembler.warning_count;

	if( assembler.error_count ) code = exit_unknown;
    }

    catch( Exception const &e ) {
	std::cerr << e.what();
	if( e.code() == exit_bad_args )
	    std::cerr << " (u3asm +h for help)";
	std::cerr << std::endl;
	code = e.code();
    }
    catch( std::bad_alloc &e )
    {
	std::cerr << "Couldn't allocate memory. What kind of beast are you trying to assemble? ;-)" << std::endl;
    }
    catch( std::exception const &e )
    {
	std::cerr << "fatal bug: " << e.what() << std::endl
	    << "You hare probably found a bug in u3asm. Perhaps I should include instructions on\nerror reporting..."
	    << std::endl;
    }

    if( print_mem_stats ) {
	std::cerr
	    << "         errors: " << error_count
	    << "\n       warnings: " << warning_count
	    << "\n   calls to new: " << mem_stats.new_count()
	    << "\ncalls to delete: " << mem_stats.delete_count()
	    << std::endl;
    }
    return exit_clean;
}



/** \page syntax Syntax
 *
 * In the following sections the u3asm grammar is defined using BNF notation.
 * Elements in square brackets are optional. Elements in curly braces may repeat
 * zero or more times. Terminal symbols are in uppercase or in single quotes.
 *
 * Input is a string of statements. No delimiter is required between staments.
 *
 * \section comments comments
 *
 * Comments come in two flavors, single line and multiple line. Single line
 * comments are invoked by ';' and continue to the end of the line. Multiple
 * line comments are invoked by ';-' and continue to the matching '-;'. Multiple
 * line comments can be nested. Multiple line comments not need not use multiple
 * lines; they can just as readily comment a subsection of a line.
 *
 * \section statement-types statement types
 *
 * What follows is a terse, formal definition of all the possible statements.
 * Descriptions of the lower level elements such as strings,
 * immediate expressions, and label expressions follow.
 *
 * \subsection type-instruction instruction
 *
 * - <tt>instruction -> opcode [ operand [ ',' operand ... ] ]</tt>
 *
 * - <tt>instruction -> macro-name [ operand [ ',' operand ... ] ]</tt>
 *
 * \subsection type-label label definition
 *
 * - <tt>statement -> ':' label-expression</tt>
 *
 * defines the label \c label-expression
 *
 * - <tt>statement -> '{' label-expression</tt>
 *
 * starts a context within \c label-expression, but does not define \c
 * label-expression.
 *
 * - <tt>statement -> ':' '{' label-expression</tt>
 *
 * starts a context within \c label-expression and defines \c label-expression.
 *
 * - <tt>statement -> '}' [ label-expression ]</tt>
 *
 * ends a context. If \c label-expression is provided, it is checked against
 * that of the opening of the context and an error is issued if they do not
 * match.
 *
 * \subsection type-message message directive
 *
 * - <tt>statement -> '#error' STRING</tt>
 *
 * displays an error to stderr. This will ultimately cause assembly to fail.
 * However, the remainder of the input is still parsed.
 *
 * - <tt>statement -> '#warning' STRING</tt>
 *
 * displays a warning to stderr. This indicates something bad might have
 * happened, but only causes assembly to fail if the abort-on-warning option is
 * set.
 *
 * - <tt>statement -> '#remark' STRING</tt>
 *
 * displays a remark to stderr. This means nothing bad has happened. Remarks
 * never cause assembly to fail.
 *
 * \subsection type-conditional conditional directive
 *
 * Conditional expressions may be nested.
 *
 * - <tt>statement -> '#if' immediate-expression</tt>
 *
 * directs the assembler to process the following input if \c expression is
 * true.
 *
 * - <tt>statement -> '#fi'</tt>
 *
 * ends the conditional assembly invoked by \c #if
 *
 * \subsection type-misc miscellaneous directives
 *
 * - <tt>statement -> '#org' expression</tt>
 *
 * tells the assembler the following code will be loaded into memory at the
 * address \c expression. This effects the value of labels and usually provides
 * information to be placed in the output binary.
 *
 * - <tt>statement -> '#line' INTEGER [ STRING ]</tt>
 *
 * tells the assembler the following line is from line number \c INTEGER of file
 * \c STRING. If \c STRING is omitted, it is assumed to be the curent file. This
 * influences the error, warning, and remark messages output durring assembly.
 * This is useful when using an external program to generate input to u3asm.
 *
 * \section label-expressions label expressions
 *
 * The labels in u3asm, unlike most assemblers, are arranged in a hierarchial
 * manner rather than flatly. Labels are represented by a label expression,
 * which is very simular to file path names. '/' is used as the delimiter
 * between nodes, '..' represents the parent node, and '.' represents the curent
 * node. If a label expression does not begin with '/', it is relative to the
 * curent node. If it does begin with '/', it is relative to the root node. The
 * delimeter '/' is a token in itself, therefore '/' may be surrounded by any
 * whitespace if desired.
 *
 * The tokens between the optional '/' are strings. Thus, if you wish to define
 * a label with odd characters, quote it. However, it is often not necessary to
 * quote strings if they contain regular characters. See the next section for
 * details.
 *
 * \section strings strings
 *
 * Strings can be defined three ways, no quotes at all, with single quotes ('),
 * and with double quotes (").
 *
 * For a string to qualify for the cool quoteless variety, it must consist
 * entirely of letters, numbers, or the following characters: _ . # @ $
 *
 * If such a string begins with # or a digit, a warning is issued as it might
 * have been a number or directive that was mistyped. A commandline option to
 * supress this will be added in the future.
 *
 * The two remaining quoted types are identical except for the quote used. This
 * is to allow easy quoting of strings that contain quotes themselves. Within a
 * string, a backslash may be used to escape the special meaning of a character
 * or to include special characters. The following escapes are defined:
 *
 * - \\\\
 *	- a literal backslash
 * - \\n
 *	- a newline
 * - \\\<newline\>
 *	- exclude \<newline\> from the output. Can be used to write long one line
 *	strings on multiple lines.
 *
 * Anything else escaped is put verbatim into the string. Thus \ can be used to
 * escape quotes. More escape sequences will be defined in the future.
 */
