all:
	yacc --debug --verbose -d src/linker.y
	flex src/linker.flex
	gcc -o linker lex.yy.c y.tab.c

install_user: 
	cp linker ~/bin/linker
