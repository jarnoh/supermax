#include <stdlib.h>
#include <stdio.h>
// #include <string.h>
#include <math.h>

typedef char byte;
typedef short word;
typedef long dword;
typedef unsigned char ubyte;
typedef unsigned short uword;
typedef unsigned long udword;


#ifndef M_PI
#define M_PI 3.141592654f
#endif

#define angz 420.f
#define dots 222
#define ambient 0.11f

#define centerx 160.f
#define centery 125.f

extern "C" void build_bumpshade(short *shadetab, byte *nakki);
#pragma aux build_bumpshade "_*"
extern "C" void build_tunnel(byte *tuna, float *tmp);
#pragma aux build_tunnel "_*"
extern "C" void build_flare(word *shadetab, byte *rc, byte *lc, byte *lt);
#pragma aux build_flare "_*"
extern "C" void build_flaresize(byte *rsize, int xp, int yp);
#pragma aux build_flaresize "_*"

/* rounds float (32bit) in S(0) to eax */
/* NOTE !!! range is from -2^19 to 2^19 */
int     roundfloat(float xx);
#pragma aux roundfloat=\
        "push   0x4b080000"\
        "fadd   dword [esp]"\
        "fstp   dword [esp]"\
        "pop    eax"\
        "and    eax, 0fffffh"\
        "sub    eax, 80000h"\
        parm    [8087]\
        value   [eax];

/* UNSIGNED !! rounds float (32bit) in S(0) to al! */
byte    ubroundfloat(float xx);
#pragma aux ubroundfloat=\
        "push   0x4b000000"\
        "fadd   dword [esp]"\
        "fstp   dword [esp]"\
        "pop    ecx"\
        parm    [8087]\
        value   [cl];

// inline  int round(float xx)  { return(roundfloat(xx)); }
// inline  byte round(float xx)  { return(ubroundfloat(xx)); }


inline void puttu(byte *tabla, float x, float y, byte rad, byte ang) {
  int ix=roundfloat(x)*2;
  int iy=640*roundfloat((y*4/5.f));
  if ((ix>=0)&&(ix<640))
  if ((iy>=0)&&(iy<(200*640)))
  if (*(tabla+(iy+ix))==0xff) {
    *(tabla+(iy+ix)) = ang;
    *(tabla+(iy+ix+1)) = rad;
  }
}

inline byte force31(int orig) {
  register byte t;
  if(orig>31) t=31; else t=orig;
  return(t);
}

inline int shader(float shade, float r, float g, float b) {
/* specular */
  float result = 1.f;
  char x; for(x=0;x<18;x++) result=result*shade;
  result=result*0.72f;
  shade+=ambient; if(shade>1.f) shade=1.f;
  return(
    (force31(roundfloat((result+r*shade)*31))<<10)+
    (force31(roundfloat((result+g*shade)*31))<<5)+
    (force31(roundfloat((result+b*shade)*31))));
}


void build_bumpshade(short *shadetab, byte *nakki) {
float fr, fg, fb;
  int col;
  int i,j,k,v;
  for (i=0;i<64;i++) {
    byte *palette = nakki;
    for (j=0;j<256;j++) {
      fr=*palette++*(0.5f/255.f);
      fg=*palette++*(0.5f/255.f);
      fb=*palette++*(0.7f/255.f);
      *shadetab++=0x7bde & (shader(i*(1.f/63.f),fr,fg,fb));
    }           // 5 7 3
  }
  for (i=0;i<64;i++) {
    byte *palette = nakki;
    for (j=0;j<256;j++) {
      fr=*palette++*(0.5f/255.f);
      fg=*palette++*(0.7f/255.f);
      fb=*palette++*(0.6f/255.f);
      *shadetab++=0x7bde & (shader(i*(1.f/63.f),fr,fg,fb));
    }           // 3 4 8
  }
  for (i=0;i<64;i++) {
    byte *palette = nakki;
    for (j=0;j<256;j++) {
      fr=*palette++*(0.7f/255.f);
      fg=*palette++*(0.5f/255.f);
      fb=*palette++*(0.6f/255.f);
      *shadetab++=0x7bde & (shader(i*(1.f/63.f),fr,fg,fb));
    }           // 8 5 3
  }
}


void build_tunnel(byte *tuna, float *tmp) {
  int i, j, k, m, n;
  i=320*200*2; while(i--) *(tuna+i)=255;
  float *px = tmp;
  float *py = (tmp+(dots*sizeof(float)));
  float *tpx = px;      // temp
  float *tpy = py;
  for(n=0;n<dots;n++) {
    *tpx++=centerx;
    *tpy++=centery+n;
  }
  float fr=0.f;
  while (fr<256.f) {
    tpx = px;
    tpy = py;
    for(n=0;n<dots;n++) {
      float dx=(*tpy-centery)*(1.f/angz);
      float dy=(*tpx-centerx)*(1.f/angz);
      puttu(tuna, *tpx, *tpy, ubroundfloat(n*(256.f/dots)), ubroundfloat(fr));
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

inline word rgb15(byte r, byte g, byte b) {
  return( (force31(r)<<10)+
          (force31(g)<<5)+
          (force31(b))
  );
}

void build_flare(word *shadetab, byte *rc, byte *lc, byte *lt) {
  int i, j;
//  for (i=0;i<768;i++) *(lc+i)=255;
//  for (i=0;i<768;i++) *(rc+i)=128;
//  for (i=0;i<768;i++) *(lt+i)=128;

  for (i=0;i<128;i++) {
    float th=((255-(*lt))*(32./62000.f));
    byte *palh = rc;
    for (j=0;j<256;j++) {
      *shadetab++=rgb15(
        ubroundfloat(((*palh+++*(lc+0))*th)),
        ubroundfloat(((*palh+++*(lc+1))*th)),
        ubroundfloat(((*palh+++*(lc+2))*th))); // &0x7bde;
    }
    lc+=6;
    lt+=6;
  }
  for (i=0;i<128;i++) for (j=0;j<256;j++) *shadetab++=0;
}

inline int rand(int a,int b) {
  return((a+b));
}

void build_flaresize(byte *rsize, int xp, int yp) {
  int i,j,k;
//  for (i=0;i<256;i++) for (j=0;j<256;j++) *(rsize+j+(i<<8))=(256+(j*15633+i*56845)&0xff)>>1;
  for(k=0;k<xp;k++) for (i=0;i<256;i++) for (j=0;j<256;j++) *(rsize+j+(i<<8))=(*(rsize+j+(i<<8))+*(rsize+((j+1)&255)+(i<<8)))>>1;
  for(k=0;k<yp;k++) for (i=0;i<256;i++) for (j=0;j<256;j++) *(rsize+j+(i<<8))=(*(rsize+j+(i<<8))+*(rsize+j+(((i+1)&0xff)<<8)))>>1;

}
