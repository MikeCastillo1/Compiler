## Process this file with automake to produce Makefile.in

## Created by Anjuta


uidir = $(pkgdatadir)/ui
ui_DATA = compiler.ui


AM_CPPFLAGS = \
	-DPACKAGE_LOCALE_DIR=\""$(localedir)"\" \
	-DPACKAGE_SRC_DIR=\""$(srcdir)"\" \
	-DPACKAGE_DATA_DIR=\""$(pkgdatadir)"\" \
	$(COMPILER_CFLAGS)

AM_CFLAGS =\
	 -Wall\
	 -g

bin_PROGRAMS = compiler

compiler_SOURCES = \
	compiler.vala config.vapi util.vala syntactic.vala state-machine.vala source-manager.vala log.vala lexical.vala log-out.vala source-code.vala semantic.vala blueprint.vala

compiler_VALAFLAGS =  \
	--pkg gtk+-3.0 \
	--pkg gee-0.8 \
	--pkg gtksourceview-3.0


compiler_LDFLAGS = \
	-Wl,--export-dynamic

compiler_LDADD = $(COMPILER_LIBS)




EXTRA_DIST = $(ui_DATA)

# Remove ui directory on uninstall
uninstall-local:
	-rm -r $(uidir)
	-rm -r $(pkgdatadir)

