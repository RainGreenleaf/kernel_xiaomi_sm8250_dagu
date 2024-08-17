/* SPDX-License-Identifier: GPL-2.0-only */


#ifndef __LINUX_PINCTRL_MSM_H__
#define __LINUX_PINCTRL_MSM_H__


int msm_qup_write(u32 mode, u32 val);
int msm_qup_read(u32 mode);


int msm_gpio_mpm_wake_set(unsigned int gpio, bool enable);

#endif 
