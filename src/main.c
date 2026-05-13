#include <zephyr/kernel.h>
#include <zephyr/device.h>
#include <zephyr/drivers/display.h>
#include <zephyr/logging/log.h>

LOG_MODULE_REGISTER(rv_display, LOG_LEVEL_INF);

#define EPD_W        800
#define EPD_H        480
#define EPD_STRIDE   (EPD_W / 8)
#define EPD_BUF_SIZE (EPD_STRIDE * EPD_H)

static uint8_t fb[EPD_BUF_SIZE];

static void fill(uint8_t value)
{
	for (size_t i = 0; i < sizeof(fb); i++) {
		fb[i] = value;
	}
}

static void fill_split(void)
{
	for (uint16_t y = 0; y < EPD_H; y++) {
		uint8_t v = (y < EPD_H / 2) ? 0xFF : 0x00;
		for (uint16_t x = 0; x < EPD_STRIDE; x++) {
			fb[y * EPD_STRIDE + x] = v;
		}
	}
}

int main(void)
{
	const struct device *display = DEVICE_DT_GET(DT_CHOSEN(zephyr_display));
	struct display_buffer_descriptor desc = {
		.buf_size = sizeof(fb),
		.width = EPD_W,
		.height = EPD_H,
		.pitch = EPD_W,
	};

	if (!device_is_ready(display)) {
		LOG_ERR("display not ready");
		return -1;
	}

	display_blanking_off(display);

	while (1) {
		LOG_INF("white");
		fill(0xFF);
		display_write(display, 0, 0, &desc, fb);
		k_sleep(K_SECONDS(15));

		LOG_INF("split");
		fill_split();
		display_write(display, 0, 0, &desc, fb);
		k_sleep(K_SECONDS(15));

		LOG_INF("black");
		fill(0x00);
		display_write(display, 0, 0, &desc, fb);
		k_sleep(K_SECONDS(15));
	}
	return 0;
}
