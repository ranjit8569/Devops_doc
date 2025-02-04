#!/bin/bash
clear
echo -e " Production [ Error AND Session ] Counting.."
if [ ! -f Error_count ]
then
echo "File Error_count doesn't Exit"
exit
fi
total_line=`cat Error_count|wc -l`
i=1
while [ $i -le $total_line ]
do
line=`head -n $i Error_count|tail -1`
#line_session=`head -n $i Session_count|tail -1`
heading=`echo $line|cut -d"'" -f2|tr '[a-z]' '[A-Z]'`
cd /u01/app/wmprod/IBM/WebSphere/AppServer/profiles/AppSrv01
line_sesn=`echo $line|sed 's/wc -l/sort | uniq | wc -l/'`
err_cnt_app7=`echo $line|bash`
sess_cnt_app7=`echo $line_sesn|bash`
cd
cnt_val=0
ses_val=0

for server in 10.74.44.8 10.74.44.9 10.74.44.10
do
printf -v cmd_str '%q' "$line"
err_cnt=`ssh -q kusing@$server "
cd /u01/app/wmprod/IBM/WebSphere/AppServer/profiles/AppSrv01;
bash -c $cmd_str"`
if [ $? -eq 0 ]
then
res=`echo -e "$res $err_cnt\c"`
#echo "server val= $err_cnt_app7 $res"
let cnt_val=cnt_val+err_cnt #adding server values

if [ $err_cnt -ge 1 ]
then
line_sesn=`echo $line|sed 's/wc -l/sort | uniq | wc -l/'`
printf -v cmd_ses_str '%q' "$line_sesn"
session_count=`ssh -q kusing@$server "
cd /u01/app/wmprod/IBM/WebSphere/AppServer/profiles/AppSrv01;
bash -c $cmd_ses_str"`
let ses_val=ses_val+session_count
res1=`echo -e "$res1 $session_count\c"`
fi
else
echo "Unable to work server $server"
exit
fi
done

let cnt_val=cnt_val+err_cnt_app7
let ses_val=ses_val+sess_cnt_app7
#echo 
"$heading  $err_cnt_app7 $res | $sess_cnt_app7 $res1 ||total val: $cnt_val $ses_val |"  
#Values show all apserver
echo "$heading | $cnt_val | $ses_val"  
#Total count of Error and session
res=""
res1=""
#echo
let i=i+1
done
echo "Completed"
