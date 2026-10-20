#!/usr/bin/env python3
"""
Normalize only the gettext metadata charset placeholder in a temporary PO copy.

Usage: normalize-po-charset.py INPUT OUTPUT

Do not use OUTPUT as INPUT. The source is never modified.
"""

import sys
import polib

source, destination = sys.argv[1:]

po = polib.pofile(source)

content_type = po.metadata.get('Content-Type', '')

if 'charset=CHARSET' in content_type:
    po.metadata['Content-Type'] = content_type.replace('charset=CHARSET', 'charset=UTF-8')

po.save(destination)
