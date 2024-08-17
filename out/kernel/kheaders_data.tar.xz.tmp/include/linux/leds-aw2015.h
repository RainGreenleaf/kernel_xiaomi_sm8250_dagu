

#ifndef __LINUX_AW2015_LED_H__
#define __LINUX_AW2015_LED_H__



struct aw2015_platform_data {
	int imax;
	int currents[4]; 
	int delay_time_ms;
	int rise_time_ms;
	int hold_time_ms;
	int fall_time_ms;
	int slot_time_ms;
	int off_time_ms;
	struct aw2015_led *led;
	u8 cex;
	u8 mpulse;
};

#endif
