all:
	yacc --debug --verbose -d src/linker.y
	flex src/linker.l
	gcc -o linker lex.yy.c y.tab.c

install_user: 
	cp linker ~/bin/linker
