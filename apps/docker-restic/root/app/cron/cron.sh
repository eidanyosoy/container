#!/usr/bin/with-contenv bash
# shellcheck shell=bash
#####################################
# All rights reserved.              #
# started from Zero                 #
# Docker owned dockserver           #
# Docker Maintainer dockserver      #
#####################################
# THIS DOCKER IS UNDER LICENSE      #
# NO CUSTOMIZING IS ALLOWED         #
# NO REBRANDING IS ALLOWED          #
# NO everyDE MIRRORING IS ALLOWED   #
#####################################

function log() {
   GRAY="\033[0;37m"
   BLUE="\033[0;34m"
   NC="\033[0m"
   $(which echo) -e "${GRAY}[$($(which date) +'%Y/%m/%d %H:%M:%S')]${BLUE} [Restic]${NC} ${1}"
}

   crontab -l -u $1 | while read line; do
   if [[ ! $line =~ ^\# && ! -z $line ]]; then
      COMBINED_DATE=0
      TIME_str=""
      DATE_str=""

      #### CHECK TIME STRING ####
      COMMAND=`echo "$line" | sed 's/^\(.\{1,8\} \)\{5\}//'`
      MINUTES=`echo "$line" |cut -d" " -f1`
      HOUR=`echo "$line" |cut -d" " -f2`
      MONTH_DAY=`echo "$line" |cut -d" " -f3`
      MONTH=`echo "$line" |cut -d" " -f4`
      WEEK_DAY=`echo "$line" |cut -d" " -f5`

      #### CHECK COMMAND STRING ####
      ECHO_str="Next backup job will be running"

      #### HOURS ####
      if [[ ! $HOUR =~ ^\*$ && ! -z $HOUR ]]; then
         if [[ $HOUR =~ ^\*\/[0-9]{1,2}$ && ! -z $HOUR ]]; then
            NUM_HOUR=`echo "$HOUR" |cut -d"/" -f2`;
            HR_str="every $NUM_HOUR hours";
         elif [[ $HOUR =~ ^[0-9]{1,2}$ && ! -z $HOUR ]]; then
            HR_str="at $HOUR"
            COMBINED_DATE=1
         elif [[ $HOUR =~ ^[0-9]{1,2}-[0-9]{1,2}$ && ! -z $HOUR ]]; then
            FR_NUM_HOUR=`echo "$HOUR" |cut -d"-" -f1`;
            TO_NUM_HOUR=`echo "$HOUR" |cut -d"-" -f2`;
            HR_str="between time $FR_NUM_HOUR and $TO_NUM_HOUR"
         elif [[ $HOUR =~ ^[0-9]{1,2}-[0-9]{1,2}\/[0-9]{1,2}$ && ! -z $HOUR ]]; then
            NUM_HOUR=`echo "$HOUR" |cut -d"/" -f2`;
            HOUR_RANGE=`echo "$HOUR" |cut -d"/" -f1`;
            FR_NUM_HOUR=`echo "$HOUR_RANGE" |cut -d"-" -f1`;
            TO_NUM_HOUR=`echo "$HOUR_RANGE" |cut -d"-" -f2`;
            HR_str="between time $FR_NUM_HOUR and $TO_NUM_HOUR, every $NUM_HOUR hours"
         fi
      else
         HR_str=""
      fi

      #### MINUTES ####
      if [[ ! $MINUTES =~ ^\*$ && ! -z $MINUTES ]]; then
         if [[ $MINUTES =~ ^\*\/[0-9]{1,2}$ && ! -z $MINUTES ]]; then
            NUM_MINUTES=`echo "$MINUTES" |cut -d"/" -f2`
            MIN_str="every $NUM_MINUTES minutes"
         elif [[ $COMBINED_DATE == 1 ]]; then
            if [[ ! $MINUTES =~ ^\*$ && ! -z $MINUTES ]]; then
               MIN_str="$MINUTES"
            else
               MIN_str="w $MINUTES minute"
            fi
         elif [[ $MINUTES =~ ^[0-9]{1,2}-[0-9]{1,2}$ && ! -z $MINUTES ]]; then
            FR_NUM_MINUTES=`echo "$MINUTES" |cut -d"-" -f1`;
            TO_NUM_MINUTES=`echo "$MINUTES" |cut -d"-" -f2`;
            MIN_str="between $FR_NUM_MINUTES and $TO_NUM_MINUTES minute"
         elif [[ $MINUTES =~ ^[0-9]{1,2}-[0-9]{1,2}\/[0-9]{1,2}$ && ! -z $MINUTES ]]; then
            NUM_MINUTES=`echo "$MINUTES" |cut -d"/" -f2`;
            MINUTES_RANGE=`echo "$MINUTES" |cut -d"/" -f1`;
            FR_NUM_MINUTES=`echo "$MINUTES_RANGE" |cut -d"-" -f1`;
            TO_NUM_MINUTES=`echo "$MINUTES_RANGE" |cut -d"-" -f2`;
            MIN_str="between $FR_NUM_MINUTES and $TO_NUM_MINUTES minute, every $NUM_MINUTES minutes"
         fi
      else
         MIN_str=""
      fi

      #### DAY OF MONTH ####
      if [[ ! $MONTH_DAY =~ ^\*$ && ! -z $MONTH_DAY ]]; then
         if [[ $MONTH_DAY =~ ^\*\/[0-9]{1,2}$ && ! -z $MONTH_DAY ]]; then
            NUM_MONTH_DAY=`echo "$MONTH_DAY" |cut -d"/" -f2`
            MON_D_str="every $NUM_MONTH_DAY days"
         elif [[ $MONTH_DAY =~ ^[0-9]{1,2}$ && ! -z $MONTH_DAY ]]; then
            MON_D_str="$MONTH_DAY daysa month"
         elif [[ $MONTH_DAY =~ ^[0-9]{1,2}-[0-9]{1,2}$ && ! -z $MONTH_DAY ]]; then
            FR_NUM_MONTH_DAY=`echo "$MONTH_DAY" |cut -d"-" -f1`;
            TO_NUM_MONTH_DAY=`echo "$MONTH_DAY" |cut -d"-" -f2`;
            MON_D_str="between $FR_NUM_MONTH_DAY and $TO_NUM_MONTH_DAY daysem month"
         elif [[ $MONTH_DAY =~ ^[0-9]{1,2}-[0-9]{1,2}\/[0-9]{1,2}$ && ! -z $MONTH_DAY ]]; then
            NUM_MONTH_DAY=`echo "$MONTH_DAY" |cut -d"/" -f2`;
            MONTH_DAY_RANGE=`echo "$MONTH_DAY" |cut -d"/" -f1`;
            FR_NUM_MONTH_DAY=`echo "$MONTH_DAY_RANGE" |cut -d"-" -f1`;
            TO_NUM_MONTH_DAY=`echo "$MONTH_DAY_RANGE" |cut -d"-" -f2`;
            MON_D_str="between $FR_NUM_MONTH_DAY and $TO_NUM_MONTH_DAY daysem month, every $NUM_MONTH_DAY days"
         fi
      else
         MON_D_str=""
      fi

      #### MONTH ####
      if [[ ! $MONTH =~ ^\*$ && ! -z $MONTH ]]; then
         if [[ $MONTH =~ ^\*\/[0-9]{1,2}$ && ! -z $MONTH ]]; then
            NUM_MONTH=`echo "$MONTH" |cut -d"/" -f2`
            MON_str="every $NUM_MONTH miesiecy"
         elif [[ $MONTH =~ ^[0-9]{1,2}$ && ! -z $MONTH ]]; then
            MON_str="w $MONTH miesiacu"
         elif [[ $MONTH =~ ^[0-9]{1,2}-[0-9]{1,2}$ && ! -z $MONTH ]]; then
            FR_NUM_MONTH=`echo "$MONTH" |cut -d"-" -f1`;
            TO_NUM_MONTH=`echo "$MONTH" |cut -d"-" -f2`;
            MON_str="between $FR_NUM_MONTH and $TO_NUM_MONTH month"
         elif [[ $MONTH =~ ^[0-9]{1,2}-[0-9]{1,2}\/[0-9]{1,2}$ && ! -z $MONTH ]]; then
            NUM_MONTH=`echo "$MONTH" |cut -d"/" -f2`;
            MONTH_RANGE=`echo "$MONTH" |cut -d"/" -f1`;
            FR_NUM_MONTH=`echo "$MONTH_RANGE" |cut -d"-" -f1`;
            TO_NUM_MONTH=`echo "$MONTH_RANGE" |cut -d"-" -f2`;
            MON_str="between $FR_NUM_MONTH and $TO_NUM_MONTH month, every $NUM_MONTH miesiecy"
         fi
      else
         MON_str=""
      fi

      #### WEEK DAY ####
      if [[ ! $WEEK_DAY =~ ^\*$ && ! -z $WEEK_DAY ]]; then
         if [[ $WEEK_DAY =~ ^\*\/[0-9]{1,2}$ && ! -z $WEEK_DAY ]]; then
            NUM_WEEK=`echo "$WEEK_DAY" |cut -d"/" -f2`
            WEK_str="every $NUM_WEEK days weekdays"
         elif [[ $WEEK_DAY =~ ^[0-9]{1,2}$ && ! -z $WEEK_DAY ]]; then
            WEK_str="$WEEK_DAY daysa weekdays"
         elif [[ $WEEK_DAY =~ ^[0-9]{1,2}-[0-9]{1,2}$ && ! -z $WEEK_DAY ]]; then
            FR_NUM_WEEK_DAY=`echo "$WEEK_DAY" |cut -d"-" -f1`;
            TO_NUM_WEEK_DAY=`echo "$WEEK_DAY" |cut -d"-" -f2`;
            WEK_str="between $FR_NUM_WEEK_DAY and $TO_NUM_WEEK_DAY daysem weekdays"
         elif [[ $WEEK_DAY =~ ^[0-9]{1,2}-[0-9]{1,2}\/[0-9]{1,2}$ && ! -z $WEEK_DAY ]]; then
            NUM_WEEK_DAY=`echo "$WEEK_DAY" |cut -d"/" -f2`;
            WEEK_DAY_RANGE=`echo "$WEEK_DAY" |cut -d"/" -f1`;
            FR_NUM_WEEK_DAY=`echo "$WEEK_DAY_RANGE" |cut -d"-" -f1`;
            TO_NUM_WEEK_DAY=`echo "$WEEK_DAY_RANGE" |cut -d"-" -f2`;
            MON_str="between $FR_NUM_WEEK_DAY and $TO_NUM_WEEK_DAY daysem weekdays, every $NUM_WEEK_DAY days"
         fi
      else
         WEK_str=""
      fi

      #### GENERATE OUTPUT ####
      if [[ $COMBINED_DATE == 1 ]]; then
         if [[ $MIN_str =~ ^[0-9]{1}$ ]]; then
            MIN_str="0$MIN_str"
         fi
         TIME_str="$HR_str:$MIN_str"
      else
         if [[ ! -z $HR_str ]]; then
            TIME_str="$HR_str"
         else
            TIME_str="$TIME_str$MIN_str"
         fi
      fi

      if [[ ! -z $WEK_str || ! -z $MON_str || ! -z $MON_D_str ]]; then
         if [[ ! -z $WEK_str ]]; then
            DATE_str="$WEK_str"
         fi
         if [[ ! -z $MON_str ]]; then
            DATE_str="$DATE_str$MON_str"
         fi
         if [[ ! -z $MON_D_str ]]; then
            DATE_str="$DATE_str$MON_D_str"
         fi
      else
         DATE_str="daily"
      fi

      if [[ $DATE_str =~ ^daily$ ]]; then
         log "-> $ECHO_str $TIME_str <-"
      else
         log "-> $ECHO_str $TIME_str $DATE_str <-"
      fi

   fi
done
exit 0
