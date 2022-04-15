"""
git functionalities
"""

import os
import sys
import shutil
import logging
from git import Repo

git_repo = os.getenv('GIT_REPO')

logging.basicConfig(level=logging.DEBUG)

GIT_YML_PATH = '/opt/appdata/compose/apps/'

def git_pull():
    """
    perform git pull
    """
    if len(os.listdir(GIT_YML_PATH)) == 0:
        # removing the file using the os.remove() method
        os.rmdir(GIT_YML_PATH)
    else:
        # messaging saying folder not empty
        logging.info('Folder is not empty | fallback to rmtree')
        shutil.rmtree(GIT_YML_PATH)
        logging.info('Folder is empty now')

    if git_repo:
        logging.info('git clone ' + git_repo)
        Repo(GIT_YML_PATH).remote('origin').pull()
    else:
        logging.info('fallback to reclone of GIT_REPO)
        logging.info('git clone ' + git_repo)
        Repo.clone_from(git_repo, GIT_YML_PATH)

if git_repo:
    logging.info('git repo: ' + git_repo)
    if os.path.isdir(os.path.join(GIT_YML_PATH, '.git')):
        git_pull()
    else:
        logging.info('git clone ' +  git_repo)
        Repo.clone_from(git_repo, GIT_YML_PATH)
