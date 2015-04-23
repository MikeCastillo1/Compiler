dnl Process this file with autoconf to produce a configure script.
dnl Created by Anjuta application wizard.

AC_INIT(compiler, 0.1)

AC_CONFIG_HEADERS([config.h])

AM_INIT_AUTOMAKE([1.11])

AM_SILENT_RULES([yes])

AC_PROG_CC




LT_INIT

dnl Check for vala
AM_PROG_VALAC([0.10.0])


PKG_CHECK_MODULES(COMPILER, gtksourceview-3.0
gee-0.8
gee-0.8
[gtk+-3.0 ])


AC_OUTPUT([
Makefile
src/Makefile

])
