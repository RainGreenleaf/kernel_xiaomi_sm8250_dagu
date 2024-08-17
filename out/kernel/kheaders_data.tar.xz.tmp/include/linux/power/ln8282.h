

#ifndef _LN8282_REGULATOR_H_
#define _LN8282_REGULATOR_H_

// (high-level) operation mode
enum {
	LN8282_OPMODE_UNKNOWN = -1,
	LN8282_OPMODE_STANDBY = 0,
	LN8282_OPMODE_BYPASS = 1,
	LN8282_OPMODE_SWITCHING = 2,
	LN8282_OPMODE_SWITCHING_ALT = 3,
};

// Forward declarations
struct ln8282_info;

void ln8282_use_ext_5V(struct ln8282_info *info, unsigned int enable);
void ln8282_set_infet(struct ln8282_info *info, unsigned int enable);
void ln8282_set_powerpath(struct ln8282_info *info, bool forward_path);
bool ln8282_change_opmode(struct ln8282_info *info, unsigned int target_mode);
int ln8282_hw_init(struct ln8282_info *info);



#endif
