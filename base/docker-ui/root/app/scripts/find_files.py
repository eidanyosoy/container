"""
find docker-compose.yml / readme and environment file
"""

import fnmatch
import os
import sys
import glob
import shutil
import logging

envpath = '/opt/appdata/compose'

def find_yml_files(path):
    """
    find docker-compose.yml files in path
    """
    matches = {}
    for root, _, filenames in os.walk(path, followlinks=True):
        for _ in set().union(fnmatch.filter(filenames, 'docker-compose.yml'), fnmatch.filter(filenames, 'docker-compose.yaml')):
            key = root.split('/')[-1]
            matches[key] = os.path.join(os.getcwd(), root)
    return matches

def get_readme_file(path):
    """
    find case insensitive readme.md in path and return the contents
    """
    readme = None
    for file in os.listdir(path):
        if file.lower() == "readme.md" and os.path.isfile(os.path.join(path, file)):
            file = open(os.path.join(path, file))
            readme = file.read()
            file.close()
            break
    return readme

def get_logo_file(path):
    """
    find case insensitive logo.png in path and return the contents
    """
    logo = None
    for file in os.listdir(path):
        if file.lower() == "logo.png" and os.path.isfile(os.path.join(path, file)):
            file = open(os.path.join(path, file))
            logo = file.read()
            file.close()
            break
    return logo

def get_env_file(envpath)
    """
    find case insensitive env in path and return the contents
    ""
    for dirpath, dirs, files in os.walk(envpath):  
      for filename in files: 
         env = os.path.join(dirpath,filename) 
            if file.endswith('.env'): 
              print(env)
              env = file.read()
              file.close()
              break
    return env
