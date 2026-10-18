#!/usr/bin/env python3
# ==============================================================================
# 模块: Nerd Font 字体解除隔离与系统字体库注册
# 仅负责将字体解除 Gatekeeper 隔离并注册至系统全局字体库 (/Library/Fonts)
# 终端字体由用户在终端设置中按个人偏好自由配置
# ==============================================================================

import os
import glob
import subprocess
import ctypes
import ctypes.util

def unquarantine_and_install_fonts():
    """解除 Gatekeeper 隔离并同步至系统全局字体目录 /Library/Fonts"""
    font_pattern = os.path.expanduser("~/Library/Fonts/JetBrainsMono*")
    fonts = glob.glob(font_pattern)
    if not fonts:
        print("⚪ 未在 ~/Library/Fonts 找到 JetBrainsMono 字体文件，跳过注册")
        return False

    print(f">> 正在解除 {len(fonts)} 个字体文件的 Gatekeeper 隔离属性...")
    subprocess.run(["xattr", "-rd", "com.apple.quarantine"] + fonts, stderr=subprocess.DEVNULL)

    # 同步至系统全局字体目录 /Library/Fonts/
    sys_font_dir = "/Library/Fonts"
    try:
        if os.access(sys_font_dir, os.W_OK):
            print(">> 正在将字体同步注册至系统全局字体目录 /Library/Fonts/...")
            subprocess.run(["cp", "-f"] + fonts + [sys_font_dir], stderr=subprocess.DEVNULL)
            sys_fonts = glob.glob(os.path.join(sys_font_dir, "JetBrainsMono*"))
            if sys_fonts:
                subprocess.run(["xattr", "-rd", "com.apple.quarantine"] + sys_fonts, stderr=subprocess.DEVNULL)
            print("✓ 字体已成功注册至系统全局字体库！")
        else:
            print("ℹ️ /Library/Fonts 目录无直接写入权限，保留在 ~/Library/Fonts")
    except Exception as e:
        print(f"[!] 同步系统字体目录时跳过: {e}")

    # 调用 CoreText 动态注册激活
    try:
        ct = ctypes.cdll.LoadLibrary(ctypes.util.find_library("CoreText"))
        cf = ctypes.cdll.LoadLibrary(ctypes.util.find_library("CoreFoundation"))

        cf.CFURLCreateFromFileSystemRepresentation.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_long, ctypes.c_bool]
        cf.CFURLCreateFromFileSystemRepresentation.restype = ctypes.c_void_p

        ct.CTFontManagerRegisterFontsForURL.argtypes = [ctypes.c_void_p, ctypes.c_uint32, ctypes.POINTER(ctypes.c_void_p)]
        ct.CTFontManagerRegisterFontsForURL.restype = ctypes.c_bool

        font_files = glob.glob(os.path.join(sys_font_dir, "JetBrainsMono*.ttf")) or fonts
        count = 0
        for f in font_files:
            url = cf.CFURLCreateFromFileSystemRepresentation(None, f.encode("utf-8"), len(f.encode("utf-8")), False)
            err = ctypes.c_void_p()
            if ct.CTFontManagerRegisterFontsForURL(url, 2, ctypes.byref(err)):
                count += 1
        print(f"✓ 已通过 CoreText 向系统激活字体 (成功: {count})")
    except Exception as e:
        pass

    print("✓ Nerd Font 字体库注册已就绪（终端使用请在终端偏好设置中按需选择）。")
    return True

if __name__ == "__main__":
    unquarantine_and_install_fonts()
