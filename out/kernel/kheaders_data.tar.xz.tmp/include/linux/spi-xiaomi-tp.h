#ifndef _SPI_XIAOMI_TP_H
#define _SPI_XIAOMI_TP_H

#include <linux/module.h>
#include <linux/spi/spi.h>
#include <linux/mutex.h>
#include <linux/of.h>
#include <linux/sysfs.h>

#define TP_SPI_DEBUG

#define TP_TAG "[TP_SPI]: "

#undef PDEBUG
#ifdef TP_SPI_DEBUG
#ifdef __KERNEL__
#define PDEBUG(fmt, args...) printk(KERN_ERR TP_TAG fmt, ##args)
#else 
#define PDEBUG(fmt, args...) fprintf(stderr, TP_TAG fmt, ##args)
#endif 
#else 
#define PDEBUG(fmt, args...)
#endif 

#undef PDEBUGG
#define PDEBUGG(fmt, args...)

#define NAME_MAX_LENS 32


struct ts_spi_info {
	struct mutex lock;
	char name[NAME_MAX_LENS];
	bool used;
	bool tmp;
	bool init;
	struct spi_device *client;
};

extern int32_t tmp_hold_ts_xsfer(struct spi_device **client);
extern void tmp_drop_ts_xsfer(void);
extern int32_t get_ts_xsfer(const char *name);
extern void put_ts_xsfer(const char *name);
extern const char *get_owner_name(void);
extern struct spi_device *test_then_get_spi(const char *name);

#endif 
