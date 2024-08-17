  /*--------------------------------------------------*
       Pre-SVGAlib code by Paul Bourke:
       www.mhri.edu.au/~pdb/fractals/fern

       Usage:  <program name> <n steps>
       (Try 50,000 steps -- it won't take long).
    *--------------------------------------------------*/

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <vga.h>

#define NX 1024
#define NY 768
#define MIN(x,y) (x < y ? x : y)

double a[4] = {0.0,0.2,-0.15,0.75};
double b[4] = {0.0,-0.26,0.28,0.04};
double c[4] = {0.0,0.23,0.26,-0.04};
double d[4] = {0.16,0.22,0.24,0.85};
double e[4] = {0.0,0.0,0.0,0.0};
double f[4] = {0.0,1.6,0.44,1.6};

int main(int argc, char *argv[])
{
   int i,j,k;
   int n;
   int ix,iy;
   double r,x,y,xlast=1,ylast=1;
   double xmin=1e32,xmax=-1e32,ymin=1e32,ymax=-1e32,scale,xmid,ymid;

   if (argc < 2) {
      fprintf(stderr,"Usage: %s nsteps\n",argv[0]);
      exit(0);
   }
   n = atoi(argv[1]);

   vga_init();
   vga_setmode(G1024x768x256);
   vga_setcolor(15);

   for (j=0; j < 2 ; j++) {
      for (i=0; i < n; i++) {
         r = rand() % 100;
         if (r < 10)
            k = 0;
         else if (r < 18)
            k = 1;
         else if (r < 26)
            k = 2;
         else
            k = 3;
         x = a[k] * xlast + b[k] * ylast + e[k];
         y = c[k] * xlast + d[k] * ylast + f[k];
         xlast = x;
         ylast = y;
         if (x < xmin) xmin = x;
         if (y < ymin) ymin = y;
         if (x > xmax) xmax = x;
         if (y > ymax) ymax = y;
         if (j == 1) {
            scale = MIN(NX / (xmax - xmin),NY / (ymax - ymin));
            xmid = (xmin + xmax) / 2;
            ymid = (ymin + ymax) / 2;
            ix = NX / 2 + (x - xmid) * scale;
            iy = NY / 2 + (y - ymid) * scale;
            vga_drawpixel(ix, iy);
         }
      }
   }

   vga_getch();
   vga_setmode(TEXT);
   return 0;
}
