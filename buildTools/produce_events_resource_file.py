#!/usr/bin/python
# -*- coding: utf-8 -*-
import os
import collections
import textwrap
import codecs
import time
import plistlib
import re

SCANNED_DIRECTORIES = ["../emu", "../Keyboard"]
CFG_FILE = "../emu/Data/Reports/Analytics.plist"
OUTPUT_FILE = "../emu/Data/Reports/HMAnalyticsEvents.h"

HEADER = """//
//  HMAnalyticsEvents.h
//  emu
//
//  Created by build script on %(creation_time)s
//  Build script name: %(script_name)s
//  Copyright (c) 2015 Homage. All rights reserved.
//
//  >>> !!! This is an automatically generated file. !!! <<<
//  >>> !!!       Do NOT edit this file by hand      !!! <<<
//
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


EVENT_MATCHER = re.compile(".*\[HMPanel.sh.*?analyticsEvent:(.*?)( |]).*")


def scan_for_all_events_in_file(dir_name, file_name):
    full_path = os.path.join(dir_name, file_name)
    events = {}
    with open(full_path) as m_file:
        for num, line in enumerate(m_file, 1):
            if EVENT_MATCHER.match(line):
                event_name = EVENT_MATCHER.match(line).group(1)
                event = {"file_name":file_name, "line_number":num, "dir_name":dir_name, "event_name":event_name}
                if event_name in events:
                    events[event_name].append(event)
                else:
                    events[event_name] = [event]
    return events


def scan_for_all_events_call_in_directory(directory):
    all_events = dict()
    for dir_name, subdir_list, file_list in os.walk(directory):
        for file_name in file_list:
            extension = file_name.split(".")[-1]
            if extension == "m" or extension == "mm":
                events = scan_for_all_events_in_file(dir_name, file_name)
                all_events.update(events)
    return all_events


def scan_for_all_events_calls():
    d = dict()

    for directory in SCANNED_DIRECTORIES:
        d.update(scan_for_all_events_call_in_directory(directory))

    return d


def main():
    # read the plist file
    cfg = plistlib.readPlist(CFG_FILE)

    # scan project implementation files
    # and search for all calls to analytics events
    events_calls = scan_for_all_events_calls()
    print "Found %d events names in project" % len(events_calls.keys())

    # recreate the HMAnalyticsEvents.h file.
    creation_time = str(time.strftime('%X %x %Z'))
    script_name = os.path.basename(__file__)
    with codecs.open(OUTPUT_FILE, 'w', encoding='utf8') as f:
        f.write(HEADER % locals())
        print "Recreating file...\n"
        print HEADER % locals()
        f.write("\n\n")
        write_super_params(f, cfg)
        f.write("\n\n")
        write_analytics_events(f, cfg)
        f.write("\n\n")
        f.close()
        print "Done."


if __name__ == '__main__':
    main()
