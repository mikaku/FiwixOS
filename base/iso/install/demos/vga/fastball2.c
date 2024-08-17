/*
   FastBall II - 19 June 2000
   
   Plots thousands of randomly-generated spheres and rosettes,
   some very intriguing (rotating and pulsating).
      * Ramiro Perez <rperez@ns.pa>
      * Fausto A. A. Barbuto <bj06@c53000.petrobras.anrj.br>
      * Jay Link <jlink@svgalib.org>
      * Ivan McDonagh <ivan@svgalib.org>

   This version hacked by Michael Deegan <michael@ucc.gu.uwa.edu.au>
   Based on code found at http://www.svgalib.org/fastball.html
   Trance/techno/acid sold separately.

   Keys:
      q or Escape (or ^C I guess ;-):
         Quit
      p:
         Generate a different palette
      Space or Enter:
         Generate a different plot
      Any other key does nothing :)

   Those reading the source may notice some palette rotation code,
   commented out as it doesn't seem to be at all effective (as well
   as slowing the program down too).
   
   For those looking for something to tweak, play around with values
   of in and in2, and possibly CMUL as well.
*/

#include <stdlib.h>
#include <time.h>
#include <math.h>
#include <vga.h>

/*
 double qsrandom(void)
 {
    int    random_integer,
           temp_integer;
    double random_double,
           temp_double;

    random_integer = rand();
    random_double = (double)random_integer / RAND_MAX; // 0..1.0
    temp_integer = rand();
    temp_double = (double)temp_integer / 1000000000L; // 0..2.147
    random_double += temp_double;
//    srand((unsigned) time((time_t *)NULL));
    return(random_double); // 0..3.147
 }
*/

inline float qsrandom(void) {
    return ((float)rand()+rand()+rand())/(RAND_MAX*3.0); // 0..1.0, favouring median values
}

/*
void init_palette(int palette[768]) {
   int r,g,b,i;
   
   r=1+rand()%255; // pick starting values 1..255
   g=1+rand()%255;
   b=1+rand()%255;
   
   palette[0]=palette[1]=palette[2]=0; // force entry 0 to black
   for (i=1;i<256;++i) {               // fill the remaining 255 palette entries
      palette[r*3]=palette[g*3+1]=palette[b*3+2]=(sin(M_PI*2*i/255)+1.52)*25; // 13..63
      if (++r>=256) r=1;               // next colour index, skip 0
      if (++g>=256) g=1;
      if (++b>=256) b=1;
   }
   vga_setpalvec(0,256,palette);
}
*/

void init_palette(int palette[768]) {
   const float inc=M_PI*2/255;
   float r1,g1,b1,r2,g2,b2;
   int i;
   
   r1=rand()*M_PI*2/RAND_MAX; // pick starting values 0..2pi
   g1=rand()*M_PI*2/RAND_MAX;
   b1=rand()*M_PI*2/RAND_MAX;
   r2=rand()*M_PI*2/RAND_MAX;
   g2=rand()*M_PI*2/RAND_MAX;
   b2=rand()*M_PI*2/RAND_MAX;
   
   palette[0]=palette[1]=palette[2]=0;         // force entry 0 to black
   for (i=1;i<256;++i) {                       // fill the remaining 255 palette entries
      palette[i*3]=8*sin(r1)+16*sin(r2)+39;    // 15..63
      palette[i*3+1]=8*sin(g1)+16*sin(g2)+39;
      palette[i*3+2]=8*sin(b1)+16*sin(b2)+39;
      r1+=inc+inc; g1+=inc+inc; b1+=inc+inc;
      r2+=inc; g2+=inc; b2+=inc;
   }
   vga_setpalvec(0,256,palette);
}

void rotate_palette(int palette[768]) {
   const unsigned int STEP=255;            // number of palette entries to rotate palette
                                           // rotate 255 == rotate 1 in other direction
   int temp[STEP*3];

   memcpy(&temp[0],&palette[3],STEP*3*sizeof(int));                  // STEP entries
   memcpy(&palette[3],&palette[3+STEP*3],(255-STEP)*3*sizeof(int));  // 255-STEP entries
   memcpy(&palette[3+(255-STEP)*3],&temp[0],STEP*3*sizeof(int));     // STEP entries
   vga_setpalvec(0,256,palette);
}

int main(void) {
   double ra,
          in,
          in2,
          an = 0,
          an2 = 0,
          dan,
          dan2,
          x,
          y;

   int    //k,
          nx,
          ny;
          
   int palette[768];

//   const int NUM_PIXELS=9000;     // number of pixels onscreen at any one time
//   const int WID=800,HGT=600;
//   vga_setmode(G800x600x256);

   const int NUM_PIXELS=5000;
   const int WID=640,HGT=480;
   vga_setmode(G640x480x256);

//   const int NUM_PIXELS=1500;
//   const int WID=320,HGT=200;
//   vga_setmode(G320x200x256);

   srand((unsigned) time((time_t *)NULL));
   vga_init();

   for (;;) {
      int i;
//      const int CMUL=NUM_PIXELS/255/13; // colour multiplier (number of dots drawn before colour change)
      const int CMUL=2*NUM_PIXELS/255;
//      const int CMUL=1;
      int colour=1*CMUL;             // current colour*CMUL (note we must skip colour 0 (background))
     
      vga_clear();
     
      init_palette(palette);

      // in=theta speed, in2=radius oscillation speed
//      in = 6.24*qsrandom(); in2 = 6.24*qsrandom();
      in = .01*qsrandom(); in2 = .05*qsrandom(); // good
//      in = .005*qsrandom(); in2 = .011*qsrandom();
//      in = .01; in2 = .011*qsrandom();
//      in = .005*qsrandom(); in2 = .1;
//      in = .005*qsrandom(); in2 = .1*qsrandom(); // pretty good
      in = .4*qsrandom(); in2 = .1*qsrandom();
     
      dan=an;dan2=an2;
      for (i=0;i<NUM_PIXELS;++i)
         an+=in,an2+=in2;

      for (;;) {
         an = an + in; an2 = an2 + in2;
         ra = sin(an2);
         x = ra*sin(an); y = ra*cos(an);
         nx = WID/2+(HGT/2)*x; ny = HGT/2+HGT/2*y; // assuming WID>HGT of course :)
         vga_setcolor(colour/CMUL);
         if (++colour>=CMUL*256) colour=1*CMUL;
//         if (!colour%CMUL)
//               rotate_palette(palette);
         vga_drawpixel(nx,ny);
         
         switch (vga_getkey()) {
            case 'q':
            case 'Q':
            case 27:
               vga_setmode(TEXT);
               return 0;
            
            case 'p':
            case 'P':
               init_palette(palette);
               break;
               
            case 'R':
            case 'r':
               rotate_palette(palette);
               break;
               
            case '\n':
            case ' ':
               // double break (switch and inner for)
               break;
               break;

            default:
               break;
               // do nothing
         }

         dan = dan + in; dan2 = dan2 + in2;
         ra = sin(dan2);
         x = ra*sin(dan); y = ra*cos(dan);
         nx = WID/2+(HGT/2)*x; ny = HGT/2+HGT/2*y;
         vga_setcolor(0);
         vga_drawpixel(nx,ny);
      }
   }
}
