#1 Задание
sleep 200 &
sleep 2000 &
jobs
#2 Задание
kill %2
jobs
#3 Задание
mc &
ps -fl -p $(prgrep mc)
#4 Задание
w
#5 Задание
ps
ps -f
#6 Задание
ps -ef --forest
#7 Задание
pstree
#8 Задание
kill -TERM <PPID>
kill -INT <PPID>
kill -QUIT <PPID>
kill -HUP <PPID>
#9 Задание
sleep 1000 &
kill -TERM %1
kill -INT %1
kill -QUIT %1
kill -HUP %1
#10 Задание
trap "touch myfile" TERM
# проверяем
kill -TERM $$
ls myfile
#11 Задание
nice -n -1 bash
#12 Задание
sudo timme nice -n 19 updatedb
sudo timme nice -n 5 updatedb
