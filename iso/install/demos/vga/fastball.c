   /* Plots thousands of randomly-generated spheres and rosettes,
      some very intriguing (rotating and pulsating).

      INSTRUCTIONS: press 'n' or 'N' to see the next plot; any other
      key will stop the execution.
   */

#include <stdlib.h>
#include <time.h>
#include <math.h>
#include <vga.h>

double qsrandom(void);

int main(void)
{
  double ra,
         in,
         in2,
         an = 0,
         an2 = 0,
         x,
         y,
         c1,
         c2;

  int    k,
         nx,
         ny;

  char   key;

  vga_init();
  vga_setmode(G640x480x256);

  c1 = 640.0/3.1; c2 = 480.0/2.1;

  do
  {
    vga_clear();
    in = 6.24*qsrandom(); in2 = 6.24*qsrandom();

    do
    {
      an = an + in; an2 = an2 + in2;
      ra = sin(an2);
      x = ra*sin(an); y = ra*cos(an);
      nx = c1*(x + 1.55); ny = c2*(y + 1.05);
      k = vga_getpixel(nx,ny);
      vga_setcolor(k+1);
      if (k < 256) vga_drawpixel(nx,ny);
    } while ((key = vga_getkey()) == 0);

  } while ((key == 78) || (key == 110));

  vga_setmode(TEXT);
  return 0;
}

double qsrandom(void)
{
   int    random_integer,
          temp_integer;
   double random_double,
          temp_double;

   random_integer = rand();
   random_double = (double)random_integer / RAND_MAX;
   temp_integer = rand();
   temp_double = (double)temp_integer / 1000000000L;
   random_double += temp_double;
   srand((unsigned) time((time_t *)NULL));
   return(random_double);
}
