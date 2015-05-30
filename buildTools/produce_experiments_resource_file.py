#!/usr/bin/python
# -*- coding: utf-8 -*-
import os
import collections
import textwrap
import codecs
import time
import plistlib
import re

CFG_FILE = "../emu/Data/Reports/Experiments.plist"
OUTPUT_FILE = "../emu/Data/Reports/HMExperiments.h"

HEADER = """//
//  HMExperiments.h
//  emu
//
//  Created by Aviv Wolf on 5/27/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//
"""

INDENT = "    "


LIVE_VARIABLE = """/**
---------------------------------------
%(variable_name)s
---------------------------------------
value type: %(value_type)s
default values: %(default_value)s
description: %(description)s
*/
OptimizelyVariableKeyFor%(var_type_suffix)s(%(variable_name)s, %(default_value_obj_c)s);
"""

first_cap_re = re.compile('(.)([A-Z][a-z]+)')
all_cap_re = re.compile('([a-z0-9])([A-Z])')


def write_live_variables(f, cfg):
    f.write("#pragma mark - Live Variables\n")
    f.write("//\n")
    f.write("// Live Variables\n")
    f.write("//\n\n")

    variables = cfg["Live Variables"]

    ordered_variables = collections.OrderedDict(sorted(variables.items()))
    for key in ordered_variables:
        # Live variable
        v_info = variables[key]
        variable_name = key
        value_type = v_info["valueType"]
        default_value = v_info["defaultValue"]
        description = v_info["description"]

        var_type_suffix = var_type_suffix_for_var_type(value_type)
        default_value_obj_c = obj_c_value_for_value(default_value, value_type)

        # Write the string for this live variable
        live_var_string = LIVE_VARIABLE % locals()
        f.write(live_var_string)

#        val = events[key]
#
#        text = "\n".join(textwrap.wrap(
#            val["description"],
#            subsequent_indent=INDENT)
#        )
#
#        # remark
#        f.write("\n/**%s\n%s\n**/\n" % (" -"*40, text))
#
#        # event name
#        f.write("#define %s @\"%s\"\n" % (convert_to_constant_name(k), key))
#
#        # event params
#        if not val.has_key("params"):
#            continue
#
#        params = val["params"]
#        for param_k in params:
#            pk = "ep_%s" % param_k
#            p_val = params[param_k]
#            f.write("\n/** Param:%s --> %s **/\n" % (param_k, p_val))
#            f.write("#define %s @\"%s\"\n" % (convert_to_constant_name(pk), param_k))
#
#        f.write("\n")


def var_type_suffix_for_var_type(var_type):
    # Currently, pass through.
    # Implement mapping of var types as required
    return var_type


def obj_c_value_for_value(value, var_type):
    if var_type is "Bool":
        if value:
            return "YES"
        else:
            return "NO"
    elif var_type is "String":
        return '@"%s"' % value
    elif var_type is "Number":
        return '@%s' % value

    return '@"Var type %s unrecognized :-(!"' % var_type



def main():
    # read the plist file
    cfg = plistlib.readPlist(CFG_FILE)

    # scan project implementation files
    # and search for all calls to analytics events

    # recreate the HMExperiments.h file.
    creation_time = str(time.strftime('%X %x %Z'))
    script_name = os.path.basename(__file__)
    with codecs.open(OUTPUT_FILE, 'w', encoding='utf8') as f:
        f.write(HEADER % locals())
        print "Recreating file...\n"
        print HEADER % locals()
        f.write("\n\n")
        write_live_variables(f, cfg)
        f.write("\n\n")
        f.close()
        print "Done."


if __name__ == '__main__':
    main()
