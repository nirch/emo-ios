#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Pre build emu ios app script.
This script runs on every build of the application.
"""

import sys
import plistlib
import base64
import time
import datetime
import os
import shutil
import socket

K_SRCROOT = "srcroot"
K_TARGET_NAME = "target_name"
K_EFFECTIVE_PLATFORM_NAME = "effective_platform_name"
K_INFOPLIST_FILE = "infoplist_file"
K_CONFIGURATION = "configuration"

# PODS_COPY_RESOURCES_SCRIPT = "Pods/Target Support Files/Pods/Pods-resources.sh"

HEADER = """
----------------------------------------------------------------
Emu - PRE BUILD SCRIPT
By: Aviv Wolf
----------------------------------------------------------------
"""

FOOTER = """
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
"""


def cfg_from_args(args):
    cfg = {
        K_SRCROOT:args[1],
        K_TARGET_NAME:args[2],
        K_EFFECTIVE_PLATFORM_NAME:args[3],
        K_INFOPLIST_FILE:args[4],
        K_CONFIGURATION:args[5]
    }
    return cfg


class Builder:
    def __init__(self, cfg):
        self.cfg = cfg
        self.is_debug = cfg[K_CONFIGURATION] == 'Debug'
        self.info = plistlib.readPlist(cfg[K_INFOPLIST_FILE])

    def build_target(self):
        print "Build target '%s'" % self.cfg[K_TARGET_NAME]
        print "Configuration: '%s'" % self.cfg[K_CONFIGURATION]

    def update_build_info(self):
        file_name = "%s_latest_build_info.plist" % self.cfg[K_TARGET_NAME]
        path = os.path.join(self.cfg[K_SRCROOT], "emu", "App", "Supporting Files", file_name)
        
        info = plistlib.readPlist(path)

        # inc build counter
        if "build_counter" in info:
            info["build_counter"] = info["build_counter"] + 1
        else:
            info["build_counter"] = 1

        info["build_type"] = cfg[K_CONFIGURATION]
        info["target_name"] = cfg[K_TARGET_NAME]
        info["build_date"] = datetime.datetime.now() 
        info["machine_name"] = socket.gethostname()

        plistlib.writePlist(info, path)





if __name__ == '__main__':
    print HEADER

    # Get parameters.
    args = sys.argv
    cfg = cfg_from_args(args)

    # Bob the builder
    bob = Builder(cfg)
    bob.build_target()
    bob.update_build_info()
    print FOOTER