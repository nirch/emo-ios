#!/usr/bin/python
# -*- coding: utf-8 -*-
import os
import collections
import textwrap
import codecs
import time
import plistlib
import re
import cgi
from jinja2 import Environment, PackageLoader
env = Environment(loader=PackageLoader('writer', 'templates'))

CFG_FILE = "../emu/Data/Reports/Analytics.plist"
OUTPUT_FILE = "/Users/aviv/Google Drive/homagedocs/AnalyticsDocs.html"

def main():
    # read the plist file
    cfg = plistlib.readPlist(CFG_FILE)

    template = env.get_template('analytics_docs.html')

    # recreate the HMAnalyticsEvents.h file.
    creation_time = str(time.strftime('%X %x %Z'))
    script_name = os.path.basename(__file__)

    with codecs.open(OUTPUT_FILE, 'w', encoding='utf8') as f:
        # Prepare data
        super_params = cfg["superParams"]
        super_params_keys = super_params.keys()

        events = cfg["events"]
        events_keys = collections.OrderedDict(sorted(events.items()))

        # Write the docs
        f.write(template.render(locals()))
        f.close()

    print "Updated: %s" % creation_time

if __name__ == '__main__':
    main()
