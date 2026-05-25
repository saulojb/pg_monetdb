# Makefile for pg_monetdb
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

MODULE_big = pg_monetdb
OBJS = \
	$(WIN32RES)   \
	deparse.o 	  \
	monetdb_fdw.o \
	shippable.o   \
	connection.o

PGFILEDESC = "pg_monetdb - foreign data wrapper for MonetDB"

# MonetDB installation paths.
# Override MONETDB_HOME to point at a non-standard installation, e.g.:
#   make MONETDB_HOME=/opt/monetdb USE_PGXS=1
MONETDB_HOME ?= /usr
MONETDB_INCLUDE ?= $(MONETDB_HOME)/include/monetdb
MONETDB_LIB    ?= $(MONETDB_HOME)/lib/x86_64-linux-gnu

# Locate the versioned libmapi shared library at build time so we don't
# have to hard-code the version string.
MAPI_LIB := $(firstword $(wildcard $(MONETDB_LIB)/libmapi-*.so) \
                         $(wildcard $(MONETDB_HOME)/lib/libmapi-*.so))
ifeq ($(MAPI_LIB),)
  $(error Cannot find libmapi shared library under $(MONETDB_LIB). \
          Set MONETDB_HOME or MONETDB_LIB explicitly.)
endif
MAPI_LIBNAME := $(patsubst lib%.so,%,$(notdir $(MAPI_LIB)))
MAPI_LIBDIR  := $(dir $(MAPI_LIB))

PG_CPPFLAGS  += -I"$(MONETDB_INCLUDE)"
SHLIB_LINK   += -L"$(MAPI_LIBDIR)" -l"$(MAPI_LIBNAME)" -Wl,-rpath,"$(MAPI_LIBDIR)"

EXTENSION = pg_monetdb
DATA = pg_monetdb--1.0.sql pg_monetdb--1.1.sql pg_monetdb--1.2.sql \
	pg_monetdb--1.3.sql pg_monetdb--1.4.sql pg_monetdb--1.0--1.1.sql \
	pg_monetdb--1.1--1.2.sql pg_monetdb--1.2--1.3.sql \
	pg_monetdb--1.3--1.4.sql

REGRESS = pg_monetdb type_support

ifdef USE_PGXS
PG_CONFIG ?= pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
else
subdir = contrib/MonetDB_fdw
top_builddir = ../..
include $(top_builddir)/src/Makefile.global
include $(top_srcdir)/contrib/contrib-global.mk
endif
