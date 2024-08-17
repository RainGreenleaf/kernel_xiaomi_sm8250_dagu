

#ifndef __ARM64_KVM_HYP_H__
#define __ARM64_KVM_HYP_H__

#include <linux/compiler.h>
#include <linux/kvm_host.h>
#include <asm/sysreg.h>

#define __hyp_text __section(.hyp.text) notrace

#define read_sysreg_elx(r,nvh,vh)					\
	({								\
		u64 reg;						\
		asm volatile(ALTERNATIVE("mrs %0, " __stringify(r##nvh),\
					 __mrs_s("%0", r##vh),		\
					 ARM64_HAS_VIRT_HOST_EXTN)	\
			     : "=r" (reg));				\
		reg;							\
	})

#define write_sysreg_elx(v,r,nvh,vh)					\
	do {								\
		u64 __val = (u64)(v);					\
		asm volatile(ALTERNATIVE("msr " __stringify(r##nvh) ", %x0",\
					 __msr_s(r##vh, "%x0"),		\
					 ARM64_HAS_VIRT_HOST_EXTN)	\
					 : : "rZ" (__val));		\
	} while (0)


#define read_sysreg_el2(r)						\
	({								\
		u64 reg;						\
		asm volatile(ALTERNATIVE("mrs %0, " __stringify(r##_EL2),\
					 "mrs %0, " __stringify(r##_EL1),\
					 ARM64_HAS_VIRT_HOST_EXTN)	\
			     : "=r" (reg));				\
		reg;							\
	})

#define write_sysreg_el2(v,r)						\
	do {								\
		u64 __val = (u64)(v);					\
		asm volatile(ALTERNATIVE("msr " __stringify(r##_EL2) ", %x0",\
					 "msr " __stringify(r##_EL1) ", %x0",\
					 ARM64_HAS_VIRT_HOST_EXTN)	\
					 : : "rZ" (__val));		\
	} while (0)

#define read_sysreg_el0(r)	read_sysreg_elx(r, _EL0, _EL02)
#define write_sysreg_el0(v,r)	write_sysreg_elx(v, r, _EL0, _EL02)
#define read_sysreg_el1(r)	read_sysreg_elx(r, _EL1, _EL12)
#define write_sysreg_el1(v,r)	write_sysreg_elx(v, r, _EL1, _EL12)


#define sctlr_EL12              sys_reg(3, 5, 1, 0, 0)
#define cpacr_EL12              sys_reg(3, 5, 1, 0, 2)
#define ttbr0_EL12              sys_reg(3, 5, 2, 0, 0)
#define ttbr1_EL12              sys_reg(3, 5, 2, 0, 1)
#define tcr_EL12                sys_reg(3, 5, 2, 0, 2)
#define afsr0_EL12              sys_reg(3, 5, 5, 1, 0)
#define afsr1_EL12              sys_reg(3, 5, 5, 1, 1)
#define esr_EL12                sys_reg(3, 5, 5, 2, 0)
#define far_EL12                sys_reg(3, 5, 6, 0, 0)
#define mair_EL12               sys_reg(3, 5, 10, 2, 0)
#define amair_EL12              sys_reg(3, 5, 10, 3, 0)
#define vbar_EL12               sys_reg(3, 5, 12, 0, 0)
#define contextidr_EL12         sys_reg(3, 5, 13, 0, 1)
#define cntkctl_EL12            sys_reg(3, 5, 14, 1, 0)
#define cntp_tval_EL02          sys_reg(3, 5, 14, 2, 0)
#define cntp_ctl_EL02           sys_reg(3, 5, 14, 2, 1)
#define cntp_cval_EL02          sys_reg(3, 5, 14, 2, 2)
#define cntv_tval_EL02          sys_reg(3, 5, 14, 3, 0)
#define cntv_ctl_EL02           sys_reg(3, 5, 14, 3, 1)
#define cntv_cval_EL02          sys_reg(3, 5, 14, 3, 2)
#define spsr_EL12               sys_reg(3, 5, 4, 0, 0)
#define elr_EL12                sys_reg(3, 5, 4, 0, 1)


#define hyp_alternate_select(fname, orig, alt, cond)			\
typeof(orig) * __hyp_text fname(void)					\
{									\
	typeof(alt) *val = orig;					\
	asm volatile(ALTERNATIVE("nop		\n",			\
				 "mov	%0, %1	\n",			\
				 cond)					\
		     : "+r" (val) : "r" (alt));				\
	return val;							\
}

int __vgic_v2_perform_cpuif_access(struct kvm_vcpu *vcpu);

void __vgic_v3_save_state(struct kvm_vcpu *vcpu);
void __vgic_v3_restore_state(struct kvm_vcpu *vcpu);
void __vgic_v3_activate_traps(struct kvm_vcpu *vcpu);
void __vgic_v3_deactivate_traps(struct kvm_vcpu *vcpu);
void __vgic_v3_save_aprs(struct kvm_vcpu *vcpu);
void __vgic_v3_restore_aprs(struct kvm_vcpu *vcpu);
int __vgic_v3_perform_cpuif_access(struct kvm_vcpu *vcpu);

void __timer_enable_traps(struct kvm_vcpu *vcpu);
void __timer_disable_traps(struct kvm_vcpu *vcpu);

void __sysreg_save_state_nvhe(struct kvm_cpu_context *ctxt);
void __sysreg_restore_state_nvhe(struct kvm_cpu_context *ctxt);
void sysreg_save_host_state_vhe(struct kvm_cpu_context *ctxt);
void sysreg_restore_host_state_vhe(struct kvm_cpu_context *ctxt);
void sysreg_save_guest_state_vhe(struct kvm_cpu_context *ctxt);
void sysreg_restore_guest_state_vhe(struct kvm_cpu_context *ctxt);
void __sysreg32_save_state(struct kvm_vcpu *vcpu);
void __sysreg32_restore_state(struct kvm_vcpu *vcpu);

void __debug_switch_to_guest(struct kvm_vcpu *vcpu);
void __debug_switch_to_host(struct kvm_vcpu *vcpu);
void __debug_save_host_buffers_nvhe(struct kvm_vcpu *vcpu);
void __debug_restore_host_buffers_nvhe(struct kvm_vcpu *vcpu);


void __fpsimd_save_state(struct user_fpsimd_state *fp_regs);
void __fpsimd_restore_state(struct user_fpsimd_state *fp_regs);
bool __fpsimd_enabled(void);

void activate_traps_vhe_load(struct kvm_vcpu *vcpu);
void deactivate_traps_vhe_put(void);

u64 __guest_enter(struct kvm_vcpu *vcpu, struct kvm_cpu_context *host_ctxt);
void __noreturn __hyp_do_panic(unsigned long, ...);

#endif 

