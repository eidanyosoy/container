"""
docker compose project management
"""
import sys
from os import rename, makedirs, path
from time import time

YML_PATH = '/opt/appdata/compose/'

def manage(directory, yml, is_update):
    """
    create or update docker compose project
    """
    file_path = YML_PATH + directory + "/docker-compose.yml" 
    if is_update:
        rename(file_path, file_path + "." + str(int(round(time()))))
    else:
        makedirs(YML_PATH)
        makedirs(directory)
    out_file = open(file_path, "w")
    out_file.write(yml)
    out_file.close()
    return file_path
