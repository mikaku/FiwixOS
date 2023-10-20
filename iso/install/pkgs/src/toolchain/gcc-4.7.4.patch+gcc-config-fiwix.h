/* Target definitions for GCC for Intel 80386 running Fiwix
 * Copyright (C) 1994, 1995, 1996, 1997, 1998, 1999, 2001, 2002, 2004, 2005,
 * 2006, 2007, 2008, 2009, 2010, 2011 Free Software Foundation, Inc.
 * by Jordi Sanfeliu.
 */

/* Useful if you wish to make target-specific gcc changes. */
#undef TARGET_FIWIX
#define TARGET_FIWIX 1
 
/* Default arguments you want when running your
   i686-fiwix-gcc/x86_64-fiwix-gcc toolchain */
#define LIB_SPEC "-lc -lg -lm -lnosys"	/* better for newlib */
 
/* Files that are linked before user code.
   The %s tells gcc to look for these files in the library directory. */
#undef STARTFILE_SPEC
#define STARTFILE_SPEC "crt0.o%s crti.o%s crtbegin.o%s"
 
/* Files that are linked after user code. */
#undef ENDFILE_SPEC
#define ENDFILE_SPEC "crtend.o%s crtn.o%s"
 
/* Don't automatically add extern "C" { } around header files. */
#undef  NO_IMPLICIT_EXTERN_C
#define NO_IMPLICIT_EXTERN_C 1

/* Additional predefined macros. */
#undef TARGET_OS_CPP_BUILTINS
#define TARGET_OS_CPP_BUILTINS()      \
  do {                                \
    builtin_define_std ("fiwix");     \
    builtin_define_std ("unix");      \
    builtin_define ("__fiwix__");     \
    builtin_define ("__unix__");      \
    builtin_assert ("system=fiwix");  \
    builtin_assert ("system=unix");   \
    builtin_assert ("system=posix");  \
  } while(0);

