#ifndef _SYS_REBOOT_H
#define _SYS_REBOOT_H

/* perform a hard reset immediately */
#define RB_AUTOBOOT	0x01234567

/* halt the system */
#define RB_HALT_SYSTEM	0xcdef0123

/* enable reboot using CTRL+ALT+DEL keystroke */
#define RB_ENABLE_CAD	0x89abcdef

/* disable reboot using CTRL+ALT+DEL keystroke */
#define RB_DISABLE_CAD	0

/* reboot or halt de system */
extern int reboot (int, int, int);

#endif /* _SYS_REBOOT_H */
