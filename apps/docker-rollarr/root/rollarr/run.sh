## run as user
exec su -l abc -c "cron -f /crontab & \
exec su -l abc -c "python /rollarr/Preroll.py"
