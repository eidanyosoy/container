#!/usr/bin/env bash
/env/bin/gunicorn --chdir /app main:app -w 2 --threads 4 -b 0.0.0.0:5000

