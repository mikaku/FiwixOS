/*
 * fiwix/syscalls.h
 *
 * Copyright 2018-2022, Jordi Sanfeliu. All rights reserved.
 * Distributed under the terms of the Fiwix License.
 */

#ifndef _SYSCALLS_H
#define _SYSCALLS_H

#include <fiwix/unistd.h>

#define MAXERRNO	-125

struct sysvipc_args {
	int arg1;
	int arg2;
	int arg3;
	void *ptr;
	int arg5;
};

#define SYSCALL0(fn, retval)					\
	int __sys_##fn(void)					\
	{							\
		unsigned int retval;				\
								\
		__asm__ __volatile__(				\
			"int	$0x80\n\t"			\
			: "=a"(retval)				\
			: "0"(SYS_##fn)				\
		);						\
		if((int)retval < 0 && (int)retval > MAXERRNO) {	\
			errno = -(retval);			\
			retval = -1;				\
			return (int)retval;			\
		}						\
		return retval;					\
	}

#define SYSCALL1(fn, retval, type1)				\
	int __sys_##fn(type1 arg1)				\
	{							\
		unsigned int retval;				\
								\
		__asm__ __volatile__(				\
			"int	$0x80\n\t"			\
			: "=a"(retval)				\
			: "0"(SYS_##fn),			\
			  "b"((type1)(arg1))			\
		);						\
		if((int)retval < 0 && (int)retval > MAXERRNO) {	\
			errno = -(retval);			\
			retval = -1;				\
			return (int)retval;			\
		}						\
		return retval;					\
	}

#define SYSCALL2(fn, retval, type1, type2)			\
	int __sys_##fn(type1 arg1, type2 arg2)			\
	{							\
		unsigned int retval;				\
								\
		__asm__ __volatile__(				\
			"int	$0x80\n\t"			\
			: "=a"(retval)				\
			: "0"(SYS_##fn),			\
			  "b"((type1)(arg1)),			\
			  "c"((type2)(arg2)) 			\
		);						\
		if((int)retval < 0 && (int)retval > MAXERRNO) {	\
			errno = -(retval);			\
			retval = -1;				\
			return (int)retval;			\
		}						\
		return retval;					\
	}

#define SYSCALL3(fn, retval, type1, type2, type3)		\
	int __sys_##fn(type1 arg1, type2 arg2, type3 arg3)	\
	{							\
		unsigned int retval;				\
								\
		__asm__ __volatile__(				\
			"int	$0x80\n\t"			\
			: "=a"(retval)				\
			: "0"(SYS_##fn),			\
			  "b"((type1)(arg1)),			\
			  "c"((type2)(arg2)),			\
			  "d"((type3)(arg3)) 			\
		);						\
		if((int)retval < 0 && (int)retval > MAXERRNO) {	\
			errno = -(retval);			\
			retval = -1;				\
			return (int)retval;			\
		}						\
		return retval;					\
	}

#define SYSCALL4(fn, retval, type1, type2, type3, type4)	\
	int __sys_##fn(type1 arg1, type2 arg2, type3 arg3, type4 arg4) \
	{							\
		unsigned int retval;				\
								\
		__asm__ __volatile__(				\
			"int	$0x80\n\t"			\
			: "=a"(retval)				\
			: "0"(SYS_##fn),			\
			  "b"((type1)(arg1)),			\
			  "c"((type2)(arg2)),			\
			  "d"((type3)(arg3)),			\
			  "S"((type4)(arg4))			\
		);						\
		if((int)retval < 0 && (int)retval > MAXERRNO) {	\
			errno = -(retval);			\
			retval = -1;				\
			return (int)retval;			\
		}						\
		return retval;					\
	}

#define SYSCALL5(fn, retval, type1, type2, type3, type4, type5)	\
	int __sys_##fn(type1 arg1, type2 arg2, type3 arg3, type4 arg4, type5 arg5) \
	{							\
		unsigned int retval;				\
								\
		__asm__ __volatile__(				\
			"int	$0x80\n\t"			\
			: "=a"(retval)				\
			: "0"(SYS_##fn),			\
			  "b"((type1)(arg1)),			\
			  "c"((type2)(arg2)),			\
			  "d"((type3)(arg3)),			\
			  "S"((type4)(arg4)),			\
			  "D"((type5)(arg5))			\
		);						\
		if((int)retval < 0 && (int)retval > MAXERRNO) {	\
			errno = -(retval);			\
			retval = -1;				\
			return (int)retval;			\
		}						\
		return retval;					\
	}

#define SYSCALL6(fn, retval, type1, type2, type3, type4, type5, type6)	\
	int __sys_##fn(type1 arg1, type2 arg2, type3 arg3, type4 arg4, type5 arg5, type6 arg6) \
	{							\
		unsigned int retval;				\
								\
		__asm__ __volatile__(				\
			"pushl	%7\n\t"				\
			"push	%%ebp\n\t"			\
			"mov	4(%%esp),%%ebp\n\t"		\
			"int	$0x80\n\t"			\
			"pop	%%ebp\n\t"			\
			"add	$4,%%esp\n\t"			\
			: "=a"(retval)				\
			: "0"(SYS_##fn),			\
			  "b"((type1)(arg1)),			\
			  "c"((type2)(arg2)),			\
			  "d"((type3)(arg3)),			\
			  "S"((type4)(arg4)),			\
			  "D"((type5)(arg5)),			\
			  "g"((type6)(arg6))			\
		);						\
		if((int)retval < 0 && (int)retval > MAXERRNO) {	\
			errno = -(retval);			\
			retval = -1;				\
			return (int)retval;			\
		}						\
		return retval;					\
	}

#endif /* _SYSCALLS_H */
