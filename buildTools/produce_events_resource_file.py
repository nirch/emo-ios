#!/usr/bin/python
# -*- coding: utf-8 -*-
import os
import collections
import textwrap
import codecs
import time
import plistlib
import re

CFG_FILE = "../emu/Data/Reports/Analytics.plist"
OUTPUT_FILE = "../emu/Data/Reports/HMAnalyticsEvents.h"

HEADER = """//
//  HMAnalyticsEvents.h
//  emu
//
//  Created by build script on %(creation_time)s
//  Copyright (c) 2015 Homage. All rights reserved.
//
"""

INDENT = "    "


first_cap_re = re.compile('(.)([A-Z][a-z]+)')
all_cap_re = re.compile('([a-z0-9])([A-Z])')


def convert_to_constant_name(name):
    name = "AK_%s" % name
    name = name.replace(":", "_")
    s1 = first_cap_re.sub(r'\1_\2', name)
    return all_cap_re.sub(r'\1_\2', s1).upper()


def write_super_params(f, cfg):
    f.write("#pragma mark - Super parameters\n")
    f.write("//\n")
    f.write("// Super parameters\n")
    f.write("//\n\n")

    super_params = cfg["superParams"]
    for key in super_params:
        k = "s_%s" % key
        val = super_params[key]

        text = "\n".join(textwrap.wrap(
            val["description"],
            subsequent_indent=INDENT)
        )
        f.write("\n/** %s **/\n" % text)
        f.write("#define %s @\"%s\"" % (convert_to_constant_name(k), key))
        f.write("\n\n")


def write_analytics_events(f, cfg):
    f.write("#pragma mark - Analytics events\n")
    f.write("//\n")
    f.write("// Analytics events\n")
    f.write("//\n\n")

    events = cfg["events"]

    ordered_events = collections.OrderedDict(sorted(events.items()))
    for key in ordered_events:
        # event
        k = "e%s" % key
        val = events[key]

        text = "\n".join(textwrap.wrap(
            val["description"],
            subsequent_indent=INDENT)
        )

        # remark
        f.write("\n/**%s\n%s\n**/\n" % (" -"*40, text))

        # event name
        f.write("#define %s @\"%s\"\n" % (convert_to_constant_name(k), key))

        # event params
        if not val.has_key("params"):
            continue

        params = val["params"]
        for param_k in params:
            pk = "ep_%s" % param_k
            p_val = params[param_k]
            f.write("\n/** Param:%s --> %s **/\n" % (param_k, p_val))
            f.write("#define %s @\"%s\"\n" % (convert_to_constant_name(pk), param_k))

        f.write("\n")


def main():
    # read the plist file
    cfg = plistlib.readPlist(CFG_FILE)

    # recreate the HMAnalyticsEvents.h file.
    creation_time = str(time.strftime('%X %x %Z'))
    with codecs.open(OUTPUT_FILE, 'w', encoding='utf8') as f:
        f.write(HEADER % locals())
        f.write("\n\n")
        write_super_params(f, cfg)
        f.write("\n\n")
        write_analytics_events(f, cfg)
        f.write("\n\n")
        f.close()



if __name__ == '__main__':
    main()
