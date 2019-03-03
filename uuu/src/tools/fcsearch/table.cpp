// table.cpp - (C)1999, 2000, 2001 Brad Bobak (bbobak@hotmail.com)


#include "table.h"

	void
table::init(uint is)
{
	cmp = 0;
	first = last = 0;
	number_blks  = 0;
	max_size = 0;
	current_size = 0;
	number_items = 0;
	max_items = 0;
	blok_size = 16;
	current = 0;
	item_size = is;
}

	void
table::fwd(uint num)
{
	for (;;)
	{
		if (!current)
			return;
		if (current_ofs + num < current->num_items)
		{
			current_ofs += num;
			return;
		}
		num -= current->num_items - current_ofs;
		current_ofs = 0;
		current = current->next;
	}
}

	void
table::bwd(uint num)
{
	for (;;)
	{
		if (!current)
			return;
		if (current_ofs >= num)
		{
			current_ofs -= num;
			return;
		}
		num -= current_ofs;
		current = current->prev;
		if (current)
			current_ofs = current->num_items;
	}
}

		uint
table::ins_before(void *obj)
{
	int i_before = -1;
	if (max_size  &&  current_size + item_size > max_size)
		return (0);
	if (max_items  &&  number_items + 1 > max_items)
		return (0);
	if (!current)
	{
		current = last;
		i_before = 0;
		if (current)
			current_ofs = current->num_items;
	}
	if (!current  ||  current->num_items >= blok_size)
	{
		/* need new blok */
		{
			blok *new_blk =
                (blok *)malloc(sizeof(blok));
			blok *ocurrent = current;
			if (!new_blk)
				return (0);
			new_blk->data = malloc(item_size * blok_size);
			if (!new_blk->data)
			{
                free(new_blk);
				return (0);
			}
			if (current)
			{
				uint left = current->num_items - current->num_items / 2;
				new_blk->num_items = current->num_items / 2;
				memcpy(new_blk->data,
					   (uchar *)current->data + left * item_size,
					   item_size * new_blk->num_items);
			}
			else
				new_blk->num_items = 0;
			new_blk->prev = current;
			if (current)
			{
				new_blk->next = current->next;
				if (current->next)
					current->next->prev = new_blk;
				else
					last = new_blk;
				current->next = new_blk;
			}
			else
			{
				new_blk->next = 0;
				first = last = new_blk;
				current_ofs = 0;
			}
			if (current  &&
				current_ofs >= current->num_items - (current->num_items / 2))
			{
				current_ofs -= current->num_items - (current->num_items / 2);
				current = new_blk;
			}
			if (i_before == 0)
			{
				current = new_blk;
				current_ofs = new_blk->num_items;
			}

			if (!ocurrent)
				current = new_blk;
			else
				ocurrent->num_items -= ocurrent->num_items / 2;
			number_blks += 1;
			current_size += item_size * blok_size;

		}
	}
	memmove((uchar *)current->data + (current_ofs+1) * item_size,
			(uchar *)current->data + current_ofs * item_size,
			item_size * (current->num_items - current_ofs));
	memcpy((uchar *)current->data + current_ofs * item_size, obj,
		   item_size);
	current_ofs += 1;
	number_items += 1;
	current->num_items += 1;

	if (i_before == 0)
		current = 0;
	return (1);
}

	void
table::search(void *obj, uint method)
{
	uint mid;
	uint l = 0;
	uint r;

	if (cmp == 0  ||  number_items == 0)
	{
		mknull();
		return;
	}

	r = number_items - 1;
	mid = (r - l) / 2;

	start();
	fwd(mid);

	for (;;)
	{
		int res = (*cmp)(obj,
						 (uchar *)current->data + current_ofs * item_size);
		if (l == r)
		{
			if (res == 0)
				return;
			if (res == -1)
			{
				if (method == TABLE_S_BIGGER)
					return;
				if (method == TABLE_S_EXACT)
				{
					mknull();
					return;
				}
				fwd();
				return;
			}
			if (res == 1)
			{
				if (method == TABLE_S_SMALLER)
					return;
				if (method == TABLE_S_EXACT)
				{
					mknull();
					return;
				}
				bwd();
				return;
			}
		}
		if (res < 0)
		{
			uint nmid;
			l = mid + 1;
			nmid = (r - l)/2 + l;
			fwd(nmid - mid);
			mid = nmid;
		}
		else if (res > 0)
		{
			uint nmid;
			r = mid;
			nmid = (r - l)/2 + l;
			bwd(mid - nmid);
			mid = nmid;
		}
		else
			return;
	}
}

	uint
table::ins(void *obj)
{
	search(obj, TABLE_S_SMALLER);

	return(ins_before(obj));
}

	void
table::clear()
{
	blok *blk;

	while (first)
	{
		blk = first->next;
        free(first->data);
        free(first);
		first = blk;
	}
	first = last = 0;
	current = 0;
	number_blks = 0;
	current_size = 0;
	number_items = 0;
}

	void
table::del()
{
	if (current)
	{
		memmove((uchar *)current->data + current_ofs * item_size,
				(uchar *)current->data + (current_ofs+1) * item_size,
				item_size * (current->num_items - current_ofs - 1));
		current->num_items -= 1;
		number_items -= 1;
		if (current->num_items == 0)
		{
			free(current->data);
			if (current->prev)
				current->prev->next = current->next;
			else
				first = current->next;
			if (current->next)
				current->next->prev = current->prev;
			else
				last = current->prev;
			current_size -= item_size * blok_size;
			number_blks -= 1;
			blok *next = current->next;
			free(current);
			current = next;
			current_ofs = 0;
		}
		if (current  && (current_ofs >= current->num_items))
		{
			current = current->next;
			current_ofs = 0;
		}
	}
}
