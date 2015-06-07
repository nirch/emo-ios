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
OUTPUT_H_FILE = "../emu/Data/Reports/HMExperiments.h"
OUTPUT_M_FILE = "../emu/Data/Reports/HMExperiments.m"

HEADER = """//
//  HMExperiments.h
//  emu
//
//  Created by produce_experiments_resource_file.py script.
//  Copyright (c) 2015 Homage. All rights reserved.
//
"""

FOOTER = """/**
 HMExperiments auto generated class
 */
@interface HMExperiments : NSObject

@property NSDictionary *opKeysByString;

@end
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

LIVE_VARIABLE_KEY_STRING = """/** %(variable_name)s : %(description)s  */
#define %(variable_name_uc)s @"%(variable_name)s" """

GOAL_KEY_STRING = """/** %(goal_name)s : %(description)s  */
#define %(goal_name_uc)s @"%(goal_name)s" """

EXPERIMENTS_IMPLEMENTATION_IMPORTS = """
//
//  HMExperiments.m
//  emu
//
//  Created by produce_experiments_resource_file.py script.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "HMExperiments.h"
#import <Optimizely/Optimizely.h>
"""

EXPERIMENTS_IMPLEMENTATION_CODE = """
@implementation HMExperiments

-(instancetype)init
{
    self = [super init];
    if (self) {
        self.opKeysByString = @{
            %(op_keys_by_string)s
        };
    }
    return self;
}

@end
"""

KEY_BY_STRING_LINE = '\t\t\t@"%s":%s'

first_cap_re = re.compile('(.)([A-Z][a-z]+)')
all_cap_re = re.compile('([a-z0-9])([A-Z])')

def convert_to_constant_name(prefix, name):
    name = "%s_%s" % (prefix, name)
    name = name.replace(":", "_")
    s1 = first_cap_re.sub(r'\1_\2', name)
    return all_cap_re.sub(r'\1_\2', s1).upper()

def write_live_variables_h(f, cfg):

    # Live variables
    f.write("#pragma mark - Live Variables\n")
    f.write("//\n")
    f.write("// Live Variables\n")
    f.write("//\n\n")
    variables = cfg["Live Variables"]
    ordered_variables = collections.OrderedDict(sorted(variables.items()))
    for key in ordered_variables:
        variable_name = key
        variable_info = variables[key]
        description = variable_info["description"]
        variable_name_uc = convert_to_constant_name("Vk", variable_name)
        f.write(LIVE_VARIABLE_KEY_STRING % locals())
        f.write("\n\n")
    f.write("\n\n")

    # Goals
    f.write("#pragma mark - Goals\n")
    f.write("//\n")
    f.write("// Goals\n")
    f.write("//\n\n")
    goals = cfg["Goals"]
    ordered_goals = collections.OrderedDict(sorted(goals.items()))
    for key in ordered_goals:
        goal_name = key
        goal_info = goals[key]
        description = goal_info["description"]
        goal_name_uc = convert_to_constant_name("Gk", goal_name)
        f.write(GOAL_KEY_STRING % locals())
        f.write("\n\n")
    f.write("\n\n")

    f.write(FOOTER)


def write_live_variables_m(f, cfg):
    f.write(EXPERIMENTS_IMPLEMENTATION_IMPORTS)

    variables = cfg["Live Variables"]
    ordered_variables = collections.OrderedDict(sorted(variables.items()))

    lines = []
    for key in ordered_variables:
        # Live variable
        v_info = variables[key]
        variable_name = key
        value_type = v_info["valueType"]
        default_value = v_info["defaultValue"]
        description = v_info["description"]
        variable_name_uc = convert_to_constant_name("LK", variable_name)

        var_type_suffix = var_type_suffix_for_var_type(value_type)
        default_value_obj_c = obj_c_value_for_value(default_value, value_type)

        # Write the string for this live variable
        live_var_string = LIVE_VARIABLE % locals()
        f.write(live_var_string)
        f.write("\n\n")

        lines.append(KEY_BY_STRING_LINE % (key, key))

    op_keys_by_string = ',\n'.join(lines)
    op_keys_by_string = op_keys_by_string.strip()
    f.write(EXPERIMENTS_IMPLEMENTATION_CODE % locals())


def var_type_suffix_for_var_type(var_type):
    # Currently, pass through.
    # Implement mapping of var types as required
    return var_type


def obj_c_value_for_value(value, var_type):
    if var_type == "Bool":
        if value:
            return "YES"
        else:
            return "NO"
    elif var_type == "String":
        return '@"%s"' % value
    elif var_type == "Number":
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
    with codecs.open(OUTPUT_H_FILE, 'w', encoding='utf8') as f:
        f.write(HEADER % locals())
        print "Recreating h file...\n"
        print HEADER % locals()
        f.write("\n\n")
        write_live_variables_h(f, cfg)
        f.write("\n\n")
        f.close()
        print "Done: h file."

    # recreate the HMExperiments.m file.
    with codecs.open(OUTPUT_M_FILE, 'w', encoding='utf8') as f:
        print "Recreating m file...\n"
        write_live_variables_m(f, cfg)
        print "Done: m file."

if __name__ == '__main__':
    main()
