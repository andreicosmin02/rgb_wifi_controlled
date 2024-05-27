#include "gpio.h"
#include "server.h"
#include "softap.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

void app_main(void)
{
    // Start in SoftAP mode
    start_softap();

    // Configure GPIO
    configure_gpio();

    // Start the web server
    start_webserver();
}
