

#ifndef _DRM_NOTIFIER_MI_H_
#define _DRM_NOTIFIER_MI_H_

#include <linux/notifier.h>


#define MI_DRM_EVENT_BLANK              0x01

#define MI_DRM_EARLY_EVENT_BLANK        0x02

#define MI_DRM_PRE_EVENT_BLANK          0x03

enum msm_drm_display_id {
	
	MSM_DRM_PRIMARY_DISPLAY,
	
	MSM_DRM_EXTERNAL_DISPLAY,
	MSM_DRM_DISPLAY_MAX
};

enum {
	
	MI_DRM_BLANK_UNBLANK   = 0,
	MI_DRM_BLANK_LP1       = 1,
	MI_DRM_BLANK_LP2       = 2,
	MI_DRM_BLANK_STANDBY   = 3,
	MI_DRM_BLANK_SUSPEND   = 4,
	
	MI_DRM_BLANK_POWERDOWN = 5,
};

struct mi_drm_notifier {
	enum msm_drm_display_id id;
	void *data;
};

int mi_drm_register_client(struct notifier_block *nb);
int mi_drm_unregister_client(struct notifier_block *nb);
int mi_drm_notifier_call_chain(unsigned long val, void *v);

#endif 
