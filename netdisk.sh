#!/usr/bin/bash

APP_ID="XXX"
ACCESS_TOKEN="XXX"

list_file()
{
result=$(curl -s "http://api.189.cn/ChinaTelecom/listFiles.action?app_id=$APP_ID&access_token=$ACCESS_TOKEN"&orderBy=filename)
file_count=$(echo $result | jq .fileList.count)
folder_count=$(echo $result | jq ".fileList.folder" | grep id | wc -l)
file_index=$(expr $file_count - $folder_count - 1)
folder_index=$(expr $folder_count - 1)

while [ $file_index -ge 0 ];
do
    file_name=$(echo $result | jq ".fileList.file[$file_index].name")
    file_size=$(echo $result | jq ".fileList.file[$file_index].size")
    file_name=$(echo ${file_name#\"}) && file_name=$(echo ${file_name%\"})
    echo -e $file_name"\t"$file_size >> .file_info
    file_index=$(expr $file_index - 1)
done
while [ $folder_index -ge 0 ];
do
    folder_name=$(echo $result | jq ".fileList.folder[$folder_index].name")
    folder_name=$(echo ${folder_name#\"}) && folder_name=$(echo ${folder_name%\"})
    echo -e $folder_name"\t"Folder >> .folder_info
    folder_index=$(expr $folder_index - 1)
done

printf "%-45s %23s \n" Name Size
printf "%-45s\t %20s \n" $(cat .folder_info)
printf "%-45s\t %20s \n" $(cat .file_info)
echo -e "\nFolder:$folder_count     File:$file_count"

rm .folder_info .file_info
}

if [[ $1 == "ls" ]]; then
    list_file
else
    echo "Usage:"
    echo "ls      List files and folders."
    exit
fi
