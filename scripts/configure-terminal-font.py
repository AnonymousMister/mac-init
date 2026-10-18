#!/usr/bin/env python3
# ==============================================================================
# 兼容性封装：直接调用 register-fonts.py 仅执行系统字体库注册
# ==============================================================================
import sys
import os
import subprocess

script_dir = os.path.dirname(os.path.abspath(__file__))
target = os.path.join(script_dir, "register-fonts.py")
if os.path.exists(target):
    sys.exit(subprocess.call([sys.executable, target]))
