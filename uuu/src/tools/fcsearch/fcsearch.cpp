/* fcsearch - Function/Class id search for UUU
 *  Brad Bobak (bbobak@hotmail.com) 2001
 */

#include <stdio.h>
#include <errno.h>
#include <unistd.h>
#include <sys/types.h>
#include <signal.h>
#include <ctype.h>
#include <stdlib.h>

#ifndef SSIZE_MAX
#define SSIZE_MAX 1024
#endif

#include "table.h"

class reference
{
	public:
		char *class_name;
		char *func_name;

		int class_id;
		int func_id;
		int unknown_func;

		char *dep_file;
		char *dep_class;
		char *dep_func;
};

class file
{
	public:
		table exported_syms_by_class_func_name;
		table exported_syms_by_class_name_id;
		table imported_syms_by_class_func_name;
		table imported_syms_by_class_name_id;

		table dependancies; // of char *

		char *file_name;

			int
		init(char *fname);
};

class instance
{
	public:
		table file_by_file_name;

			int
		init();
};

	int
syms_by_class_func_cmp(void *a, void *b)
{
	reference *r1, *r2;
	memcpy(&r1, a, sizeof(reference *));
	memcpy(&r2, b, sizeof(reference *));
	if (r1->class_name == 0  &&  r2->class_name != 0)
		return (1);
	if (r1->class_name != 0  &&  r2->class_name == 0)
		return (-1);
	int res;
	if (r1->class_name  &&  r2->class_name)
	{
		res = strcmp(r1->class_name, r2->class_name);
		if (res < 0)
			return (1);
		if (res > 0)
			return (-1);
	}
	res = strcmp(r1->func_name, r2->func_name);
	if (res < 0)
		return (1);
	if (res > 0)
		return (-1);
	return (0);
}

	int
syms_by_class_id_cmp(void *a, void *b)
{
	reference *r1, *r2;
	memcpy(&r1, a, sizeof(reference *));
	memcpy(&r2, b, sizeof(reference *));
	if (r1->class_name == 0  &&  r2->class_name != 0)
		return (1);
	if (r1->class_name != 0  &&  r2->class_name == 0)
		return (-1);
	if (r1->class_id > r2->class_id)
		return (-1);
	if (r1->class_id < r2->class_id)
		return (1);
	if (r1->func_id > r2->func_id)
		return (-1);
	if (r1->func_id < r2->func_id)
		return (1);
	return (0);
}

	int
file_by_file_name_cmp(void *a, void *b)
{
	file *fa, *fb;
	memcpy(&fa, a, sizeof(file *));
	memcpy(&fb, b, sizeof(file *));
	int res = strcmp(fa->file_name, fb->file_name);

	if (res < 0)
		return (-1);
	if (res > 0)
		return (1);
	return (0);
}

	int
instance::init()
{
	file_by_file_name.init(sizeof(file *));
	file_by_file_name.set_cmp(file_by_file_name_cmp);
	return (1);
}

	int
file::init(char *fname)
{
	exported_syms_by_class_func_name.init(sizeof(reference *));
	imported_syms_by_class_func_name.init(sizeof(reference *));
	exported_syms_by_class_func_name.set_cmp(syms_by_class_func_cmp);
	imported_syms_by_class_func_name.set_cmp(syms_by_class_func_cmp);
	exported_syms_by_class_name_id.init(sizeof(reference *));
	exported_syms_by_class_name_id.set_cmp(syms_by_class_id_cmp);
	imported_syms_by_class_name_id.init(sizeof(reference *));
	imported_syms_by_class_name_id.set_cmp(syms_by_class_id_cmp);

	dependancies.init(sizeof(char *));

	file_name = (char *)malloc(strlen(fname)+1);
	if (!file_name)
		return (0);
	strcpy(file_name, fname);
	return (1);
}

	int
print_all(instance &inst)
{
	FILE *fp = fopen("cells.html", "w+");
	if (!fp)
		return (0);
	setbuf(fp, 0);
	fprintf(fp, "<html>\n");
	fprintf(fp, "<head><title>Unununium cell list</title></head>\n");
	fprintf(fp, "<body bgcolor=\"#000000\" text=\"#C0C0C0\">\n");
	fprintf(fp, "<br>\n");

	file *fl;
	inst.file_by_file_name.start();
	while (!inst.file_by_file_name.null())
	{
		inst.file_by_file_name.data(&fl);
		fprintf(fp, "[%s]<blockquote>\n", fl->file_name);
		fprintf(fp, "<font color=\"#00d700\">Exports:</font>\n");
		if (fl->exported_syms_by_class_name_id.num() > 0)
			fprintf(fp, "<blockquote>\n");
		else
			fprintf(fp, "<br>\n");
		int last_id = -1;
		fl->exported_syms_by_class_name_id.start();
		while (!fl->exported_syms_by_class_name_id.null())
		{
			reference *ref;
			fl->exported_syms_by_class_name_id.data(&ref);
			if (last_id == -1  ||  last_id != ref->class_id)
			{
				if (last_id != -1)
					fprintf(fp, "</blockquote>\n");
				last_id = ref->class_id;
				fprintf(fp, "<font color=\"#5070d0\">(%d) Class [%s]</font><blockquote>\n", ref->class_id, ref->class_name);
			}
			fprintf(fp, "<font color=\"#80e0ee\">(%d) %s</font><br>\n", ref->func_id, ref->func_name);
			fl->exported_syms_by_class_name_id.fwd();
		}
		if (last_id != -1)
			fprintf(fp, "</blockquote></blockquote>\n");
		fprintf(fp, "<font color=\"#00d700\">Imports:</font>\n");
		if (fl->imported_syms_by_class_name_id.num() > 0)
			fprintf(fp, "<blockquote>\n");
		else
			fprintf(fp, "<br>\n");
		fl->imported_syms_by_class_name_id.start();
		last_id = -1;
		while (!fl->imported_syms_by_class_name_id.null())
		{
			reference *ref;
			fl->imported_syms_by_class_name_id.data(&ref);
			if (last_id == -1  ||  last_id != ref->class_id)
			{
				if (last_id != -1)
					fprintf(fp, "</blockquote>\n");
				last_id = ref->class_id;
				fprintf(fp, "<font color=\"#5070d0\">(%d) Class [%s]</font><blockquote>\n", ref->class_id, ref->class_name);
			}
			fprintf(fp, "<font color=\"#80e0ee\">(%d) %s</font>\n", ref->func_id, ref->func_name);
			if (ref->dep_file)
				fprintf(fp, "<font color=\"#ffff00\">{%s}</font>\n", ref->dep_file);
			else
				fprintf(fp, "<font color=\"#00ffff\">{Unknown source}</font>\n");
			fprintf(fp, "<br>\n");
			fl->imported_syms_by_class_name_id.fwd();
		}
		if (last_id != -1)
			fprintf(fp, "</blockquote></blockquote>\n");
		fprintf(fp, "<font color=\"#00d700\">Dependancies:</font>\n");
		if (fl->dependancies.num() > 0)
			fprintf(fp, "<blockquote>\n");
		else
			fprintf(fp, "<br>\n");
		fl->dependancies.start();
		while (!fl->dependancies.null())
		{
			char *dat;
			fl->dependancies.data(&dat);
			fprintf(fp, "<font color=\"#ff00ff\">%s</font><br>\n", dat);
			fl->dependancies.fwd();
		}
		if (fl->dependancies.num() > 0)
			fprintf(fp, "</blockquote>\n");
		fprintf(fp, "</blockquote>\n");
		inst.file_by_file_name.fwd();
	}
	fprintf(fp, "</body>\n");
	fclose(fp);
	return (1);
}


	int
scan_file(file *fl);
	file *
scan_obj_output(char *filename, instance &inst);
	int
find_dependancies(instance &inst);
	int
find_all_dependancies(instance &inst);

	int
main(int argc, char **argv)
{
	setbuf(stdout, 0);
	if (argc < 2)
	{
		fprintf(stderr, "use : fcsearch obj_file obj_file...\n");
		exit (1);
	}
	unlink("cells.html");

	instance inst;
	inst.init();

	int ct;
	for (ct = 1; ct < argc; ct++)
	{
		file *fl = scan_obj_output(argv[ct], inst);
		if (!fl)
			exit (1);
		scan_file(fl);
#if 0
		fl->exported_syms_by_class_func_name.start();
		while (!fl->exported_syms_by_class_func_name.null())
		{
			reference *ref;
			fl->exported_syms_by_class_func_name.data(&ref);
			printf("class [%s](%d) fiunc [%s](%d) unk [%d]\n", ref->class_name, ref->class_id, ref->func_name, ref->func_id, ref->unknown_func);
			fl->exported_syms_by_class_func_name.fwd();
		}
#endif

	}
	find_dependancies(inst);
	find_all_dependancies(inst);
	print_all(inst);
	exit (0);
}

// 0 == no dup, 1 == dup
	int
scan_dep_table_for_file_name_match(file *fl, char *dup)
{
	fl->dependancies.start();
	while (!fl->dependancies.null())
	{
		char *res;
		fl->dependancies.data(&res);
		if (!strcmp(res, dup))
			return (1);
		fl->dependancies.fwd();
	}
	return (0);
}

	int
scan_imported_sym_list(file *fl)
{
	int at_pos = 0;

	for (;;)
	{
		fl->imported_syms_by_class_func_name.start();
		fl->imported_syms_by_class_func_name.fwd(at_pos);
		if (fl->imported_syms_by_class_func_name.null())
			break;
		reference *ref;
		fl->imported_syms_by_class_func_name.data(&ref);
		if (!ref->dep_file)
		{
			at_pos += 1;
			continue;
		}
		if (!scan_dep_table_for_file_name_match(fl, ref->dep_file))
		{
			fl->dependancies.mknull();
			if (!fl->dependancies.ins_before(&ref->dep_file))
				return (0);
		}
		at_pos += 1;
	}
	return (1);
}

	int
find_all_dependancies(instance &inst)
{
	int at_pos = 0;
	for (;;)
	{
		inst.file_by_file_name.start();
		inst.file_by_file_name.fwd(at_pos);
		if (inst.file_by_file_name.null())
			break;
		file *fl;
		inst.file_by_file_name.data(&fl);
		fl->dependancies.start();
		if (!fl->dependancies.ins_before(&fl->file_name))
			return (0);
		if (!scan_imported_sym_list(fl))
			return (0);
		fl->dependancies.start();
		fl->dependancies.del();
		at_pos += 1;
	}
	return (1);
}

	int
scan_for_class_func(instance &inst, reference *ref, char **fn, reference **ref_2)
{
	inst.file_by_file_name.start();
	while (!inst.file_by_file_name.null())
	{
		file *fl;
		inst.file_by_file_name.data(&fl);
		fl->exported_syms_by_class_func_name.start();
		while (!fl->exported_syms_by_class_func_name.null())
		{
			reference *r;
			fl->exported_syms_by_class_func_name.data(&r);
			if (!r->class_name ||  !ref->class_name || strcmp(r->func_name, ref->func_name)
			||  strcmp(r->class_name, ref->class_name))
			{
				fl->exported_syms_by_class_func_name.fwd();
				continue;
			}
			*fn = fl->file_name;
			*ref_2 = r;
			return (1);
		}
		inst.file_by_file_name.fwd();
	}
	return (0);
}

	int
find_dependancies(instance &inst)
{
	int at_pos = 0;
	for (;;)
	{
		inst.file_by_file_name.start();
		inst.file_by_file_name.fwd(at_pos);
		if (inst.file_by_file_name.null())
			break;
		file *fl;
		inst.file_by_file_name.data(&fl);
		int at_pos_imp = 0;
		for (;;)
		{
			fl->imported_syms_by_class_func_name.start();
			fl->imported_syms_by_class_func_name.fwd(at_pos_imp);
			if (fl->imported_syms_by_class_func_name.null())
				break;
			reference *ref;
			fl->imported_syms_by_class_func_name.data(&ref);
			char *fn;
			reference *ref_2;
			int res = scan_for_class_func(inst, ref, &fn, &ref_2);
			if (res == 0)
			{
				fprintf(stderr, "Dependancy for [%s][%s] not found.\n", ref->class_name, ref->func_name);
				at_pos_imp += 1;
				continue;
			}
			ref->dep_file = fn;
			ref->dep_class  = ref_2->class_name;
			ref->dep_func = ref_2->func_name;
			ref->class_id = ref_2->class_id;
			ref->func_id = ref_2->func_id;
			if (!fl->imported_syms_by_class_name_id.ins(&ref))
				return (0);
			at_pos_imp += 1;
		}
		at_pos += 1;
	}
	return (1);
}

	int
parse_line(char *filename, char *buf, instance &inst, int &found_sym, file *fl);

	file *
scan_obj_output(char *filename, instance &inst)
{
	int io[2];
	if (pipe(io) == -1)
	{
		fprintf(stderr, "Error creating pipe -- %s\n", strerror(errno));
		exit (1);
	}

	int pid = fork();
	if (!pid) // we child??
	{
		close(io[0]);
		if (!dup2(io[1], 1))
		{
			fprintf(stderr, "Error creating pipe -- %s\n", strerror(errno));
			exit (1);
		}
		execlp("objdump", "objdump", "-x", filename, 0);
		fprintf(stderr, "Error running objdump -- %s\n", strerror(errno));
		exit (1);
	}
	// we're parent, wait for data
	close(io[1]);

	char buf[SSIZE_MAX + 1];
	int  buf_pos = 0;
	int found_sym = 0;
	file *fl = (file *)malloc(sizeof(file));
	if (!fl)
	{
		fprintf(stderr, "mem error\n");
		kill(9, pid);
		return (0);
	}
	if (!fl->init(filename))
	{
		fprintf(stderr, "mem error\n");
		free(fl);
		kill(9, pid);
		return (0);
	}
	if (!inst.file_by_file_name.ins(&fl))
	{
		free(fl->file_name);
		free(fl);
		fprintf(stderr, "mem error\n");
		kill(9, pid);
		return (0);
	}
	for (;;)
	{
		int res = read(io[0], buf + buf_pos, SSIZE_MAX - buf_pos);
		if (res == -1)
		{
			fprintf(stderr, "Error reading pipe -- %s\n", strerror(errno));
			kill(9, pid);
			free(fl->file_name);
			free(fl);
			exit (1);
		}
		if (res == 0)
		{
			close(io[0]);
			break;
		}
		buf[buf_pos + res] = 0;
		char *buf_wlk = buf;
		for (;;)
		{
		// BUG if buf[buflen] ends witht he first '\n'
			if (buf_wlk[0] == '\n'  &&  buf_wlk[1] == '\n')
				return (fl);
			char *buf_p = buf_wlk;
			while (buf_p[0])
			{
				if (buf_p[0] == '\n')
				{
					if (!found_sym)
						break;
					break;
				}
				buf_p += 1;
			}
			if (buf_p[0] == 0)
				break;
			buf_p[0] = 0;
			if (!parse_line(filename, buf_wlk, inst, found_sym, fl))
			{
				close(io[0]);
				exit (1);
			}
			buf_p[0] = '\n';
			buf_wlk = buf_p + 1;
		}
		memmove(buf, buf_wlk, strlen(buf_wlk) + 1);
		buf_pos = strlen(buf_wlk);

	}
	return (fl);
}

	int
proc_func(char *buf, file *fl);
	int
proc_class(char *buf, file *fl);

	int
parse_line(char *filename, char *buf, instance &inst, int &found_sym, file *fl)
{
	if (!found_sym)
	{
		if (strncmp(buf, "SYMBOL TABLE:", 13) != 0)
			return (1);
		found_sym = 1;
	}
	if (strstr(buf, "__FID__") != 0)
		return (proc_func(buf, fl));
	if (strstr(buf, "__CID__") != 0)
		return (proc_class(buf, fl));
	return (1);
}

	int
proc_func(char *buf, file *fl)
{
	reference *ref = (reference *)malloc(sizeof(reference));
	if (!ref)
		return (0);

	char *mark = strstr(buf, "__FID__");
	mark += 8;
	ref->func_name = (char *)malloc(strlen(mark)+1);
	if (!ref->func_name)
	{
		free(ref);
		return (0);
	}
	strcpy(ref->func_name, mark);
	ref->func_id = strtol(buf, 0, 16);
	ref->class_name = 0;
	if (buf[9] == 'g')
	{
		if (!fl->exported_syms_by_class_func_name.ins(&ref))
		{
			free(ref->func_name);
			free(ref);
			return (0);
		}
	}
	else
	{
		if (!fl->imported_syms_by_class_func_name.ins(&ref))
		{
			free(ref->func_name);
			free(ref);
			return (0);
		}
	}
	return (1);
}

	int
proc_class(char *buf, file *fl)
{
	reference *ref = (reference *)malloc(sizeof(reference));	
	if (!ref)
		return (0);
	ref->dep_file = 0;
	char *mark = strstr(buf, "__CID__");
	mark += 8;
	char *walk = mark + strlen(mark);
	while (walk[0] != '.'  &&  walk > mark)
		walk -= 1;
	if (walk == mark)
	{
		free(ref);
		return (0);
	}
	walk[0] = 0;
	ref->func_name = (char *)malloc(strlen(mark)+1);
	if (!ref->func_name)
	{
		free(ref);
		return (0);
	}
	strcpy(ref->func_name, mark);
	walk[0] = '.';
	mark = walk + 1;
	ref->class_name = (char *)malloc(strlen(mark)+1);
	if (!ref->class_name)
	{
		free(ref->func_name);
		free(ref);
		return (0);
	}
	strcpy(ref->class_name, mark);
	ref->class_id = strtol(buf, 0, 16);
	ref->unknown_func = 1;

	if (buf[9] == 'g')
	{
		if (!fl->exported_syms_by_class_func_name.ins(&ref))
		{
			free(ref->class_name);
			free(ref->func_name);
			free(ref);
			return (0);
		}
	}
	else
	{
		if (!fl->imported_syms_by_class_func_name.ins(&ref))
		{
			free(ref->class_name);
			free(ref->func_name);
			free(ref);
			return (0);
		}
	}
	return (1);
}


// scan thru all files w/o classes and see if we can find a class for them
// either way, we delete the func entry and notify if no class matches the
// func.

	char *
find_class_from_func_ex(file *fl, char *func_name)
{
	fl->exported_syms_by_class_func_name.start();
	for (;;)
	{
		if (fl->exported_syms_by_class_func_name.null())
			break;
		reference *ref;
		fl->exported_syms_by_class_func_name.data(&ref);
		if (ref->class_name  &&  !strcmp(ref->func_name, func_name))
			return (ref->class_name);
		fl->exported_syms_by_class_func_name.fwd();
	}
	return (0);
}

	char *
find_class_from_func_im(file *fl, char *func_name)
{
	fl->imported_syms_by_class_func_name.start();
	for (;;)
	{
		if (fl->imported_syms_by_class_func_name.null())
			break;
		reference *ref;
		fl->imported_syms_by_class_func_name.data(&ref);
		if (ref->class_name  &&  !strcmp(ref->func_name, func_name))
			return (ref->class_name);
		fl->imported_syms_by_class_func_name.fwd();
	}
	return (0);
}

	int
scan_file(file *fl)
{
	for (;;)
	{
		fl->exported_syms_by_class_func_name.start();
		if (fl->exported_syms_by_class_func_name.null())
			break;
		reference *ref;
		fl->exported_syms_by_class_func_name.data(&ref);
		if (ref->class_name != 0)
			break;
		char *res = find_class_from_func_ex(fl, ref->func_name);
		if (res == 0)
		{
			fprintf(stderr, "func [%s] declared, but no matching class\n", ref->func_name);
			return (0);
		}
		int f_id = ref->func_id;
		fl->exported_syms_by_class_func_name.data(&ref);
		ref->unknown_func = 0;
		ref->func_id = f_id;
		if (!fl->exported_syms_by_class_name_id.ins(&ref))
			return (0);
		fl->exported_syms_by_class_func_name.start();
		fl->exported_syms_by_class_func_name.del();
	}
	for (;;)
	{
		fl->imported_syms_by_class_func_name.start();
		if (fl->imported_syms_by_class_func_name.null())
			break;
		reference *ref;
		fl->imported_syms_by_class_func_name.data(&ref);
		if (ref->class_name != 0)
			break;
		char *res = find_class_from_func_im(fl, ref->func_name);
		if (res == 0)
		{
			fprintf(stderr, "func [%s] declared, but no matching class\n", ref->func_name);
			return (0);
		}
		int f_id = ref->func_id;
		fl->imported_syms_by_class_func_name.data(&ref);
		ref->unknown_func = 0;
		ref->func_id = f_id;
		fl->imported_syms_by_class_func_name.start();
fl->imported_syms_by_class_func_name.data(&ref);
		fl->imported_syms_by_class_func_name.del();
	}
	return (1);
}


