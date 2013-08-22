// #include <stdlib.h>
// #include <stdio.h>
// #include <conio.h>
// #include <string.h>
// #include <math.h>

typedef char byte;
typedef int  word;
typedef long dword;
typedef unsigned char ubyte;
typedef unsigned int  uword;
typedef unsigned long udword;

int LBW;
int LBH;

void    setbiosmode(int x);
#pragma aux setbiosmode="int 10h" parm [ax];

unsigned char shadetable[256][256][3];

inline byte rand(void) {
  return 0;
}

inline byte forceb(int orig) {
  register byte t;
  if(orig>255) t=255; else t=orig;
  return(t);
}

main(int argc, char *argv[]) {
  int i, j, k, m;
  word *tuna = new word [320*200];
  byte *rc;
  byte *lc;
  byte *lt;
  byte *rsize;

  for (i=0;i<256;i++) for (j=0;j<256;j++)
    *(rsize+j+(i<<8))=(((rand())&0xff))>>0; // (256+(j*133847)&0xff)>>1;

  for(k=0;k<8;k++) for (i=0;i<256;i++) for (j=0;j<256;j++) *(rsize+j+(i<<8))=(*(rsize+j+(i<<8))+*(rsize+((j+1)&255)+(i<<8)))>>1;
  for(k=0;k<8;k++) for (i=0;i<256;i++) for (j=0;j<256;j++) *(rsize+j+(i<<8))=(*(rsize+j+(i<<8))+*(rsize+j+(((i+1)&0xff)<<8)))>>1;

  byte *palv = lc;
  for (i=0;i<128;i++) {
    int th=*lt;
//    int th=((127-i)*(127-i)*1038)>>16;
//    int th=255-((i*i*1040)>>16);
    if(th<0) th=0; if(th>255) th=255;
    byte *palh = rc;
    for (j=0;j<256;j++) {
      shadetable[i][j][0]=forceb((*palh+++*(palv+0))*th>>8);
      shadetable[i][j][1]=forceb((*palh+++*(palv+1))*th>>8);
      shadetable[i][j][2]=forceb((*palh+++*(palv+2))*th>>8);
//      printf("%x %x %x   ",shadetable[i][j][0],shadetable[i][j][1],shadetable[i][j][2]);
    }
    palv+=6;
    lt+=6;
  }
//  while(!kbhit());
//  for (m=0;m<3;m++) for (i=0;i<128;i++) for (j=0;j<256;j++) for (k=0;k<3;k++) {
//    shadetable[i][j][0]=(shadetable[i][j][0]+shadetable[i][(j+1)&255][0])>>1;
//  }

  byte *hi = new byte [320*256*3];
  byte fukka=0;
//  while(!kbhit()) {
{
    byte *tmp = (byte*)tuna;
    byte *vga = (byte*)0x0a0000;
    byte *hit = hi;
    int dist = 20*20;
    for(i=0;i<200;i++) {
      for(j=0;j<320;j++) {
        byte x=*tmp++;
        byte y=*tmp++;
        x+=fukka;
        int z=(y*dist**(rsize+x+((fukka&0xff)<<8)))>>16;
        if(z>128) y=128; else y=z;
        *(hit+0)=shadetable[y][x][0];
        *(hit+1)=shadetable[y][x][1];
        *(hit+2)=shadetable[y][x][2];
        *vga++=16+((*(hit)+*(hit+1)+*(hit+2))*5>>8);
        hit+=3;
      }
    }

    fukka-=1;
  }
}
