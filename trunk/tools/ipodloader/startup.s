/*
 * head.S - iPodLinux loader
 * Copyright (c) 2003, Daniel Palffy (dpalffy (at) rainstorm.org)
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

        .equ    C_PROCESSOR_ID,	0xc4000000
        .equ    C_CPU_SLEEP,	0xca
        .equ    C_CPU_WAKE,	0xce
        .equ    C_CPU_ID,	0x55

.global _start
_start:
	mov	r0, #C_PROCESSOR_ID
	ldr	r0, [r0]
	and	r0, r0, #0xff
	cmp	r0, #C_CPU_ID
	beq	1f
								
	/* put us (co-processor) to sleep */
	ldr	r4, =0xcf004058
	mov	r3, #C_CPU_SLEEP
	strh	r3, [r4]

	/* make sure pipleline is clear */
	nop
	nop

	ldr	pc, =cop_wake_start

cop_wake_start:
.ifdef NOTDEF
	/* turn on backlight */
	ldr	r4, =0xc0001000
	ldr	r5, [r4]
	orr	r5, r5, #0x2
	str	r5, [r4]
.endif

	/* jump the COP to startup */
	ldr	r0, =startup_loc
	ldr	pc, [r0]

1:
	/* setup some stack */
	ldr	sp, =0x400177fc

	/* get the high part of our execute address */
	ldr	r2, =0xffffff00
	and	r4, pc, r2

	mov	r5, #0x40000000
	ldr	r6, =__data_start__
	sub	r0, r6, r5	/* lenth of text */
	add	r0, r4, r0	/* r0 points to start of text */
	cmp	r4, r5
	beq	start_loc	/* are we already at 0x40000000 */

1:
	cmp	r5, r6
	ldrcc	r2, [r4], #4
	strcc	r2, [r5], #4
	bcc	1b

	ldr	pc, =start_loc	/* jump to the next instruction in 0x4000xxxx */
	nop
	nop

start_loc:
	ldr	r1, =__data_start__
	ldr	r3, =__bss_start__
	cmp	r0, r1
	beq	init_bss

1:
	cmp	r1, r3
	ldrcc	r2, [r0], #4
	strcc	r2, [r1], #4
	bcc	1b

init_bss:
	ldr	r1, =__bss_end__
	mov	r2, #0x0

1:
	cmp	r3, r1
	strcc	r2, [r3], #4
	bcc	1b

	/* go to the loader */
	bl	loader
	/* save the startup address for the COP */
	ldr	r1, =startup_loc
	str	r0, [r1]

	/* make sure COP is sleeping */
	ldr	r4, =0xcf004050
1:
	ldr	r3, [r4]
	ands	r3, r3, #0x4000
	beq	1b

	/* wake up COP */
	ldr	r4, =0xcf004058
	mov	r3, #C_CPU_WAKE
	strh	r3, [r4]

	/* jump to start location */
	mov	pc, r0

startup_loc:
	.word	0x0

.align 8	/* starts at 0x100 */
.global boot_table
boot_table:
	/* here comes the boot table, don't move its offset */
	.space 400
