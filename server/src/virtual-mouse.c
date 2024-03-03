// https://kernel.org/doc/html/v4.12/input/uinput.html

#include <linux/uinput.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>
#include <stdio.h>
#include <errno.h>

// key_press_status
#define RELEASE 0
#define PRESS   1

typedef struct device {
    char* dev_file;
    char* dev_name;
    int fd;
    // mouse
    unsigned int move_x_sense;
    unsigned int move_y_sense;
    unsigned int move_delay;
    // keyboard
    unsigned char key_tap;          // set when single pressing a key
    unsigned char key_press_status; // set when dragging/maintaining key pressed
} device ;

/**
 * @brief write the event into the file descriptor 
 * 
 * @param fd file descriptor
 * @param type event type
 * @param code event code
 * @param val value
 */
void emit(int fd, int type, int code, int val)
{
    struct input_event ie;

    ie.type = type;
    ie.code = code;
    ie.value = val;
    /* timestamp values below are ignored */
    ie.time.tv_sec = 0;
    ie.time.tv_usec = 0;

    int res = write(fd, &ie, sizeof(ie));
    if (res == -1) {
        fprintf(stderr, "Error writing to file descriptor: %s\n", strerror(errno));
        return;
    }
}

int inline get_nbr_bytes(unsigned int val) {
    unsigned char bits = 0;
    while (val) {
        val >>= 1;
        bits++;
    }
    return bits/8 + 1;
}

/**
 * @brief Enable all the input system-related events
 * EV_KEY - key events
 * EV_REL - relative axis events
 * @param fd file descriptor
 */
void set_events(int fd) {
    // ------------------------ //
    //      Key events          //
    // ------------------------ //
    ioctl(fd, UI_SET_EVBIT, EV_KEY);
    ioctl(fd, UI_SET_KEYBIT, BTN_LEFT);                 // mouse btns
    ioctl(fd, UI_SET_KEYBIT, BTN_RIGHT);
    
    // set basic keyboard keys
    for (unsigned int k = KEY_ESC ; k < KEY_CAPSLOCK ; k++) {
        ioctl(fd, UI_SET_KEYBIT, k);
    }
    
    ioctl(fd, UI_SET_KEYBIT, KEY_MUTE);                 // volume & pause controls
    ioctl(fd, UI_SET_KEYBIT, KEY_VOLUMEDOWN);
    ioctl(fd, UI_SET_KEYBIT, KEY_VOLUMEUP);
    ioctl(fd, UI_SET_KEYBIT, KEY_PAUSE);

    ioctl(fd, UI_SET_KEYBIT, KEY_COPY);                 // copy-paste-cut
    ioctl(fd, UI_SET_KEYBIT, KEY_PASTE);
    ioctl(fd, UI_SET_KEYBIT, KEY_CUT);
    
    ioctl(fd, UI_SET_KEYBIT, KEY_REFRESH);              // refresh
    
    ioctl(fd, UI_SET_KEYBIT, KEY_SCROLLUP);             // mouse scrolls
    ioctl(fd, UI_SET_KEYBIT, KEY_SCROLLDOWN);
    
    ioctl(fd, UI_SET_KEYBIT, KEY_BRIGHTNESS_CYCLE);     // adjust brightness

    // ------------------------ //
    //   Relative Axis events   //
    // ------------------------ //
    ioctl(fd, UI_SET_EVBIT, EV_REL);
    ioctl(fd, UI_SET_RELBIT, REL_X);
    ioctl(fd, UI_SET_RELBIT, REL_Y);
}

/**
 * @brief Move the device's relative axis position
 * 
 * @param dev 
 * @param move_x 
 * @param move_y 
 */
void device_move(device* dev, int move_x, int move_y) {
    emit(dev->fd, EV_REL, REL_X, dev->move_x_sense * move_x);
    emit(dev->fd, EV_REL, REL_Y, dev->move_y_sense * move_y);
    emit(dev->fd, EV_SYN, SYN_REPORT, 0);
    usleep(dev->move_delay);
}

/**
 * @brief Emit key pressed event
 * 
 * @param dev 
 * @param move_x 
 * @param move_y 
 */
void press_key(device* dev, unsigned int key_code, unsigned int key_tap) {
    if (key_tap) { // key tap
        emit(dev->fd, EV_KEY, key_code, PRESS);
        emit(dev->fd, EV_SYN, SYN_REPORT, 0);
        emit(dev->fd, EV_KEY, key_code, RELEASE);
        emit(dev->fd, EV_SYN, SYN_REPORT, 0);
    }
    else { // long press
        emit(dev->fd, EV_KEY, key_code, dev->key_press_status);
        emit(dev->fd, EV_SYN, SYN_REPORT, 0);
    }

}

/**
 * @brief Configure the device in the respective uinput file
 * If the file doesn't exist, ends the program.
 * Sets the file descripto in the device struct
 * @param dev device configuration struct 
 * @return int 
 */
int set_device(device* dev) {
    if ((dev->fd = open(dev->dev_file, O_WRONLY | O_NONBLOCK)) < 0) {
        fprintf(stderr, "Error opening file %s: %s\n", dev->dev_file, strerror(errno));
        return -1;
    }

    // ioctl(dev->fd, UI_SET_EVBIT, EV_KEY);
    // ioctl(dev->fd, UI_SET_KEYBIT, KEY_S); 

    set_events(dev->fd);

    struct uinput_setup usetup;
    memset(&usetup, 0, sizeof(usetup));
    usetup.id.bustype = BUS_USB;
    usetup.id.vendor = 0x1234; /* sample vendor */
    usetup.id.product = 0x5678; /* sample product */
    strcpy(usetup.name, dev->dev_name);

    ioctl(dev->fd, UI_DEV_SETUP, &usetup);
    ioctl(dev->fd, UI_DEV_CREATE);
    
    /*
    * On UI_DEV_CREATE the kernel will create the device node for this
    * device. We are inserting a pause here so that userspace has time
    * to detect, initialize the new device, and can start listening to
    * the event, otherwise it will not notice the event we are about
    * to send.
    */
    sleep(1);

    return 1;
}

/**
 * @brief Cleanup the device
 * 
 * @param dev 
 */
void destroy_device(device* dev) {
   ioctl(dev->fd, UI_DEV_DESTROY);
   close(dev->fd);
}
