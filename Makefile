all:
	yacc -d src/linker.y
	flex src/linker.flex
	gcc -o linker lex.yy.c y.tab.c
