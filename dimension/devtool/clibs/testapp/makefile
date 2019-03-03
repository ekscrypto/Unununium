testapp.ubf: testapp.ha
	elf2ubf testapp.ha testapp.ubf
	rm testapp.ha

testapp.ha: testapp.o
	ld -r testapp.o ../stdio/stdio.o ../appwrap/appwrap.o -o testapp.ha

testapp.o: testapp.c
	gcc -c testapp.c -o testapp.o
	
.PHONY: clean 

clean:
	rm -f *.o
	rm -f *.ha
	rm -f *.ubf

