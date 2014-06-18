echo hello 
PID=$BASHPID
STDOUT=$(readlink -f /proc/${PID}/fd/1)
if [[ $STDOUT != *pipe* ]]
then
exec $0 |& tee  $0.$(date +%Y%m%d%H%M).log
fi
