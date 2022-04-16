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

GIT_YML_PATH = '/opt/appdata/compose/'

def git_pull():
    """
    perform git pull
    """
    if len(os.listdir(GIT_YML_PATH)) == 0:
        os.rmdir(GIT_YML_PATH)
    else:
        logging.info('Folder is not empty | fallback to rmtree')
        shutil.rmtree(GIT_YML_PATH)
        logging.info('Folder is empty now')

    if git_repo:
        shutil.rmtree(GIT_YML_PATH)
        logging.info('git clone ' + git_repo)
        Repo.clone_from(git_repo, GIT_YML_PATH)
    else:
        logging.info('fallback to reclone of GIT_REPO')
        logging.info('git clone ' + git_repo)
        Repo.clone_from(git_repo, GIT_YML_PATH)

if git_repo:
    logging.info('git repo: ' + git_repo)
    if os.path.isdir(os.path.join(GIT_YML_PATH, '.git')):
        git_pull()
    else:
        logging.info('git clone ' +  git_repo)
        Repo.clone_from(git_repo, GIT_YML_PATH)
