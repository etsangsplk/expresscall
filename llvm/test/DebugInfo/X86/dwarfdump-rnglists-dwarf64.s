# RUN: llvm-mc -triple x86_64-unknown-linux %s -filetype=obj -o %t.o
# RUN: llvm-dwarfdump -v -debug-info %t.o 2> %t.err | FileCheck %s
# RUN: FileCheck %s --input-file %t.err --check-prefix=ERR
# RUN: llvm-dwarfdump -lookup 10 %t.o 2> %t2.err
# RUN: FileCheck %s --input-file %t2.err --check-prefix=ERR

# Test object to verify dwarfdump handles v5 range lists in 64-bit DWARF format.
# This is similar to 'dwarfdump-rnglists.s', which uses 32-bit DWARF format.
# We use very simplified compile unit dies.
# There are 2 full CUs with DW_AT_rnglists_base, one with a DW_AT_ranges
# attribute using DW_FORM_sec_offset, the other with DW_AT_ranges using
# DW_FORM_rnglistx.

        .section .debug_abbrev,"",@progbits
        .byte 0x01  # Abbrev code
        .byte 0x11  # DW_TAG_compile_unit
        .byte 0x00  # DW_CHILDREN_no
        .byte 0x74  # DW_AT_rnglists_base
        .byte 0x17  # DW_FORM_sec_offset
        .byte 0x55  # DW_AT_ranges
        .byte 0x17  # DW_FORM_sec_offset
        .byte 0x00  # EOM(1)
        .byte 0x00  # EOM(2)
        .byte 0x02  # Abbrev code
        .byte 0x11  # DW_TAG_compile_unit
        .byte 0x00  # DW_CHILDREN_no
        .byte 0x74  # DW_AT_rnglists_base
        .byte 0x17  # DW_FORM_sec_offset
        .byte 0x55  # DW_AT_ranges
        .byte 0x23  # DW_FORM_rnglistx
        .byte 0x00  # EOM(1)
        .byte 0x00  # EOM(2)
        .byte 0x00  # EOM(3)

# The split CU uses DW_FORM_rnglistx (the only correct option).
# There is no DW_AT_rnglists_base in split units.
        .section .debug_abbrev.dwo,"",@progbits
        .byte 0x01  # Abbrev code
        .byte 0x11  # DW_TAG_compile_unit
        .byte 0x00  # DW_CHILDREN_no
        .byte 0x55  # DW_AT_ranges
        .byte 0x23  # DW_FORM_rnglistx
        .byte 0x00  # EOM(1)
        .byte 0x00  # EOM(2)
        .byte 0x00  # EOM(3)
        
        .section .debug_info,"",@progbits
        .long 0xffffffff       # DWARF64 mark
        .quad  CU1_5_64_end - CU1_5_64_version  # Length of Unit
CU1_5_64_version:
        .short 5               # DWARF version number
        .byte 1                # DWARF Unit Type
        .byte 4                # Address Size (in bytes)
        .quad .debug_abbrev    # Offset Into Abbrev. Section
# The compile-unit DIE, which has DW_AT_rnglists_base and DW_AT_ranges.
        .byte 1                # Abbreviation code
        .quad Rnglist_Table0_base     # DW_AT_rnglists_base
        .quad Rnglist_Table0_Rnglist0 # DW_AT_ranges
CU1_5_64_end:

        .long 0xffffffff       # DWARF64 mark
        .quad  CU2_5_64_end - CU2_5_64_version  # Length of Unit
CU2_5_64_version:
        .short 5               # DWARF version number
        .byte 1                # DWARF Unit Type
        .byte 4                # Address Size (in bytes)
        .quad .debug_abbrev    # Offset Into Abbrev. Section
# The compile-unit DIE, which has DW_AT_rnglists_base and DW_AT_ranges.
        .byte 2                # Abbreviation code
        .quad Rnglist_Table0_base   # DW_AT_rnglists_base
        .uleb128 1             # DW_AT_ranges
CU2_5_64_end:

# A CU with an invalid DW_AT_rnglists_base attribute
        .long 0xffffffff       # DWARF64 mark
        .quad  CU3_5_64_end - CU3_5_64_version  # Length of Unit
CU3_5_64_version:
        .short 5               # DWARF version number
        .byte 1                # DWARF Unit Type
        .byte 4                # Address Size (in bytes)
        .quad .debug_abbrev    # Offset Into Abbrev. Section
# The compile-unit DIE, which has DW_AT_rnglists_base and DW_AT_ranges.
        .byte 2                # Abbreviation code
        .quad 0x8              # DW_AT_rnglists_base
        .uleb128 0             # DW_AT_ranges
CU3_5_64_end:

# A CU DIE with an incorrect DW_AT_ranges attribute
        .long 0xffffffff       # DWARF64 mark
        .quad  CU4_5_64_end - CU4_5_64_version  # Length of Unit
CU4_5_64_version:
        .short 5               # DWARF version number
        .byte 1                # DWARF Unit Type
        .byte 4                # Address Size (in bytes)
        .quad .debug_abbrev    # Offset Into Abbrev. Section
# The compile-unit DIE, which has DW_AT_rnglists_base and DW_AT_ranges.
        .byte 1                # Abbreviation code
        .quad Rnglist_Table0_base   # DW_AT_rnglists_base
        .quad 4000             # DW_AT_ranges
CU4_5_64_end:

        .section .debug_info.dwo,"",@progbits

# DWARF v5 split CU header.
        .long 0xffffffff       # DWARF64 mark
        .quad  CU_split_5_64_end-CU_split_5_64_version  # Length of Unit
CU_split_5_64_version:
        .short 5               # DWARF version number
        .byte 5                # DWARF Unit Type
        .byte 4                # Address Size (in bytes)
        .quad 0                # Offset Into Abbrev Section
# The compile-unit DIE, which has DW_AT_rnglists_base and DW_AT_ranges.
        .byte 1                # Abbreviation code
        .uleb128 1             # DW_AT_ranges
CU_split_5_64_end:

        .section .debug_rnglists,"",@progbits
# A rnglist table with 2 range lists. The first one uses DW_RLE_start_end
# and DW_RLE_start_length. The second one uses DW_RLE_base_address and
# DW_RLE_offset_pair. The range lists have entries in the offset table.
        .long 0xffffffff                            # DWARF64 mark
        .quad Rnglist_Table0_end - Rnglist_Table0   # table length
Rnglist_Table0:
        .short 5                                    # version
        .byte 4                                     # address size
        .byte 0                                     # segment selector size
        .long 2                                     # offset entry count
Rnglist_Table0_base:
# 2 offset entries which can be used by DW_FORM_rnglistx.
        .quad Rnglist_Table0_Rnglist0 - Rnglist_Table0_base
        .quad Rnglist_Table0_Rnglist1 - Rnglist_Table0_base
Rnglist_Table0_Rnglist0:
        .byte 6                                     # DW_RLE_start_end
        .long Range0_start
        .long Range0_end
        .byte 7                                     # DW_RLE_start_length
        .long Range1_start
        .uleb128 Range1_end - Range1_start 
        .byte 0                                     # DW_RLE_end_of_list
Rnglist_Table0_Rnglist1:
        .byte 5                                     # DW_RLE_base_address
        .long Range0_start
        .byte 4                                     # DW_RLE_offset_pair
        .uleb128 Range1_start - Range0_start
        .uleb128 Range1_end - Range0_start
        .byte 0                                     # DW_RLE_end_of_list
Rnglist_Table0_end:

# A rnglist table for the split unit with an empty rangelist and one that
# uses DW_RLE_base_address and DW_RLE_offset_pair. The ranges have entries
# in the offset table. We use the empty range list so we can test 
# DW_FORM_rnglistx with an index other than 0.
        .section .debug_rnglists.dwo,"",@progbits
        .long 0xffffffff                            # DWARF64 mark
        .quad Rnglist_Table0_dwo_end - Rnglist_Table0_dwo   # table length
Rnglist_Table0_dwo:
        .short 5                                    # version
        .byte 4                                     # address size
        .byte 0                                     # segment selector size
        .long 2                                     # offset entry count
Rnglist_Table0_base_dwo:
# 2 offset entries which can be used by DW_FORM_rnglistx.
        .quad Rnglist_Table0_Rnglist0_dwo - Rnglist_Table0_base_dwo
        .quad Rnglist_Table0_Rnglist1_dwo - Rnglist_Table0_base_dwo
Rnglist_Table0_Rnglist0_dwo:
        .byte 0                                     # DW_RLE_start_end
Rnglist_Table0_Rnglist1_dwo:
        .byte 5                                     # DW_RLE_base_address
        .long Range0_start - .text
        .byte 4                                     # DW_RLE_offset_pair
        .uleb128 Range1_start - Range0_start
        .uleb128 Range1_end - Range0_start
        .byte 0                                     # DW_RLE_end_of_list
Rnglist_Table0_dwo_end:

.text
        .space 20
Range0_start:               # Range0: 0x14 - 0x1c
        .space 10
Range0_end:
        .space 12
Range1_start:               # Range1: 0x2a - 0x34
        .space 10
Range1_end:

# CHECK:      .debug_info contents:
# CHECK:      Compile Unit: 
# CHECK-NOT:  Compile Unit:
# CHECK:      DW_TAG_compile_unit
# CHECK-NEXT: DW_AT_rnglists_base [DW_FORM_sec_offset]  (0x00000014)
# CHECK-NEXT: DW_AT_ranges [DW_FORM_sec_offset] (0x00000024
# CHECK-NEXT: [0x00000014, 0x0000001e) ".text"
# CHECK-NEXT: [0x0000002a, 0x00000034) ".text")

# CHECK:      Compile Unit:
# CHECK-NOT:  Compile Unit:
# CHECK:      DW_TAG_compile_unit
# CHECK-NEXT: DW_AT_rnglists_base [DW_FORM_sec_offset]  (0x00000014)
# CHECK-NEXT: DW_AT_ranges [DW_FORM_rnglistx] (indexed (0x1) rangelist = 0x00000034
# CHECK-NEXT: [0x0000002a, 0x00000034) ".text")

# CHECK:      .debug_info.dwo contents:
# CHECK:      Compile Unit:
# CHECK-NOT:  contents:
# CHECK:      DW_TAG_compile_unit
# CHECK-NEXT: DW_AT_ranges [DW_FORM_rnglistx] (indexed (0x1) rangelist = 0x00000025
# CHECK-NEXT: [0x0000002a, 0x00000034))

#ERR: error: parsing a range list table: did not detect a valid list table with base = 0x8
#ERR: error: decoding address ranges: missing or invalid range list table
#ERR: error: decoding address ranges: invalid range list offset 0xfa0
