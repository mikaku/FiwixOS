/* Copyright (C) 1999, 2000, 2001 Free Software Foundation, Inc.
   This file is part of the GNU C Library.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
   02111-1307 USA.  */

#include <errno.h>
#include <stdint.h>
#include <time.h>
#include <sys/time.h>
#include <unistd.h>

/* Get current value of CLOCK and store it in TP.  */
int
clock_gettime (clockid_t clock_id, struct timespec *tp)
{
  struct timeval tv;
  int retval = -1;

  switch (clock_id)
    {
    case CLOCK_REALTIME:
    case CLOCK_MONOTONIC: /* fake */
      retval = gettimeofday (&tv, NULL);
      if (retval == 0)
        /* Convert into `timespec'.  */
        TIMEVAL_TO_TIMESPEC (&tv, tp);
      break;

    default:
      __set_errno (EINVAL);
      break;
    }

  return retval;
}

/* Get resolution of clock.  */
int
clock_getres (clockid_t clock_id, struct timespec *res)
{
  int retval = -1;

  switch (clock_id)
    {
    case CLOCK_REALTIME:
    case CLOCK_MONOTONIC: /* fake */
      {
        int clk_tck = sysconf (_SC_CLK_TCK);

        if (__builtin_expect (clk_tck != -1, 1))
          {
            /* This implementation assumes that the realtime clock has a
               resolution higher than 1 second.  This is the case for any
               reasonable implementation.  */
            res->tv_sec = 0;
            res->tv_nsec = 1000000000 / clk_tck;

            retval = 0;
          }
      }
      break;

    default:
      __set_errno (EINVAL);
      break;
    }

  return retval;
}

/* Set CLOCK to value TP.  */
int
clock_settime (clockid_t clock_id, const struct timespec *tp)
{
  struct timeval tv;
  int retval;

  /* Make sure the time cvalue is OK.  */
  if (tp->tv_nsec < 0 || tp->tv_nsec >= 1000000000)
    {
      __set_errno (EINVAL);
      return -1;
    }

  switch (clock_id)
    {
    case CLOCK_REALTIME:
    case CLOCK_MONOTONIC: /* fake */
      TIMESPEC_TO_TIMEVAL (&tv, tp);

      retval = settimeofday (&tv, NULL);
      break;

    default:
      __set_errno (EINVAL);
      retval = -1;
      break;
    }

  return retval;
}
