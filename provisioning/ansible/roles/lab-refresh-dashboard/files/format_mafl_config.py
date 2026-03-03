#!/usr/bin/env python3
import yaml
import os
import sys

def format_config(path):
    if not os.path.exists(path):
        print(f"File not found: {path}")
        return

    class MyDumper(yaml.Dumper):
        def increase_indent(self, flow=False, indentless=False):
            return super(MyDumper, self).increase_indent(flow, False)

    try:
        with open(path, 'r') as f:
            data = yaml.safe_load(f)
        
        if not data:
            print("Config file is empty.")
            return

        with open(path, 'w') as f:
            yaml.dump(data, f, Dumper=MyDumper, sort_keys=False, indent=2)
        print("Mafl config reformatted successfully.")
    except Exception as e:
        print(f"Error formatting Mafl config: {e}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: format_mafl_config.py <path>")
        sys.exit(1)
    format_config(sys.argv[1])
