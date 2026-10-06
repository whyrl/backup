#!/bin/sh
set -e
REMOTE_LOGIN=$1
DATE=`date "+%F"`
LOCAL_HOST=`hostname -s`

#
# Whyrl's backup script.
# 2012-05-04
#
# USAGE: ./backup [REMOTE_LOGIN]
#   e.g. ./backup whyrl@192.168.0.100
#
#
# This script uses rsync and ssh to create a rotating backup on a remote host.
# The most recent backup is symlinked to "current".
#
#
# ~/.excludes should contain a list of rsync filter rules, e.g.
#       - *.core
#       - *.swp
#       - /.local/share/Trash/
#       - /.mozilla/**/Cache/
#       - /.ssh/
#       - /.thumbnails/
#
# See rsync(1) FILTER RULES section of the man page
#


#
# XXX Edit these as appropriate
#
#EMAIL='whyrlgryph@gmail.com'
REMOTE_PATH="~/${LOCAL_HOST}"

#RSYNC_FLAGS='-rlptgoihx --delete'
RSYNC_FLAGS='-aihx --no-D --delete'

LOG=/tmp/backup.${USER}.${DATE}.log
ERRLOG=/tmp/backup.${USER}.${DATE}.err


backup ()
{
   SRC=$1
   DEST="${REMOTE_PATH}"
   EXCLUDES="${SRC}/.excludes"

   echo "--------------------------------------------------"
   echo "Backup ${SRC} to ${DEST}"
   echo "--------------------------------------------------"

   # Display list of exclusions to stdout
   echo ${EXCLUDES}
   echo "Excluded files:"
   cat ${EXCLUDES}
   echo "End of exclusions"
   echo "--------------------------------------------------"


   # Set up remote server
   echo "${DEST}"
   ssh ${REMOTE_LOGIN} "mkdir -p ${DEST}"
   echo "***"

   # Do not delete current backup
   touch ${SRC}

   # Run backup
   cat ${EXCLUDES} | \
   rsync ${RSYNC_FLAGS} --stats --progress --link-dest=${DEST}/current --exclude-from=- \
         ${SRC} ${REMOTE_LOGIN}:${DEST}/${DATE} || exit 1

   ssh ${REMOTE_LOGIN} "cd ${DEST} && rm -f current && ln -s ${DATE} current"

   #echo "Deleting old backups"
   #ssh ${REMOTE_LOGIN} "find ${DEST} -depth 1 -type d -Btime +8d -print"
   #ssh ${REMOTE_LOGIN} "find ${DEST} -depth 1 -type d -Btime +8d -print0 | xargs -0 rm -rf"

   echo "--------------------------------------------------"
   echo "Backup ${SRC} done"
   echo "--------------------------------------------------"
}

echo "*** Backup music to ${HOME}/backup/iTunes ***"
rsync ${RSYNC_FLAGS} ${HOME}/music/iTunes/ ${HOME}/backup/iTunes/.

#echo "*** Backup music to ${REMOTE_LOGIN}:/home/share/music"
#rsync ${RSYNC_FLAGS} ${HOME}/music/        ${REMOTE_LOGIN}:/home/share/music

echo "*** Start backup of ${HOME}"
backup ${HOME}/ 2> ${ERRLOG} | tee ${LOG}

#cat ${LOG}    | mail -s "[Backup] `hostname -s`: `date '+%F %a %R'` (manual)" ${EMAIL}
#cat ${ERRLOG} | mail -E -s "[Backup] ERRORS for `hostname -s`" ${EMAIL}

cat ${ERRLOG}
rm ${LOG} ${ERRLOG}

