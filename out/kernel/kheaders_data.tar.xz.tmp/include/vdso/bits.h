/* SPDX-License-Identifier: GPL-2.0 */
#ifndef __VDSO_BITS_H
#define __VDSO_BITS_H

#ifdef __GENKSYMS__

#define BIT(nr)			(1UL << (nr))
#else
#include <vdso/const.h>

#define BIT(nr)			(UL(1) << (nr))
#endif

#endif	
