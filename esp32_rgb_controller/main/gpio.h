#ifndef GPIO_H
#define GPIO_H

#include <stdint.h>

void configure_gpio(void);
void set_rgb(uint8_t r, uint8_t g, uint8_t b);

#endif // GPIO_H
