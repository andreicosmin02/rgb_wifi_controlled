#include <string.h>
#include "esp_wifi.h"
#include "esp_event.h"
#include "esp_log.h"
#include "nvs_flash.h"
#include "softap.h"

static const char *TAG = "softap";

void start_softap(void)
{
    ESP_LOGI(TAG, "Initializing NVS");
    ESP_ERROR_CHECK(nvs_flash_init());
    ESP_LOGI(TAG, "Initializing netif");
    ESP_ERROR_CHECK(esp_netif_init());
    ESP_LOGI(TAG, "Creating default event loop");
    ESP_ERROR_CHECK(esp_event_loop_create_default());

    ESP_LOGI(TAG, "Creating default WiFi AP netif");
    esp_netif_create_default_wifi_ap();

    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    ESP_LOGI(TAG, "Initializing WiFi with default config");
    ESP_ERROR_CHECK(esp_wifi_init(&cfg));

    wifi_config_t wifi_config = {
        .ap = {
            .ssid = "ESP32_AP",
            .ssid_len = strlen("ESP32_AP"),
            .channel = 1,
            .password = "12345678",
            .max_connection = 4,
            .authmode = WIFI_AUTH_WPA_WPA2_PSK
        },
    };
    if (strlen("12345678") == 0) {
        wifi_config.ap.authmode = WIFI_AUTH_OPEN;
    }

    ESP_LOGI(TAG, "Setting WiFi mode to AP");
    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_AP));
    ESP_LOGI(TAG, "Configuring WiFi with provided settings");
    ESP_ERROR_CHECK(esp_wifi_set_config(WIFI_IF_AP, &wifi_config));
    ESP_LOGI(TAG, "Starting WiFi");
    ESP_ERROR_CHECK(esp_wifi_start());

    ESP_LOGI(TAG, "SoftAP started with SSID: %s, password: %s", "ESP32_AP", "12345678");
}
