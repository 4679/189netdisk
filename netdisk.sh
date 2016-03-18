#!/data/data/com.termux/files/usr/bin/bash

APP_ID="125914970000250528"

check(){
if [ -f "./.netdisk.conf" ]; then
    source ./.netdisk.conf
else
    echo "Please run with this option: init"
    exit
fi
}

init()
{
echo -e "Get your Access Token here: http://t.cn/RGdxd3z\n"
echo "Please input the Access Token:"
read -r ACCESS_TOKEN1
echo "ACCESS_TOKEN=\"$ACCESS_TOKEN1\"" > ./.netdisk.conf
echo -e "\n Done!"
}

size()
{
if [[ $1 -le "1024" ]]; then
    if [[ $1 -eq "1024" ]]; then
        size="1KB"
        echo $size
    else
        size=$(echo "$1"B)
        echo $size
    fi
elif [[ $1 -le "1048576" ]]; then
    if [[ $1 -eq "1048576" ]]; then
        size="1MB"
        echo $size
    else
        size=$(awk "BEGIN{print $1/1024.0 }" | cut -c 1-6)
        size=$(echo "$size"KB)
        echo $size
    fi
elif [[ $1 -le "1073741824" ]]; then
    if [[ $1 -eq "1073741824" ]]; then
        size="1GB"
        echo $size
    else
        size=$(awk "BEGIN{print $1/1024.0/1024.0 }" | cut -c 1-6)
        size=$(echo "$size"MB)
        echo $size
    fi
elif [[ $1 -le "1099511627776" ]]; then
    if [[ $1 -eq "1099511627776" ]]; then
        size="1TB"
        echo $size
    else
        size=$(awk "BEGIN{print $1/1024.0/1024.0/1024.0 }" | cut -c 1-6)
        size=$(echo "$size"GB)
        echo $size
    fi
else
    size="Joke"
    echo $size
fi
}

list_file()
{
check
result=$(curl -s "http://api.189.cn/ChinaTelecom/listFiles.action?app_id=$APP_ID&access_token=$ACCESS_TOKEN"&orderBy=filename)
file_count=$(echo $result | jq .fileList.count)
folder_count=$(echo $result | jq ".fileList.folder" | grep id | wc -l)
file_index=$(expr $file_count - $folder_count - 1)
folder_index=$(expr $folder_count - 1)

while [[ $file_index -ge 0 ]];
do
    file_name=$(echo $result | jq ".fileList.file[$file_index].name")
    bare_size=$(echo $result | jq ".fileList.file[$file_index].size")
    file_size=$(size $bare_size)
    file_name=$(echo ${file_name#\"}) && file_name=$(echo ${file_name%\"})
    echo -e $file_name"\t"$file_size >> .file_info
    file_index=$(expr $file_index - 1)
done
while [[ $folder_index -ge 0 ]];
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
elif [[ $1 == "init" ]]; then
    init
elif [[ $1 == "test" ]]; then
    echo $(size $2)
else
    echo "Usage:"
    echo "init    Initialization."
    echo "ls      List files and folders."
    exit
fi
