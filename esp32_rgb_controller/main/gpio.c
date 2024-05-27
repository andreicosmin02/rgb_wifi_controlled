#include "driver/ledc.h"
#include "esp_err.h"
#include "gpio.h"

#define RED_GPIO_PIN 15
#define GREEN_GPIO_PIN 2
#define BLUE_GPIO_PIN 4
#define LEDC_TIMER LEDC_TIMER_0
#define LEDC_MODE LEDC_LOW_SPEED_MODE
#define LEDC_OUTPUT_IO_R (RED_GPIO_PIN)
#define LEDC_OUTPUT_IO_G (GREEN_GPIO_PIN)
#define LEDC_OUTPUT_IO_B (BLUE_GPIO_PIN)
#define LEDC_CHANNEL_R LEDC_CHANNEL_0
#define LEDC_CHANNEL_G LEDC_CHANNEL_1
#define LEDC_CHANNEL_B LEDC_CHANNEL_2
#define LEDC_DUTY_RES LEDC_TIMER_8_BIT
#define LEDC_FREQUENCY (5000)

void configure_gpio(void)
{
    ledc_timer_config_t ledc_timer = {
        .speed_mode = LEDC_MODE,
        .duty_resolution = LEDC_DUTY_RES,
        .timer_num = LEDC_TIMER,
        .freq_hz = LEDC_FREQUENCY,
        .clk_cfg = LEDC_AUTO_CLK
    };
    ledc_timer_config(&ledc_timer);

    ledc_channel_config_t ledc_channel_r = {
        .speed_mode = LEDC_MODE,
        .channel = LEDC_CHANNEL_R,
        .timer_sel = LEDC_TIMER,
        .intr_type = LEDC_INTR_DISABLE,
        .gpio_num = LEDC_OUTPUT_IO_R,
        .duty = 0,
        .hpoint = 0
    };
    ledc_channel_config(&ledc_channel_r);

    ledc_channel_config_t ledc_channel_g = {
        .speed_mode = LEDC_MODE,
        .channel = LEDC_CHANNEL_G,
        .timer_sel = LEDC_TIMER,
        .intr_type = LEDC_INTR_DISABLE,
        .gpio_num = LEDC_OUTPUT_IO_G,
        .duty = 0,
        .hpoint = 0
    };
    ledc_channel_config(&ledc_channel_g);

    ledc_channel_config_t ledc_channel_b = {
        .speed_mode = LEDC_MODE,
        .channel = LEDC_CHANNEL_B,
        .timer_sel = LEDC_TIMER,
        .intr_type = LEDC_INTR_DISABLE,
        .gpio_num = LEDC_OUTPUT_IO_B,
        .duty = 0,
        .hpoint = 0
    };
    ledc_channel_config(&ledc_channel_b);
}

void set_rgb(uint8_t r, uint8_t g, uint8_t b)
{
    ledc_set_duty(LEDC_MODE, LEDC_CHANNEL_R, 255 - r);
    ledc_update_duty(LEDC_MODE, LEDC_CHANNEL_R);

    ledc_set_duty(LEDC_MODE, LEDC_CHANNEL_G, 255 - g);
    ledc_update_duty(LEDC_MODE, LEDC_CHANNEL_G);

    ledc_set_duty(LEDC_MODE, LEDC_CHANNEL_B, 255 - b);
    ledc_update_duty(LEDC_MODE, LEDC_CHANNEL_B);
}
