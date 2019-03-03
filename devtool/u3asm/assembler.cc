/*
 * U3ASM
 * $Header: /cvsroot/uuu/devtool/u3asm/assembler.cc,v 2.9 2003/06/29 13:39:51 daboy Exp $
 * Copyright 2003 by Phil Frost; see file "License".
 */

/** \file assembler.cc
 *
 * class \c Assembler implementation */

#include "assembler.h"
#include "operand.h"

#include <stdarg.h>

int yyparse();



Assembler::Assembler( Program_options const &options, char const *input_file ) :

next_refid(0),
    lex(*this),
    line_num(1),
    cur_file( input_file ),
    list_line_len(0),
    root_label(*this),
    error_count(0),
    warning_count(0),
options(options)

{
    sym_file.exceptions( std::ios_base::badbit | std::ios_base::failbit );

    std::string sym_filename( options.prefix + ".sym" );
    try {
	sym_file.open( sym_filename.c_str() );
    }
    catch( std::ios_base::failure const &e ) {
	throw( Exception( exit_file_output_error, "unable to open " + sym_filename + " for writing" ) );
    }

    instructions.add( "d0", new Data_instruction );
    instructions.add( "d1", new Data_instruction );
    instructions.add( "d2", new Data_instruction );
    instructions.add( "d3", new Data_instruction );

    cur_file = strdup( "<stdin>" );
}



void Assembler::run()
{
    yyparse();
}



void Assembler::output( unsigned char size, uint64_t data )
{
    assert( size == 1 || size == 2 || size == 4 || size == 8 );
    if( section_stack.empty() )
    {
	disp_warning() << "no section selected, picking default of 'default'" << std::endl;
	push_section( "default" );
    }

    if(
	    ( size == 4 && int64_t(data) > 0xFFFFFFFF	|| int64_t(data) < -0x7FFFFFFF)	||
	    ( size == 2 && int64_t(data) > 0xFFFF	|| int64_t(data) < -0x7FFF )	||
	    ( size == 1 && int64_t(data) > 0xFF		|| int64_t(data) < -0x7F )
      )
	disp_warning() << "immediate value " << data << " will be truncated" << std::endl;

    switch( size )
    {
	default:
	    section_stack.top()->put( data >> 7*8 & 0xFF );
	    list_output( " %02X", data >> 7*8 & 0xFF );
	    section_stack.top()->put( data >> 6*8 & 0xFF );
	    list_output( " %02X", data >> 6*8 & 0xFF );
	    section_stack.top()->put( data >> 5*8 & 0xFF );
	    list_output( " %02X", data >> 5*8 & 0xFF );
	    section_stack.top()->put( data >> 4*8 & 0xFF );
	    list_output( " %02X", data >> 4*8 & 0xFF );
	case 4:
	    section_stack.top()->put( data >> 3*8 & 0xFF );
	    list_output( " %02X", data >> 3*8 & 0xFF );
	    section_stack.top()->put( data >> 2*8 & 0xFF );
	    list_output( " %02X", data >> 2*8 & 0xFF );
	case 2:
	    section_stack.top()->put( data >> 1*8 & 0xFF );
	    list_output( " %02X", data >> 1*8 & 0xFF );
	case 1:
	    section_stack.top()->put( data >> 0*8 & 0xFF );
	    list_output( " %02X", data >> 0*8 & 0xFF );
	    break;
    }
}



unsigned Assembler::output_immediate( unsigned char size, Operand const &operand )
{
    assert( size == 1 || size == 2 || size == 4 || size == 8 );

    switch( operand.type )
    {
	case Operand::type_int:
	    output( size, operand.to_int().value );
	    return size;

	case Operand::type_float:
	    switch( size )
	    {
		case 8:
		    output( 8, *(immtype *)&operand.to_float().value );		// what trickery :)
		    return size;

		case 4:
		    output( 4, ( *(immtype *)&float(operand.to_float().value) ) & 0xFFFFFFFF );	// I can't even approach the insanity...
		    return size;

		case 2:
		    disp_warning()
			<< "float "
			<< operand.to_float().value
			<< " can't be represented in 2 bytes; rounded to a signed integer"
			<< std::endl;
		    output( 2, int16_t(operand.to_float().value) );
		    return size;

		case 1:
		    disp_warning()
			<< "float "
			<< operand.to_float().value
			<< " can't be represented in 1 byte; rounded to a signed integer"
			<< std::endl;
		    output( 1, int8_t(operand.to_float().value) );
		    return size;
	    }

	case Operand::type_label:
	    assert( operand.to_label().label != 0 );
	    output( size, operand.to_label().label->get_value() );
	    return size;

	default:
	    return 0;
    }
}



void Assembler::output_operand( Operand const &operand )
{
    switch( operand.type )
    {
	case Operand::type_int:
	case Operand::type_float:
	case Operand::type_label:
	    output( 1, 0xff );
	    break;

	case Operand::type_register:
	    output( 1, operand.to_register().value );
	    break;

	default:
	    assert( false );
	    break;
    }
}



void Assembler::list_output( const char *format, ... )
{
    va_list argptr;

    if( options.list_file ) {
	va_start( argptr, format );
	list_line_len += vfprintf( options.list_file, format, argptr );
	va_end( argptr );
    }
}



void Assembler::list_terminate() {
    if( options.list_file ) {
	fprintf( options.list_file, "\n" );
	list_line_len = 0;
    }
}



void Assembler::list_pad() {
    if( options.list_file ) {
	fprintf( options.list_file, "%*c",
		list_line_len < list_pad_len+1
		? list_line_len - list_pad_len+1
		: 0 ,
		' ' );
    }
}



void Assembler::list_output( Operand const &operand )
{
    switch( operand.type )
    {
	case Operand::type_int:
	    list_output( "%#llx", operand.to_int().value );
	    break;
	case Operand::type_float:
	    list_output( "%#g", operand.to_float().value );
	    break;
	case Operand::type_label:
	    list_output( "(label:%#x)", operand.to_label().label );
	    break;
	case Operand::type_register:
	    list_output( "r%.2X", operand.to_register().value );
	    break;
    }
}



std::ostream &Assembler::disp_error()
{
    std::cerr << get_file() << ": " << line_num << ": u3asm: error: ";
    ++error_count;
    return std::cerr;
}



std::ostream &Assembler::disp_warning()
{
    std::cerr << get_file() << ": " << line_num << ": u3asm: warning: ";
    ++warning_count;
    return std::cerr;
}



std::ostream &Assembler::disp_remark() const
{
    std::cerr << get_file() << ": " << line_num << ": u3asm: remark: ";
    return std::cerr;
}
