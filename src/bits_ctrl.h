#ifndef __BITS_CTRL_H__
#define __BITS_CTRL_H__

#define _BV(bit)   (1 << (bit)) 
#define INB(sfr)   _SFR_BYTE(sfr) 
#define SBI(x,y) (x |= (1<<y)); 				/* set bit y in byte x */ 
#define CBI(x,y) (x &= (~(1<<y))); 				/* clear bit y in byte x */ 
#define BIT_IS_SET(sfr, bit)   (INB(sfr) & _BV(bit)) 
#define BIT_IS_CEAR(sfr, bit)   (!(INB(sfr) & _BV(bit))) 
#define LOOP_UNTIL_BIT_IS_SET(sfr, bit)   do {asm volatile ("nop"::);} while (BIT_IS_CEAR(sfr, bit)) 
#define LOOP_UNTIL_BIT_IS_CLEAR(sfr, bit)   do {asm volatile ("nop"::);} while (BIT_IS_SET(sfr, bit))

#endif
