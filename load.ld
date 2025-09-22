/* Copyright (C) 2014-2024 Free Software Foundation, Inc.
   Copying and distribution of this script, with or without modification,
   are permitted in any medium without royalty provided the copyright
   notice and this notice are preserved.  */

/* SPDX-License-Identifier: MPL-2.0 AND FSFAP */

/*
 * NOTE: This linkerscript only works in DS mode. The TWL sections are present
 * in the file so that they can be discarded by ndstool. If ndstool can't
 * identify TWL-only code, it will all be included in the DS sections, and the
 * ARM7 binary will be too big (it will include the NAND and SD drivers, etc).
 */

OUTPUT_FORMAT("elf32-littlearm", "elf32-bigarm", "elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(_start)

/* User-configurable symbols. */

/* The size, in bytes, of the reserved section at the end of VRAM. */
/* Traditionally, ARM7 reserves 0x40 bytes here. */
PROVIDE(__vram_reserved_size = 0x40);
ASSERT((__vram_reserved_size & 3) == 0, "__vram_reserved_size must be a multiple of 4");

/* ARM supervisor (SWI calls) stack size. */
PROVIDE(__svc_stack_size = 0x100);
ASSERT((__svc_stack_size & 3) == 0, "__svc_stack_size must be a multiple of 4");

/* ARM interrupt handler stack size. */
PROVIDE(__irq_stack_size = 0x100);
ASSERT((__irq_stack_size & 3) == 0, "__irq_stack_size must be a multiple of 4");

PHDRS {
    crt0  PT_LOAD FLAGS(7);
    arm7  PT_LOAD FLAGS(7);
}

MEMORY {
    vram : ORIGIN = 0x06000000, LENGTH = 128K
}

__vram_start	=	ORIGIN(vram);
__vram_top	=	ORIGIN(vram) + LENGTH(vram);

__sp_irq	=	__vram_top - __vram_reserved_size;
__sp_svc	=	__sp_irq - __irq_stack_size;
__sp_usr	=	__sp_svc - __svc_stack_size;

__irq_flags	=	0x04000000 - 8;
__irq_flagsaux	=	0x04000000 - 0x40;
__irq_vector	=	0x04000000 - 4;

SECTIONS
{
    .crt0	:
    {
        KEEP (*(.crt0))
        . = ALIGN(4);
    } >vram :crt0 =0xff 

    .text :
    {
        __arm7_lma__ = LOADADDR(.text);
        __arm7_start__ = .;
        KEEP (*(SORT_NONE(.init)))
        *(.plt)
        *(.text .stub .text.* .gnu.linkonce.t.*)
        KEEP (*(.text.*personality*))
        /* .gnu.warning sections are handled specially by elf32.em.  */
        *(.gnu.warning)
        *(.glue_7t) *(.glue_7) *(.v4_bx)
        . = ALIGN(4);
    } >vram = 0xff

    .fini           :
    {
        KEEP (*(.fini))
    } >vram =0xff

    .rodata :
    {
        *(.rodata)
        *all.rodata*(*)
        *(.roda)
        *(.rodata.*)
        *(.gnu.linkonce.r*)
        SORT(CONSTRUCTORS)
        . = ALIGN(4);
    } >vram = 0xff

    .ARM.extab   : { *(.ARM.extab* .gnu.linkonce.armextab.*) } >vram

    .ARM.exidx   : {
        __exidx_start = .;
        *(.ARM.exidx* .gnu.linkonce.armexidx.*)
        __exidx_end = .;
    } >vram

    /* Ensure the __preinit_array_start label is properly aligned.  We
       could instead move the label definition inside the section, but
       the linker would then create the section even if it turns out to
       be empty, which isn't pretty.  */
    . = ALIGN(32 / 8);
    .init_array :
    {
        PROVIDE (__preinit_array_start = .);
        PROVIDE (__bothinit_array_start = .);
        KEEP (*(.preinit_array))
        PROVIDE (__preinit_array_end = .);

        PROVIDE (__init_array_start = .);
        KEEP (*(SORT_BY_INIT_PRIORITY(.init_array.*) SORT_BY_INIT_PRIORITY(.ctors.*)))
        KEEP (*(.init_array EXCLUDE_FILE (*crtbegin.o *crtbegin?.o *crtend.o *crtend?.o ) .ctors))
        PROVIDE (__init_array_end = .);
        PROVIDE (__bothinit_array_end = .);
    } >vram = 0xff
    .fini_array :
    {
        PROVIDE (__fini_array_start = .);
        KEEP (*(SORT_BY_INIT_PRIORITY(.fini_array.*) SORT_BY_INIT_PRIORITY(.dtors.*)))
        KEEP (*(.fini_array EXCLUDE_FILE (*crtbegin.o *crtbegin?.o *crtend.o *crtend?.o ) .dtors))
        /* Required by pico-exitprocs.c. */
        KEEP (*(.fini_array*))
        PROVIDE (__fini_array_end = .);
    } >vram = 0xff

    .ctors :
    {
        /* gcc uses crtbegin.o to find the start of
           the constructors, so we make sure it is
           first.  Because this is a wildcard, it
           doesn't matter if the user does not
           actually link against crtbegin.o; the
           linker won't look for a file to match a
           wildcard.  The wildcard also means that it
           doesn't matter which directory crtbegin.o
           is in.  */
        KEEP (*crtbegin.o(.ctors))
        KEEP (*crtbegin?.o(.ctors))
        /* We don't want to include the .ctor section from
           the crtend.o file until after the sorted ctors.
           The .ctor section from the crtend file contains the
           end of ctors marker and it must be last */
        KEEP (*(EXCLUDE_FILE (*crtend.o *crtend?.o ) .ctors))
        KEEP (*(SORT(.ctors.*)))
        KEEP (*(.ctors))
        . = ALIGN(4);   /* REQUIRED. LD is flaky without it. */
    } >vram = 0xff

    .dtors :
    {
        KEEP (*crtbegin.o(.dtors))
        KEEP (*crtbegin?.o(.dtors))
        KEEP (*(EXCLUDE_FILE (*crtend.o *crtend?.o ) .dtors))
        KEEP (*(SORT(.dtors.*)))
        KEEP (*(.dtors))
        . = ALIGN(4);   /* REQUIRED. LD is flaky without it. */
    } >vram = 0xff

    .eh_frame :
    {
        KEEP (*(.eh_frame))
        . = ALIGN(4);   /* REQUIRED. LD is flaky without it. */
    } >vram = 0xff

    .gcc_except_table :
    {
        *(.gcc_except_table .gcc_except_table.*)
        . = ALIGN(4);   /* REQUIRED. LD is flaky without it. */
    } >vram = 0xff
    .got            : { *(.got.plt) *(.got) } >vram = 0

    .data ALIGN(4) : 	{
        __data_start = ABSOLUTE(.);
        *(.data)
        *(.data.*)
        *(.gnu.linkonce.d*)
        CONSTRUCTORS
        . = ALIGN(4);
    } >vram = 0xff

    .bss ALIGN(4) (NOLOAD) :
    {
        __bss_start = ABSOLUTE(.);
        __bss_start__ = ABSOLUTE(.);
        *(.dynbss)
        *(.gnu.linkonce.b*)
        *(.bss*)
        *(COMMON)
        . = ALIGN(4);
        __bss_end__ = ABSOLUTE(.);
        __arm7_end__ = .;
    } >vram

    .noinit (NOLOAD):
    {
        __noinit_start = ABSOLUTE(.);
        *(.noinit .noinit.* .gnu.linkonce.n.*)
        . = ALIGN(4);
        __noinit_end = ABSOLUTE(.);
    } >vram

    HIDDEN(__arm7_size__ = __arm7_end__ - __arm7_start__);
    HIDDEN(__bss_size__ = __bss_end__ - __bss_start__);

    /* Stabs debugging sections.  */
    .stab          0 : { *(.stab) }
    .stabstr       0 : { *(.stabstr) }
    .stab.excl     0 : { *(.stab.excl) }
    .stab.exclstr  0 : { *(.stab.exclstr) }
    .stab.index    0 : { *(.stab.index) }
    .stab.indexstr 0 : { *(.stab.indexstr) }
    .comment 0 (INFO) : { *(.comment); LINKER_VERSION; }
    .gnu.build.attributes : { *(.gnu.build.attributes .gnu.build.attributes.*) }
    /* DWARF debug sections.
       Symbols in the DWARF debugging sections are relative to the beginning
       of the section so we begin them at 0.  */
    /* DWARF 1.  */
    .debug          0 : { *(.debug) }
    .line           0 : { *(.line) }
    /* GNU DWARF 1 extensions.  */
    .debug_srcinfo  0 : { *(.debug_srcinfo) }
    .debug_sfnames  0 : { *(.debug_sfnames) }
    /* DWARF 1.1 and DWARF 2.  */
    .debug_aranges  0 : { *(.debug_aranges) }
    .debug_pubnames 0 : { *(.debug_pubnames) }
    /* DWARF 2.  */
    .debug_info     0 : { *(.debug_info .gnu.linkonce.wi.*) }
    .debug_abbrev   0 : { *(.debug_abbrev) }
    .debug_line     0 : { *(.debug_line .debug_line.* .debug_line_end) }
    .debug_frame    0 : { *(.debug_frame) }
    .debug_str      0 : { *(.debug_str) }
    .debug_loc      0 : { *(.debug_loc) }
    .debug_macinfo  0 : { *(.debug_macinfo) }
    /* SGI/MIPS DWARF 2 extensions.  */
    .debug_weaknames 0 : { *(.debug_weaknames) }
    .debug_funcnames 0 : { *(.debug_funcnames) }
    .debug_typenames 0 : { *(.debug_typenames) }
    .debug_varnames  0 : { *(.debug_varnames) }
    /* DWARF 3.  */
    .debug_pubtypes 0 : { *(.debug_pubtypes) }
    .debug_ranges   0 : { *(.debug_ranges) }
    /* DWARF 5.  */
    .debug_addr     0 : { *(.debug_addr) }
    .debug_line_str 0 : { *(.debug_line_str) }
    .debug_loclists 0 : { *(.debug_loclists) }
    .debug_macro    0 : { *(.debug_macro) }
    .debug_names    0 : { *(.debug_names) }
    .debug_rnglists 0 : { *(.debug_rnglists) }
    .debug_str_offsets 0 : { *(.debug_str_offsets) }
    .debug_sup      0 : { *(.debug_sup) }
    .ARM.attributes 0 : { KEEP (*(.ARM.attributes)) KEEP (*(.gnu.attributes)) }
    .note.gnu.arm.ident 0 : { KEEP (*(.note.gnu.arm.ident)) }
    /DISCARD/ : { *(.note.GNU-stack) *(.gnu_debuglink) *(.gnu.lto_*) }
}
