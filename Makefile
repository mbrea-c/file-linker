all:
	yacc --debug --verbose -d src/linker.y
	flex src/linker.l
	gcc -Isrc -o linker lex.yy.c y.tab.c src/regex_util.c src/regex_util.h src/path_util.c src/path_util.h

install_user: 
	cp linker ~/bin/linker
