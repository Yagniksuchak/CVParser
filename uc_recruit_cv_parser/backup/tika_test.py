#!/usr/bin/env python2.7
import tika
from tika import parser

if __name__ == "__main__":
    tika.initVM()
    parsed = parser.from_file('Kevin_DelRosso_Resume.pdf')
    metadata = parsed["metadata"]
    content = parsed["content"]

    print type(metadata), type(content)

    print "\nMetadata"
    for k, v in metadata.iteritems():
        print k, v

    content = content.replace(u'\u2212', "-")
    content = content.replace(u'\u2022', "*")
    content = content.replace(u'\u2019', "'")
    print [content]
    doc = ''
    for c in content:
        try:
            doc += str(c)
        except UnicodeEncodeError:
            print [c]
            print "unicode error" 

    print "\nContent"
    print doc.strip()
