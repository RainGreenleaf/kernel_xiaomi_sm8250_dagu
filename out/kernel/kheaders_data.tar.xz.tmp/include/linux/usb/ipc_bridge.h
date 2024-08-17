/* SPDX-License-Identifier: GPL-2.0-only */


#ifndef __MSM_IPC_BRIDGE_H__
#define __MSM_IPC_BRIDGE_H__

#include <linux/platform_device.h>




struct ipc_bridge_platform_data {
	unsigned int max_read_size;
	unsigned int max_write_size;
	int (*open)(struct platform_device *pdev);
	int (*read)(struct platform_device *pdev, char *buf,
			unsigned int count);
	int (*write)(struct platform_device *pdev, char *buf,
			unsigned int count);
	void (*close)(struct platform_device *pdev);
};

#endif
