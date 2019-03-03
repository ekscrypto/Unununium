/*
 * U3ASM
 * $Header: /cvsroot/uuu/devtool/u3asm/assembler.h,v 2.8 2003/06/24 01:48:51 daboy Exp $
 * Copyright 2003 by Phil Frost; see file "License".
 */

/** \file assembler.h
 *
 * class \c Assembler definition */

#ifndef __ASSEMBLER_H__
#define __ASSEMBLER_H__

#include "lexer.h"
#include "data_instruction.h"
#include "instruction_map.h"
#include "section_map.h"
#include "label_definition.h"
#include "program_options.h"
#include "exit_codes.h"

#include <stack>




/** a machine that reads an input file and generates the output files. This is
 * almost the state of the entire program. The only thing preventing one from
 * creating multiple assembler classes is the parser. Bison does have an option
 * to create a reenterant parser; I have not yet implemented it. */

class Assembler
{
    /** the next reference ID to be used to create a label. */
    refid next_refid;

    /** a flex generated lexicographical scanner used to tokenize the input. */
    Lexer lex;

    /// the line number within the file currently being parsed.
    unsigned line_num;


    /** indicates the file currently being parsed. This does not need to be the
     * real filename of the input file, but rather it can indicate the original
     * source of the input. The \c #line directive manipulates this.  */

    std::string cur_file;


    /// the length of the current list file line
    unsigned list_line_len;

    /// output file for the symbol table
    std::ofstream	sym_file;

    /** the section table. */
    Section_map sections;


    /** a stack of sections, with the top element being currently selected. This
     * can be manipulated via the \c #section, \# pushsection, and \c
     * #popsection directives. */

    std::stack< Section * > section_stack;


    /** get a a named section, creating it and adding it to \c sections if it
     * does not exist.
     *
     * \param name	name of the section
     *
     * \return reference to \c Section named \p name. */

    Section &get_or_create_section( std::string const &name ) {
	if( sections.find( name ) == sections.end() ) {
	    Section *new_sect = new Section( options.prefix.c_str(), name.c_str() );
	    sections[name] = new_sect;
	    return *new_sect;
	}
	else
	    return *sections[name];
    }



    public:

    /** get the current section
     *
     * \return reference to the currently active section.
     *
     * \see change_section(), pop_section(), push_section() */

    Section &get_section() {
	if( section_stack.empty() )
	{
	    disp_warning() << "no section selected, picking default of 'default'" << std::endl;
	    push_section( "default" );
	}
	assert( section_stack.top() != 0 );
	return *section_stack.top();
    }


    /** write an entry to the symbol file. */

    void add_sym( Label const &label );


    /** output an 8, 16, 32, or 64 bit quantity.
     *
     * \param size	size of quantity, in bytes
     *
     * \param data	data to output */

    void output( unsigned char size, uint64_t data );


    /** output an \c Operand as an immediate value.
     *
     * For integers the value is output, and a warning is issued if it is
     * out of range.
     *
     * For floats, the value is output if the size is 4 or 8. If the size is
     * 1 or 2, the float will be rounded to a signed integer of that size,
     * output, and a fitting warning issued.
     *
     * For labels proper entries in the output symbol table are made and the
     * value is output. If the label is undefined, 0 is output, which will be
     * fixed on a seccond pass after the assembler knows the values of all
     * labels, or at runtime by the loader, if the label is external.
     *
     * For registers this does nothing.
     *
     * \param size	size of quantity, in bytes. This should be one of 1, 2,
     * 4, or 8.
     *
     * \param operand	the \c Operand to output.
     *
     * \return number of bytes output */

    unsigned output_immediate( unsigned char size, Operand const &operand );


    /** output an \c Operand as an instruction operand. This is useful in the
     * encoding of instructions. For labels, integers, and floats 0xFF is
     * output. For registers, the register number is output. In all cases, one
     * byte is output.
     *
     * \param operand	the \c Operand to output. */

    void output_operand( Operand const &operand );


    /** write to the assembly listing in a printf way. */

    void list_output( const char *format, ... );


    /** write an operand to the assembly listing */

    void list_output( Operand const &operand );


    /** terminate the current line of the assembly listing. */

    void list_terminate();


    /** pad the assembly listing to the binary part. This should be used after
     * outputting the textual part and before the binary part.
     *
     * \see list_pad_len */

    void list_pad();


    /** get the current line number. This does not have to be the real line
     * number; it can be the line number of any source, such as an included
     * file. This is useful in generating messages that reference specific
     * areas of the code.
     *
     * \return current line number */

    unsigned get_line() const { return line_num; }


    /** set the current line number. This is useful if the input ultimately
     * came from another source, such as an included file.
     *
     * \param line	the new line number.
     *
     * \see \c get_line()
     * \see \c next_line() */

    void set_line( unsigned line ) { line_num = line; }


    /** advance the current line number as reported by \c get_line() to the
     * next line of input. This is generally useful only in the parser.
     *
     * \see \c get_line()
     * \see \c set_line() */

    void next_line() { ++line_num; }


    /** get the current input file. This need not be the real name of the input
     * file; rather it can be the name of the ultimate source of the input,
     * such as in included file.
     *
     * \see \c set_file() */
    char const *get_file() const { return cur_file.c_str(); }


    /** set the current input file. This does not change the actual input file,
     * but only affects the output of error messages.
     *
     * \see \c get_file() */

    void set_file( std::string const &file ) {
	cur_file = file;
    }


    /** change the current section. The section is created if it does not
     * exist.
     *
     * \param section	name of the section to which to switch.
     *
     * \see \c push_section(), \c pop_section() */

    void change_section( std::string const &section ) {
	if( section_stack.empty() )
	    push_section( section );
	else
	    section_stack.top() = &get_or_create_section( section );
    }


    /** push a section on to the current section stack.
     *
     * \param section	name of the section to push.
     *
     * \see \c change_section(), \c pop_section() */

    void push_section( std::string const &section ) {
	section_stack.push( &get_or_create_section( section ) );
    }


    /** pop a section from the current section stack.
     *
     * \see \c push_section(), \c change_section() */

    void pop_section() {
	if( section_stack.empty() )
	    disp_error() << "section stack underflow: excess #popsection" << std::endl;
	else
	    section_stack.pop();
    }


    /** the instruction table. This holds all the valid instructions. It is
     * initialized only with the data instructions such as \c d0, but not
     * regular bismuth instructions, such as \c addi2. The latter is
     * accomplished by \c #opcode directives, which would generally be in an
     * included file. */

    Instruction_map instructions;


    /// The root label in the label hierarchy.
    Label root_label;

    /// the number of errors encountered.
    unsigned error_count;

    /// the number of warnings encountered.
    unsigned warning_count;

    /// the options from the command line.
    Program_options const &options;

    /// run the assembler, parsing the input file and generating output files.
    void run();


    /** use to display an error message. This will output some header
     * information like the current file and line number and then return a
     * stream to which the rest of the message can be written. The message
     * should be terminated with \c std::endl or should a newline and then
     * flushed.
     *
     * \return reference to a stream to which the message should be written. */

    std::ostream &disp_error();


    /** use to display a warning message. See \c disp_error() for verbose
     * description.
     *
     * \return reference to a stream to which the message should be written. */

    std::ostream &disp_warning();


    /** use to display a remark message. See \c disp_error() for verbose
     * description.
     *
     * \return reference to a stream to which the message should be written. */

    std::ostream &disp_remark() const;


    /** get the next token from the input file. This is used by the parser. */

    int get_token() { return lex.yylex(); }


    /** construct a new \c Assembler.
     *
     * \param options	an object reference representing the command line
     * options. This must remain valid for the life of the \c Assembler.
     *
     * \param input_file	the initial value of the file reported by \c
     * get_file(). This has no effect on the actual file read; that is set in
     * \p options. */

    Assembler( Program_options const &options, char const *input_file = "<stdin>" );


    /** get a unique reference ID. This is used when creating new \c Label
     * classes. */

    refid get_unique_refid() { return next_refid++; }
};



#include "label.h"



#endif
