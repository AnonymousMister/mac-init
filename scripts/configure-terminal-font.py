#!/usr/bin/env python3
# ==============================================================================
# 一键解除字体隔离、注册 CoreText 并自动配置 Terminal.app 默认字体
# ==============================================================================

import os
import glob
import plistlib
import subprocess
import ctypes
import ctypes.util

def unquarantine_fonts():
    """解除 macOS Gatekeeper 对字体的隔离属性"""
    font_pattern = os.path.expanduser("~/Library/Fonts/JetBrainsMono*")
    fonts = glob.glob(font_pattern)
    if not fonts:
        print("[!] 未在 ~/Library/Fonts 找到 JetBrainsMono 字体文件")
        return False

    print(f">> 正在解除 {len(fonts)} 个字体文件的 Gatekeeper 隔离属性...")
    subprocess.run(["xattr", "-rd", "com.apple.quarantine"] + fonts, stderr=subprocess.DEVNULL)
    return True

def register_fonts_coretext():
    """通过 CoreText 动态激活字体至用户环境"""
    try:
        ct = ctypes.cdll.LoadLibrary(ctypes.util.find_library("CoreText"))
        cf = ctypes.cdll.LoadLibrary(ctypes.util.find_library("CoreFoundation"))

        cf.CFURLCreateFromFileSystemRepresentation.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_long, ctypes.c_bool]
        cf.CFURLCreateFromFileSystemRepresentation.restype = ctypes.c_void_p

        ct.CTFontManagerRegisterFontsForURL.argtypes = [ctypes.c_void_p, ctypes.c_uint32, ctypes.POINTER(ctypes.c_void_p)]
        ct.CTFontManagerRegisterFontsForURL.restype = ctypes.c_bool

        font_files = glob.glob(os.path.expanduser("~/Library/Fonts/JetBrainsMono*.ttf"))
        count = 0
        for f in font_files:
            url = cf.CFURLCreateFromFileSystemRepresentation(None, f.encode("utf-8"), len(f.encode("utf-8")), False)
            err = ctypes.c_void_p()
            if ct.CTFontManagerRegisterFontsForURL(url, 2, ctypes.byref(err)):
                count += 1
        print(f"✓ 已通过 CoreText 向系统激活注册字体 (成功: {count})")
    except Exception as e:
        print(f"[!] 动态注册字体异常 (可忽略): {e}")

def configure_terminal_app(font_name="JetBrainsMonoNFM-Regular", font_size=13.0):
    """直接通过 plist 配置 macOS 自带 Terminal.app 的默认字体"""
    plist_path = os.path.expanduser("~/Library/Preferences/com.apple.Terminal.plist")
    if not os.path.exists(plist_path):
        print(f"[!] 未找到 Terminal.plist: {plist_path}")
        return False

    print(f">> 正在将 Terminal.app 字体配置为: {font_name} ({font_size}pt)...")

    # 构建 NSKeyedArchiver 结构
    font_archive = {
        "$version": 100000,
        "$archiver": "NSKeyedArchiver",
        "$top": {"root": plistlib.UID(1)},
        "$objects": [
            "$null",
            {
                "NSSize": float(font_size),
                "NSfFlags": 16,
                "NSName": plistlib.UID(2),
                "$class": plistlib.UID(3),
            },
            font_name,
            {"$classname": "NSFont", "$classes": ["NSFont", "NSObject"]},
        ],
    }
    font_bytes = plistlib.dumps(font_archive, fmt=plistlib.FMT_BINARY)

    with open(plist_path, "rb") as f:
        data = plistlib.load(f)

    ws = data.get("Window Settings", {})
    default_prof = data.get("Default Window Settings", "Basic")
    startup_prof = data.get("Startup Window Settings", "Basic")

    target_profiles = set([default_prof, startup_prof, "Clear Dark", "Basic", "Pro"])

    for prof_name in target_profiles:
        if prof_name in ws:
            ws[prof_name]["Font"] = font_bytes
            ws[prof_name]["FontWidthSpacing"] = 1.0
            ws[prof_name]["FontAntialias"] = True

    with open(plist_path, "wb") as f:
        plistlib.dump(data, f, fmt=plistlib.FMT_BINARY)

    subprocess.run(["killall", "cfprefsd"], stderr=subprocess.DEVNULL)
    print("✓ Terminal.app 偏好设置已成功写入并刷新缓存！")
    return True

if __name__ == "__main__":
    unquarantine_fonts()
    register_fonts_coretext()
    configure_terminal_app()
