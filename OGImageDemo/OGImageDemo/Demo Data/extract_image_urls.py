#!/usr/bin/env python

def main():
    import re
    r = []
    print "["
    with open("search_bond.html") as f:
        for line in f:
            for i in re.finditer(r'imgurl=(.*?)[&%]', line):
                print "    \"{0}\",".format(i.groups(1)[0])
    print "]"

if __name__ == "__main__":
    main()
