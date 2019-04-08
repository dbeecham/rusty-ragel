#########################################
# VARIABLES - overridable by make flags #
#########################################
# {{{

# Stuff to set in CFLAGS:
#   -march=native
#       speed! Don't use for cross compilation.
#   -fpie -Wl,-pie
#       don't use along with -fPIE and -shared for shared libraries
CFLAGS         = -Iinc -Wall -Wextra \
                 -Wno-implicit-fallthrough -Wno-unused-const-variable \
                 -std=c11 -g3 -Os -D_FORTIFY_SOURCE=2 -fexceptions \
                 -fasynchronous-unwind-tables -fpie -Wl,-pie \
                 -fstack-protector-strong -grecord-gcc-switches \
                 -Werror=format-security \
                 -Werror=implicit-function-declaration -Wl,-z,defs -Wl,-z,now \
                 -Wl,-z,relro $(EXTRA_CFLAGS)
LDFLAGS        = $(EXTRA_LDFLAGS)
LDLIBS         = -luv -lnats $(EXTRA_LDLIBS)
DESTDIR        = /
PREFIX         = /usr/local
RAGEL          = ragel
RAGELFLAGS     = -G2 $(EXTRA_RAGELFLAGS)
INSTALL        = install
BEAR           = bear
COMPLEXITY     = complexity
CFLOW          = cflow
NEATO          = neato
CTAGS          = ctags
Q              = @
CC_COLOR       = \033[0;34m
LD_COLOR       = \033[0;33m
TEST_COLOR     = \033[0;35m
INSTALL_COLOR  = \033[0;32m
NO_COLOR       = \033[m

default: all

all: libnatsparser.a

libnatsparser.a: natsparser.o


################
# SOURCE PATHS #
################

vpath %.c src/
vpath %.c.rst src/
vpath %.c.md src/
vpath %.c.rl src/
vpath %.c.rl.md src/
vpath %.c.rl.rst src/
vpath %.h include/
vpath munit.c vendor/munit/
vpath test_%.c tests/



##################
# IMPLICIT RULES #
##################

%: %.o
	@echo "$(LD_COLOR)LD$(NO_COLOR) $@"
	$(Q)$(CC) $(LDFLAGS) -o $@ $^ $(LOADLIBES) $(LDLIBS)

%.a:
	@echo "$(LD_COLOR)AR$(NO_COLOR) $@"
	$(Q)$(AR) rcs $@ $^

%.so:
	@echo "$(LD_COLOR)LD$(NO_COLOR) $@"
	$(Q)$(CC) $(LDFLAGS) -shared -o $@ $^ $(LOADLIBES) $(LDLIBS)

%.o: %.c
	@echo "$(CC_COLOR)CC$(NO_COLOR) $@"
	$(Q)$(CC) -c $(CFLAGS) $(CPPFLAGS) -o $@ $^

# for each c file, it's possible to generate a cflow flow graph.
%.c.cflow: %.c
	@echo "$(CC_COLOR)CC$(NO_COLOR) $@"
	$(Q)$(CFLOW) -o $@ $<

%.png: %.dot
	@echo "$(CC_COLOR)CC$(NO_COLOR) $@"
	$(Q)$(NEATO) -Tpng -Ln100 -o $@ $<

%.dot: %.rl
	@echo "$(CC_COLOR)CC$(NO_COLOR) $@"
	$(Q)$(RAGEL) $(RAGELFLAGS) -V -p $< -o $@

%.c: %.c.rl
	@echo "$(CC_COLOR)CC$(NO_COLOR) $@"
	$(Q)$(RAGEL) -Iinclude $(RAGELFLAGS) -o $@ $<

%.c: %.c.rst
	@echo "$(CC_COLOR)CC$(NO_COLOR) $@"
	$(Q)cat $< | rst_tangle > $@

# build c files from markdown files - literate programming style
%.c: %.c.md
	@echo "$(CC_COLOR)CC$(NO_COLOR) $@"
	$(Q)cat $< | sed -n '/^```c/,/^```/ p' | sed '/^```/ d' > $@

# }}}

clean:
	rm -f *.o *.a


