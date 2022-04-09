#!/bin/bash
exec cron -f &
exec python /rollarr/Preroll.py
