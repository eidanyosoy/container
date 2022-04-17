"""
find docker-compose.yml / readme and environment file
"""

import fnmatch
import os
import sys
import glob
import shutil
import logging

def find_yml_files(path):
    matches = {}
    for root, _, filenames in os.walk(path, followlinks=True):
        for _ in set().union(fnmatch.filter(filenames, 'docker-compose.yml'), fnmatch.filter(filenames, 'docker-compose.yaml')):
            key = root.split('/')[-1]
            matches[key] = os.path.join(os.getcwd(), root)
    return matches

def get_readme_file(path):
    readme = None
    for file in os.listdir(path):
        if file.lower() == "readme.md" and os.path.isfile(os.path.join(path, file)):
            file = open(os.path.join(path, file))
            readme = file.read()
            file.close()
            break
    return readme

def get_logo_file(path):
    logo = None
    for file in os.listdir(path):
        if file.lower() == "*.png" and os.path.isfile(os.path.join(path, file)):
            file = open(os.path.join(path, file))
            logo = file.read()
            file.close()
            break
    return logo

def get_env_file(path):
    for dirpath, dirs, files in os.walk(path):  
        for filename in fnmatch.filter(files, '.env'):
            env = os.path.join(dirpath, filename)
            print(os.path.join(dirpath, filename))
            print(env)
    return env
