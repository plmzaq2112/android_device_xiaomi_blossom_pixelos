#!/usr/bin/env python3
"""Extract boot.img DTB or trim a DTBO partition dump.

Usage:
    extract-stock-dt.py boot <boot.img> <out-dtb.img>
    extract-stock-dt.py dtbo <dtbo-partition.img> <out-dtbo.img>

The boot extractor supports Android boot image header v1/v2 (this device is
header v2, page size 2048). It only reads; nothing is modified in place.
"""
import struct
import sys


def u32(buf, off):
    return struct.unpack_from("<I", buf, off)[0]


def u32be(buf, off):
    # dt_table_header (dtbo) stores all fields big-endian.
    return struct.unpack_from(">I", buf, off)[0]


def align_up(x, page):
    return ((x + page - 1) // page) * page


def extract_boot_dtb(src, dst):
    data = open(src, "rb").read()
    page = u32(data, 36)
    hdr_ver = u32(data, 40)
    if page not in (2048, 4096):
        raise SystemExit(f"unexpected page size: {page}")
    if hdr_ver < 2:
        raise SystemExit(f"header version {hdr_ver} has no dtb section")

    kernel_size = u32(data, 8)
    ramdisk_size = u32(data, 16)
    second_size = u32(data, 24)
    dtb_size = u32(data, 1648)

    if dtb_size == 0:
        raise SystemExit("dtb size is 0")

    off = page
    off += align_up(kernel_size, page)
    off += align_up(ramdisk_size, page)
    off += align_up(second_size, page)
    dtb = data[off:off + dtb_size]
    if len(dtb) != dtb_size:
        raise SystemExit("truncated dtb section")

    with open(dst, "wb") as f:
        f.write(dtb)
    print(f"boot dtb: {dtb_size} bytes -> {dst}")


def extract_dtbo(src, dst):
    data = open(src, "rb").read()
    magic = u32be(data, 0)
    if magic != 0xD7B7AB1E:
        raise SystemExit(f"bad dtbo magic: 0x{magic:08x}")
    total_size = u32be(data, 4)
    if total_size == 0 or total_size > len(data):
        raise SystemExit(f"invalid dtbo total_size: {total_size}")

    with open(dst, "wb") as f:
        f.write(data[:total_size])
    print(f"dtbo: {total_size} bytes (from {len(data)} byte partition) -> {dst}")


def main():
    if len(sys.argv) != 4 or sys.argv[1] not in ("boot", "dtbo"):
        raise SystemExit(__doc__)
    mode, src, dst = sys.argv[1:]
    if mode == "boot":
        extract_boot_dtb(src, dst)
    else:
        extract_dtbo(src, dst)


if __name__ == "__main__":
    main()
