#include <esp_http_server.h>
#include "esp_log.h"
#include "gpio.h"
#include "server.h"

#define MIN(a, b) (((a) < (b)) ? (a) : (b))

static const char *TAG = "webserver";
static httpd_handle_t server = NULL;

static const char *control_page = "<!DOCTYPE html>\
<html>\
<head>\
<title>RGB LED Control</title>\
</head>\
<body>\
<h1>RGB LED Control</h1>\
<label for='red'>Red:</label>\
<input type='range' id='red' name='red' min='0' max='255' oninput='updateRGB()'><br>\
<label for='green'>Green:</label>\
<input type='range' id='green' name='green' min='0' max='255' oninput='updateRGB()'><br>\
<label for='blue'>Blue:</label>\
<input type='range' id='blue' name='blue' min='0' max='255' oninput='updateRGB()'><br>\
<script>\
function updateRGB() {\
    var r = document.getElementById('red').value;\
    var g = document.getElementById('green').value;\
    var b = document.getElementById('blue').value;\
    var xhttp = new XMLHttpRequest();\
    xhttp.open('POST', `/set_rgb?r=${r}&g=${g}&b=${b}`, true);\
    xhttp.send();\
}\
</script>\
</body>\
</html>";

static esp_err_t root_get_handler(httpd_req_t *req)
{
    ESP_LOGI(TAG, "Serving control page");
    httpd_resp_send(req, control_page, HTTPD_RESP_USE_STRLEN);
    return ESP_OK;
}

static esp_err_t set_rgb_handler(httpd_req_t *req)
{
    char*  buf;
    size_t buf_len;

    buf_len = httpd_req_get_url_query_len(req) + 1;
    if (buf_len > 1) {
        buf = malloc(buf_len);
        if (httpd_req_get_url_query_str(req, buf, buf_len) == ESP_OK) {
            ESP_LOGI(TAG, "Found URL query => %s", buf);

            int red = 0, green = 0, blue = 0;
            char param[32];

            if (httpd_query_key_value(buf, "r", param, sizeof(param)) == ESP_OK) {
                red = atoi(param);
            }
            if (httpd_query_key_value(buf, "g", param, sizeof(param)) == ESP_OK) {
                green = atoi(param);
            }
            if (httpd_query_key_value(buf, "b", param, sizeof(param)) == ESP_OK) {
                blue = atoi(param);
            }
            free(buf);

            set_rgb(red, green, blue);
            ESP_LOGI(TAG, "Set RGB to R=%d, G=%d, B=%d", red, green, blue);
        }
    }

    httpd_resp_send(req, "RGB updated", HTTPD_RESP_USE_STRLEN);
    return ESP_OK;
}

httpd_uri_t uri_root = {
    .uri      = "/",
    .method   = HTTP_GET,
    .handler  = root_get_handler,
    .user_ctx = NULL
};

httpd_uri_t uri_set_rgb = {
    .uri      = "/set_rgb",
    .method   = HTTP_POST,
    .handler  = set_rgb_handler,
    .user_ctx = NULL
};

void start_webserver(void)
{
    httpd_config_t config = HTTPD_DEFAULT_CONFIG();

    ESP_LOGI(TAG, "Starting web server");
    if (httpd_start(&server, &config) == ESP_OK) {
        ESP_LOGI(TAG, "Registering URI handlers");
        httpd_register_uri_handler(server, &uri_root);
        httpd_register_uri_handler(server, &uri_set_rgb);
    }
}

void stop_webserver(void)
{
    if (server) {
        ESP_LOGI(TAG, "Stopping web server");
        httpd_stop(server);
        server = NULL;
    }
}
