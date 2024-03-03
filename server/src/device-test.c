int main(void) {
    struct device dev;
    memset(&dev, 0, sizeof(dev));
    dev.dev_file = "/dev/uinput";
    dev.dev_name = "mouse";

    set_device(&dev);
    dev.key_tap = 1;

    for (int i = 1 ; i < 59 ; i++) {
        press_key(&dev, i);
        usleep(50000);
    }

    press_key(&dev, KEY_BRIGHTNESS_CYCLE);

    destroy_device(&dev);

}