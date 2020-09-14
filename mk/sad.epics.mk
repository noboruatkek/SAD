# New Makefile -- EPICS Part
#

## EPICS Enviroment
ifeq ($(USE_EPICS),YES)

# Static map: OS_NAME	-> EPICS_OS_CLASS
EPICS_OS_CLASS_OSF1?=osf
EPICS_OS_CLASS_HP-UX?=hpux
EPICS_OS_CLASS_SunOS?=solaris
EPICS_OS_CLASS_FreeBSD?=freebsd

# Static map: OS_NAME	-> EPICS_HOST_OS_CLASS
EPICS_HOST_OS_CLASS_Linux?=linux
EPICS_HOST_OS_CLASS_Darwin?=darwin

# Static map: CPU_ARCH	-> EPICS_HOST_CPU_CLASS
EPICS_HOST_CPU_CLASS_i386?=x86
EPICS_HOST_CPU_CLASS_AMD64?=x86_64
EPICS_HOST_CPU_CLASS_Alpha?=alpha
EPICS_HOST_CPU_CLASS_PowerPC?=ppc
EPICS_HOST_CPU_CLASS_SPARC?=sparc
EPICS_HOST_CPU_CLASS_PA1.0?=parisc
EPICS_HOST_CPU_CLASS_PA2.0?=parisc

ifndef EPICS_OS_CLASS
_EPICS_OS_CLASS=$(EPICS_OS_CLASS_$(OS_NAME))
ifeq ($(_EPICS_OS_CLASS),)
_EPICS_OS_CLASS=$(OS_NAME)
endif
EPICS_OS_CLASS=$(_EPICS_OS_CLASS)
endif # EPICS_OS_CLASS

ifndef EPICS_HOST_ARCH
_EPICS_HOST_OS_CLASS=$(EPICS_HOST_OS_CLASS_$(OS_NAME))
ifeq ($(_EPICS_HOST_OS_CLASS),)
_EPICS_HOST_OS_CLASS=$(EPICS_OS_CLASS_$(OS_NAME))
endif
ifeq ($(_EPICS_HOST_OS_CLASS),)
_EPICS_HOST_OS_CLASS=$(OS_NAME)
endif

_EPICS_HOST_CPU_CLASS=$(EPICS_HOST_CPU_CLASS_$(CPU_ARCH))
ifeq ($(_EPICS_HOST_CPU_CLASS),)
_EPICS_HOST_CPU_CLASS=$(CPU_ARCH)
endif

_EPICS_HOST_ARCH=$(_EPICS_HOST_OS_CLASS)-$(_EPICS_HOST_CPU_CLASS)

EPICS_HOST_ARCH=$(EPICS_HOST_ARCH_$(CPU_ARCH)_$(OS_NAME))
ifeq ($(EPICS_HOST_ARCH),)
EPICS_HOST_ARCH=$(_EPICS_HOST_ARCH)
endif
endif # EPICS_HOST_ARCH

ifndef EPICS_PREFIX
EPICS_PREFIX=/usr/local/epics
endif

ifndef EPICS_INCDIR
EPICS_INCDIR=$(EPICS_PREFIX)/include
endif

ifndef EPICS_LIBDIR
EPICS_LIBDIR=$(EPICS_PREFIX)/lib/$(EPICS_HOST_ARCH)
endif

_EPICS_LIBS=$(EPICS_LIBS_$(CPU_ARCH)_$(OS_NAME))
ifeq ($(_EPICS_LIBS),)
#_EPICS_LIBS=-lca -ldbStaticHost -lCom
_EPICS_LIBS=-lca -ldbCore -lCom
endif

EPICS_IOPT=-I$(EPICS_INCDIR) -I$(EPICS_INCDIR)/os/$(EPICS_OS_CLASS)
EPICS_ROPT=-L$(EPICS_LIBDIR)
EPICS_LIBS=-L$(EPICS_LIBDIR) $(_EPICS_LIBS)

endif # USE_EPICS

# End of File
