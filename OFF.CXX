#include <stdlib.h>
#include <stdio.h>
#include <conio.h>
// #include <string.h>
#include <math.h>

#ifndef M_PI
#define M_PI 3.141592654f
#endif

#define angz 420.f
#define dots 222

typedef char byte;
typedef int  word;
typedef long dword;
typedef unsigned char ubyte;
typedef unsigned int  uword;
typedef unsigned long udword;

inline void puttu(byte *tabla, float x, float y, byte ang, byte rad) {
  int ix=x;
  int iy=(int)(y*(3.f/4.f));
  if ((ix>=0)&&(ix<320))
  if ((iy>=0)&&(iy<200))
  if (*(tabla+(iy*640+ix*2))==0xff) {
    *(tabla+(iy*640+ix*2+1)) = ang;
    *(tabla+(iy*640+ix*2)) = rad;
  }
}

extern "C" void build_tunnel(byte *tuna, float *tmp);
#pragma aux build_tunnel "_*"

void build_tunnel(byte *tuna, float *tmp) {
  int i, j, k, m, n;
  i=320*200*2; while(i--) *(tuna+i)=255;
  float *px = tmp;
  float *py = (tmp+(dots*sizeof(float)));
  float *tpx = px;      // temp
  float *tpy = py;
  for(n=0;n<dots;n++) {
    *tpx++=160.f;
    *tpy++=133.f+n;       // aspect ratio 4:3  -> 100*4/3...
  }
  float fr=0.f;
  while (fr<256.f) {
    tpx = px;
    tpy = py;
    for(n=0;n<dots;n++) {
      float dx=(*tpy-133.f)*(1.f/angz);
      float dy=(*tpx-160.f)*(1.f/angz);
      puttu(tuna, *tpx, *tpy, (byte)(n*(256./dots)), (byte)fr);
      *tpx=*tpx-dx;
      *tpy=*tpy+dy;
      tpx++;
      tpy++;
    }
    fr+=((256.f/angz)/(2*M_PI));
  }
//  delete py;
//  delete px;
}
