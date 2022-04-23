#!/usr/bin/python3 

"""
   # $(which python3) templater.py >> 
   # >> /PFAD/VALUES-[NAME].yaml      | >> VALUES IN YAML FORMAT
   # >> /PFAD/JINJA2TEMP-[NAME].j2    | >> VALUES IN JINJA2 FORMAT
   # >> /PFAD/[NAME]*.yaml oder *.yml | >> FINAL FILE
 
   ## NOTES

   # 1 ) YAML wird live geschrieben
   # 2 ) j2   wird live geschrieben
   # 3 ) order muss existieren

   # command + yaml + j2 + output ergibt am ende final file
   # alle 3 müssen in einer Zeile stehen !
"""

from jinja2 import Template
import yaml, sys

# load yaml vars file
yaml = yaml.safe_load(open(str(sys.argv[1]), 'r'))

# load jinja2 template file
template = Template(open(str(sys.argv[2])).read())

# if no out file was provided
if len(sys.argv) == 3:
    # print to stdout
    print(template.render(yaml))

# if outfile was provided
elif len(sys.argv) == 4:
    # write result to output file
    with open(str(sys.argv[3]), 'w') as f:
        print(template.render(yaml), file=f)
