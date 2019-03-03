/*
	    fprintf( stderr, "freeing redefined instruction\n" );
 * U3ASM
 * $Header: /cvsroot/uuu/devtool/u3asm/parse.y,v 2.10 2003/07/01 01:02:48 daboy Exp $
 * Copyright 2003 by Phil Frost; see file "License".
 */

%{

/** \file parse.cc
 *
 * the parser, generated from \c parse.y by the program \c bison.
 *
 * \todo enable a structure '\ expression' to parse as a register constant
 * (\c rE0 - \c rFF). */

/** \file parse.h
 *
 * token values for the parser and lexer, generated from \c parse.y by the
 * program \c bison. */

#include "regular_instruction.h"
#include "assembler.h"
#include "operand.h"

#include <stack>
#include <sstream>



#define YYERROR_VERBOSE
void yyerror(const char *s);

int yylex();

/// number of operands in instruction being parsed
unsigned operand_count = 0;

/** a kludge to indicate the \c Assembler that should be a parameter to \c
 * yyparse().
 *
 * \todo find a way to get around this kludge. */
Assembler *yyparse_asmblr;


/** a stack to hold the label contexts created by '{' */

struct Label_context_stack : std::stack<Label *>
{
    void pop() {
	if( size() <= 1 ) {
	    yyparse_asmblr->disp_error()
		<< "'}' encountered but no label context is open" << std::endl;
	    return;
	}

	std::stack<Label *>::pop();
    }

} label_context_stack;



/** the label being closed with \c }. This is used to check that the following
 * identifier, if present, matches the opening identifier. */

Label const *closing_context;



/** add a related group of instructions. This is used to support the semantics
 * of the \c #opcode directive.
 *
 * \param mnemonic	the base part of the mnemonic, such as "add".
 *
 * \param operand_count	the number of operands taken by the instruction.
 *
 * \param suffixes	a string indicating the valid suffixes. Each character
 * in the string enables a set of instructions. The defined sets are "i" for
 * integer, "f" for float, "g" for generic, and "." meaning no suffix.
 *
 * \param opcode	the base opcode to be used to encode the instruction.
 * The proper value will be added to this for each suffix. */

void add_instruction_group(
	const char *mnemonic,
	unsigned operand_count,
	const char *suffixes,
	unsigned opcode	);



%}


%union {
    immtype		immediate;
    double		float_imm;
    Label		*label;
    std::string		*string;
    unsigned		reg;
    Operand		*operand;
    struct {
	Instruction	*inst;
	std::string	*mnemonic;
    } instruction;
}

%type <immediate> int_imm_exp
%type <float_imm> float_imm_exp
%type <label> identifier
%type <operand> operand operands

%token	T_NE	"/="
%token	T_GT_EQ	">="	T_LT_EQ	"<="
%token	T_LOR	"||"	T_LAND	"&&"
%token	T_SHL	"<<"	T_SHR	">>"

%left T_LOR
%left T_LAND
%left '|' '^'
%left '&'
%nonassoc '=' T_NE
%nonassoc '<' '>' T_GT_EQ T_LT_EQ
%left T_SHL T_SHR
%left '-' '+'
%left '*' '/' '%'
%left T_NEG '~' '!'

%token <reg>T_REGISTER
%token T_STRING

%token <instruction>T_MNEMONIC	<string>T_STRING
%token <immediate>T_INTEGER_IMM	<float_imm>T_FLOAT_IMM

%token	T_MACRO		"#macro"	T_ORCAM		"#orcam"
%token	T_SECTION	"#section"
%token	T_PUSHSECTION	"#pushsection"	T_POPSECTION	"#popsection"
%token	T_ORG		"#org"		T_ERROR		"#error"
%token	T_WARNING	"#warning"	T_REMARK	"#remark"
%token	T_LINE		"#line"		T_OPCODE	"#opcode"
%token	T_DEBUG		"#debug"	T_DUMPLABELS	"#dumplabels"


%debug

%defines

%%



input:
	/* empty */
	| {
	    assert( yyparse_asmblr );
	    label_context_stack.push( &yyparse_asmblr->root_label );
	} statements {
	    if( label_context_stack.size() != 1 )
		yyparse_asmblr->disp_error()
		    << label_context_stack.size() - 1
		    << " label context(s) open and end of parsing"
		    << std::endl;
	}
;



statements:
	statement
	| statements statement
;



statement:

	// instruction //

		{ yyparse_asmblr->list_output( "%08x ", yyparse_asmblr->get_section().get_offset() ); }
	instruction
		{ yyparse_asmblr->list_terminate();
		operand_count = 0; }


	// directives //

	| T_DUMPLABELS		{ yyparse_asmblr->root_label.dump_children(); }
	| T_DEBUG		{ yydebug ^= -1; }
	| T_MACRO T_STRING	{ delete $2; }
	| T_ORCAM		{ yyparse_asmblr->disp_error() << "\"#orcam\" without matching \"#macro\"" << std::endl; }
	| T_SECTION T_STRING	{ yyparse_asmblr->change_section( *$2 ); delete $2; }
	| T_PUSHSECTION T_STRING{ yyparse_asmblr->push_section( *$2 ); delete $2; }
	| T_POPSECTION		{ yyparse_asmblr->pop_section(); }
	| T_ERROR T_STRING	{ yyparse_asmblr->disp_error() << *$2 << std::endl; delete $2; }
	| T_WARNING T_STRING	{ yyparse_asmblr->disp_warning() << *$2 << std::endl; delete $2; }
	| T_REMARK T_STRING	{ yyparse_asmblr->disp_remark() << *$2 << std::endl; delete $2; }
	| T_ORG int_imm_exp	{ yyparse_asmblr->get_section().set_offset( $2 ); }
	| T_ORG error		{ yyparse_asmblr->disp_error() << "a valid immediate expression must follow #org" << std::endl; yyerrok; }
	| T_LINE T_INTEGER_IMM T_STRING
				{ yyparse_asmblr->set_line( $2 - 1 ); yyparse_asmblr->set_file( *$3 ); delete $3; }
	| T_LINE T_INTEGER_IMM	{ yyparse_asmblr->set_line( $2 - 1 ); }
	| T_OPCODE T_STRING T_INTEGER_IMM T_STRING T_INTEGER_IMM
				{ add_instruction_group( $2->c_str(), $3, $4->c_str(), $5 ); delete $2; delete $4; }


	// error //

	| error			// we don't want to use yyerrok because there's no clear way to tell when the error is over.


	// label definitions //

	| ':' identifier {

	    if( $2->is_defined() )
		yyparse_asmblr->disp_error() << "label redefined" << std::endl;
	    else {
		$2->define( yyparse_asmblr->get_section().get_offset() );
	    }
	}

	| ':' '{' identifier {

	    if( $3->is_defined() )
		yyparse_asmblr->disp_error() << "label redefined" << std::endl;
	    else {
		$3->define( yyparse_asmblr->get_section().get_offset() );
		label_context_stack.push( $3 );
	    }
	}

	| '{' identifier '=' int_imm_exp {

	    if( $2->is_defined() )
		yyparse_asmblr->disp_error() << "label redefined" << std::endl;
	    else {
		$2->define( $4 );
		label_context_stack.push( $2 );
	    }
	}

	| '{' identifier {

	    label_context_stack.push( $2 );
	}

	| '{' {
	    static unsigned id = 0;

	    std::stringstream unique;
	    unique << "anonymous" << ++id << ':' << yyparse_asmblr->get_file() << ':' << yyparse_asmblr->get_line();

	    assert( label_context_stack.top() != 0 );
	    Label *annon_label = label_context_stack.top()->get_or_create_child( *yyparse_asmblr, unique.str().c_str() );
	    label_context_stack.push( annon_label );
	}


	| ':' identifier '=' int_imm_exp {
	    if( $2->is_defined() )
		yyparse_asmblr->disp_error() << "label redefined" << std::endl;
	    else {
		$2->define( $4 );
	    }
	}

	| '}'	{ label_context_stack.pop(); }

	| '}'		{ closing_context = label_context_stack.top();
			  label_context_stack.pop(); }
	  identifier	{ if( $3 != closing_context ) yyparse_asmblr->disp_error() << "opening and closing contexts do not match" << std::endl; }
;



identifier:
	T_STRING {
	    assert( label_context_stack.top() != 0 );
	    $$ = label_context_stack.top()->get_or_create_child( *yyparse_asmblr, *$1 );
	    delete $1;
	}
	| identifier '/' T_STRING {
	    $$ = $1->get_or_create_child( *yyparse_asmblr, *$3 );
	    delete $3;
	}
	| '/' T_STRING {
	    $$ = yyparse_asmblr->root_label.get_or_create_child( *yyparse_asmblr, *$2 );
	    delete $2;
	}
;



instruction:
	T_MNEMONIC
		{ yyparse_asmblr->list_output( "%s", $1.mnemonic->c_str() );
		yyparse_asmblr->list_pad();
		assert( yyparse_asmblr != 0 );
		$1.inst->encode( *yyparse_asmblr, *$1.mnemonic );
		delete $1.mnemonic; }

	| T_MNEMONIC
		{ yyparse_asmblr->list_output( "%s ", $1.mnemonic->c_str() ); }
	  operands
		{ Operand *cur_operand = $3;
		yyparse_asmblr->list_output( *cur_operand );
		cur_operand = cur_operand->next;
		while( cur_operand ) {
		    yyparse_asmblr->list_output( ", " );
		    yyparse_asmblr->list_output( *cur_operand );
		    cur_operand = cur_operand->next;
		}
		yyparse_asmblr->list_pad();
		assert( yyparse_asmblr != 0 );
		$1.inst->encode( *yyparse_asmblr, *$1.mnemonic, operand_count, $3 );
		delete $1.mnemonic;

		cur_operand = $3;
		for( unsigned i = operand_count; i != 0; --i ) {
		    Operand *prev_operand = cur_operand;
		    cur_operand = cur_operand->next;
		    delete prev_operand;
		}
		}
;



operands:
	operand			{ $$ = $1; operand_count = 1; }
	| operand ',' operands	{ $1->next = $3; $$ = $1; ++operand_count; }
;



operand:
	T_REGISTER {
	    Operand_register *op = new Operand_register;
	    op->value = $1;
	    $$ = op;
	}
	| float_imm_exp {
	    Operand_float *op = new Operand_float;
	    op->value = $1;
	    $$ = op;
	}
	| int_imm_exp {
	    Operand_int *op = new Operand_int;
	    op->value = $1;
	    $$ = op;
	}
	| identifier {
	    Operand_label *op = new Operand_label;
	    op->label = $1;
	    $$ = op;
	}
;


float_imm_exp:
	T_FLOAT_IMM				{ $$ = $1; }
	| float_imm_exp '=' float_imm_exp	{ $$ = $1 == $3; }
	| float_imm_exp T_NE float_imm_exp	{ $$ = $1 != $3; }
	| float_imm_exp '<' float_imm_exp	{ $$ = $1 < $3; }
	| float_imm_exp '>' float_imm_exp	{ $$ = $1 > $3; }
	| float_imm_exp T_GT_EQ float_imm_exp	{ $$ = $1 >= $3; }
	| float_imm_exp T_LT_EQ float_imm_exp	{ $$ = $1 <= $3; }
	| float_imm_exp '+' float_imm_exp	{ $$ = $1 + $3; }
	| float_imm_exp '-' float_imm_exp	{ $$ = $1 - $3; }
	| float_imm_exp '*' float_imm_exp	{ $$ = $1 * $3; }
	| float_imm_exp '/' float_imm_exp	{ $$ = $1 / $3; }
	| '-' float_imm_exp %prec T_NEG		{ $$ = -$2; }
	| '+' float_imm_exp %prec T_NEG		{ $$ = +$2; }
	| '!' float_imm_exp			{ $$ = !$2; }
	| '(' float_imm_exp ')'			{ $$ = $2 }
;

int_imm_exp:
	T_INTEGER_IMM				{ $$ = $1; }
	| int_imm_exp T_LOR int_imm_exp		{ $$ = $1 || $3; }
	| int_imm_exp T_LAND int_imm_exp	{ $$ = $1 && $3; }
	| int_imm_exp '|' int_imm_exp		{ $$ = $1 | $3; }
	| int_imm_exp '^' int_imm_exp		{ $$ = $1 ^ $3; }
	| int_imm_exp '&' int_imm_exp		{ $$ = $1 & $3; }
	| int_imm_exp '=' int_imm_exp		{ $$ = $1 == $3; }
	| int_imm_exp T_NE int_imm_exp		{ $$ = $1 != $3; }
	| int_imm_exp '<' int_imm_exp		{ $$ = $1 < $3; }
	| int_imm_exp '>' int_imm_exp		{ $$ = $1 > $3; }
	| int_imm_exp T_GT_EQ int_imm_exp	{ $$ = $1 >= $3; }
	| int_imm_exp T_LT_EQ int_imm_exp	{ $$ = $1 <= $3; }
	| int_imm_exp T_SHR int_imm_exp		{ $$ = $1 >> $3; }
	| int_imm_exp T_SHL int_imm_exp		{ $$ = $1 << $3; }
	| int_imm_exp '+' int_imm_exp		{ $$ = $1 + $3; }
	| int_imm_exp '-' int_imm_exp		{ $$ = $1 - $3; }
	| int_imm_exp '*' int_imm_exp		{ $$ = $1 * $3; }
	| int_imm_exp '/' int_imm_exp		{ $$ = $1 / $3; }
	| int_imm_exp '%' int_imm_exp		{ $$ = $1 % $3; }
	| '-' int_imm_exp %prec T_NEG		{ $$ = -$2; }
	| '+' int_imm_exp %prec T_NEG		{ $$ = +$2; }
	| '~' int_imm_exp			{ $$ = ~$2; }
	| '!' int_imm_exp			{ $$ = !$2; }
	| '(' int_imm_exp ')'			{ $$ = $2 }
;



%%



/** a kludge as \c yyparse() can't directly call the C++ lexer.
 *
 * \todo find a way around this. */
int yylex()
{
    assert( yyparse_asmblr != 0 );
    return yyparse_asmblr->get_token();
}



void yyerror (const char *s)  /* Called by yyparse on error */
{
    yyparse_asmblr->disp_error() << s << std::endl;
}



void add_instruction_group(
	const char *mnemonic,
	unsigned operand_count,
	const char *suffixes,
	unsigned opcode )
{
    unsigned count = 0;

    const char *cur_suffix;
    std::string temp_mnemonic( mnemonic );
    unsigned base_length = temp_mnemonic.size();

    for( cur_suffix = suffixes; *cur_suffix != '\0'; ++cur_suffix ) {
	switch( *cur_suffix ) {
	    case 'i':
		temp_mnemonic.resize( base_length + 2 );
		temp_mnemonic[base_length] = 'i';

		temp_mnemonic[base_length+1] = '0';
		yyparse_asmblr->instructions.add( temp_mnemonic, new Regular_instruction(operand_count, opcode) );

		temp_mnemonic[base_length+1] = '1';
		yyparse_asmblr->instructions.add( temp_mnemonic, new Regular_instruction(operand_count, opcode+1) );

		temp_mnemonic[base_length+1] = '2';
		yyparse_asmblr->instructions.add( temp_mnemonic, new Regular_instruction(operand_count, opcode+2) );

		temp_mnemonic[base_length+1] = '3';
		yyparse_asmblr->instructions.add( temp_mnemonic, new Regular_instruction(operand_count, opcode+3) );

		temp_mnemonic.resize( base_length );
		count += 4;
		break;

	    case 'f':
		temp_mnemonic.resize( base_length + 2 );
		temp_mnemonic[base_length] = 'f';

		temp_mnemonic[base_length+1] = '2';
		yyparse_asmblr->instructions.add( temp_mnemonic, new Regular_instruction(operand_count, opcode+7) );

		temp_mnemonic[base_length+1] = '3';
		yyparse_asmblr->instructions.add( temp_mnemonic, new Regular_instruction(operand_count, opcode+6) );

		temp_mnemonic.resize( base_length );
		count += 2;
		break;

	    case 'g':
		temp_mnemonic.resize( base_length + 1 );

		temp_mnemonic[base_length] = '0';
		yyparse_asmblr->instructions.add( temp_mnemonic, new Regular_instruction(operand_count, opcode+0) );

		temp_mnemonic[base_length] = '1';
		yyparse_asmblr->instructions.add( temp_mnemonic, new Regular_instruction(operand_count, opcode+1) );

		temp_mnemonic[base_length] = '2';
		yyparse_asmblr->instructions.add( temp_mnemonic, new Regular_instruction(operand_count, opcode+2) );

		temp_mnemonic[base_length] = '3';
		yyparse_asmblr->instructions.add( temp_mnemonic, new Regular_instruction(operand_count, opcode+3) );

		temp_mnemonic.resize( base_length );
		count += 4;
		break;

	    case '.':
		yyparse_asmblr->instructions.add( temp_mnemonic, new Regular_instruction(operand_count, opcode+0) );

		count += 1;
		break;

	    default:
		yyparse_asmblr->disp_error() << "unrecognized suffix type " << *cur_suffix << std::endl;
		return;
	}
    }

    if( yyparse_asmblr->options.verbosity >= 4 ) yyparse_asmblr->disp_remark() << count << " instructions added" << std::endl;
}
