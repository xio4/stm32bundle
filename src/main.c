#include "stm32f10x.h"
#include "system_stm32f10x.h"
#include "stdint_less.h"
#include "defines.h"
#include "bits_ctrl.h"

int main() {
    SystemCoreClockUpdate();

	uint32_t a = 0;
	for(;;) {
		GPIOA->CRL = a++;
		GPIOA->CRH = a / 2;


	}

	return 0;
}
