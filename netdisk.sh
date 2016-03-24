#!/usr/bin/bash

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
read -p "Please input the Access Token: " ACCESS_TOKEN
echo "ACCESS_TOKEN=\"$ACCESS_TOKEN\"" > ./.netdisk.conf
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
elif [[ $1 -le "1125899906842624" ]]; then
    if [[ $1 -eq "1125899906842624" ]]; then
        size="1PB"
        echo $size
    else
        size=$(awk "BEGIN{print $1/1024.0/1024.0/1024.0/1024.0 }" | cut -c 1-6)
        size=$(echo "$size"TB)
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

quota()
{
check
quota_result=$(curl -s "http://api.189.cn/ChinaTelecom/getUserInfo.action?app_id=$APP_ID&access_token=$ACCESS_TOKEN")
capacity_space=$(echo $quota_result | jq ".capacity")
available_space=$(echo $quota_result | jq ".available")
used_space=$(expr $capacity_space - $available_space)
capacity_space=$(size $capacity_space)
available_space=$(size $available_space)
used_space=$(size $used_space)
echo "Total:     $capacity_space"
echo "Used:      $used_space"
echo "Available: $available_space"
}

download()
{
check
dl_result=$(curl -s "http://api.189.cn/ChinaTelecom/listFiles.action?app_id=$APP_ID&access_token=$ACCESS_TOKEN")
dl_folder_count=$(echo $dl_result | jq ".fileList.folder" | grep id | wc -l)
dl_file_count=$(echo $dl_result | jq ".fileList.count")
dl_file_index=$(expr $dl_file_count - $dl_folder_count - 1)

while [[ $dl_file_index -ge 0 ]];
do
    dl_file_name=$(echo $dl_result | jq ".fileList.file[$dl_file_index].name")
    dl_file_name=$(echo ${dl_file_name#\"}) && dl_file_name=$(echo ${dl_file_name%\"})
    echo -e $dl_file_name"\t"$dl_file_index >> .dl_info
    dl_file_index=$(expr $dl_file_index - 1)
done

printf "%-45s %23s \n" Name ID
printf "%-45s\t %20s \n" $(cat .dl_info)
echo -e "\n"
read -p "Input the file id(only one): " dl_id
rm .dl_info

dl_file_id=$(echo $dl_result | jq ".fileList.file[$dl_id].id")
dl_file_name2=$(echo $dl_result | jq ".fileList.file[$dl_id].name")
dl_file_name2=$(echo ${dl_file_name2#\"}) && dl_file_name2=$(echo ${dl_file_name2%\"})
dl_file_size=$(echo $dl_result | jq ".fileList.file[$dl_id].size")
dl_file_size=$(size $dl_file_size)
dl_file_md5=$(echo $dl_result | jq ".fileList.file[$dl_id].md5")
dl_file_md5=$(echo ${dl_file_md5#\"}) && dl_file_md5=$(echo ${dl_file_md5%\"})
dl_file_url=$(curl -s "http://api.189.cn/ChinaTelecom/getFileDownloadUrl.action?app_id=$APP_ID&access_token=$ACCESS_TOKEN&fileId=$dl_file_id")
dl_file_url=$(echo $dl_file_url | jq ".fileDownloadUrl")
dl_file_url=$(echo ${dl_file_url#\"}) && dl_file_url=$(echo ${dl_file_url%\"})

echo -e "\n"
echo "File name: $dl_file_name2"
echo "File size: $dl_file_size"
echo "File MD5:  $dl_file_md5"
echo -e "\nDownload begin..."
echo -e "\n"

wget -O "$dl_file_name2" "$dl_file_url"

echo -e "\n"
echo "Done!"
}

dl-url()
{
check
dl_result=$(curl -s "http://api.189.cn/ChinaTelecom/listFiles.action?app_id=$APP_ID&access_token=$ACCESS_TOKEN")
dl_folder_count=$(echo $dl_result | jq ".fileList.folder" | grep id | wc -l)
dl_file_count=$(echo $dl_result | jq ".fileList.count")
dl_file_index=$(expr $dl_file_count - $dl_folder_count - 1)

while [[ $dl_file_index -ge 0 ]];
do
    dl_file_name=$(echo $dl_result | jq ".fileList.file[$dl_file_index].name")
    dl_file_name=$(echo ${dl_file_name#\"}) && dl_file_name=$(echo ${dl_file_name%\"})
    echo -e $dl_file_name"\t"$dl_file_index >> .dl_info
    dl_file_index=$(expr $dl_file_index - 1)
done

printf "%-45s %23s \n" Name ID
printf "%-45s\t %20s \n" $(cat .dl_info)
echo -e "\n"
read -p "Input the file id(only one): " dl_id
rm .dl_info

dl_file_id=$(echo $dl_result | jq ".fileList.file[$dl_id].id")
dl_file_name2=$(echo $dl_result | jq ".fileList.file[$dl_id].name")
dl_file_name2=$(echo ${dl_file_name2#\"}) && dl_file_name2=$(echo ${dl_file_name2%\"})
dl_file_size=$(echo $dl_result | jq ".fileList.file[$dl_id].size")
dl_file_size=$(size $dl_file_size)
dl_file_md5=$(echo $dl_result | jq ".fileList.file[$dl_id].md5")
dl_file_md5=$(echo ${dl_file_md5#\"}) && dl_file_md5=$(echo ${dl_file_md5%\"})
dl_file_url=$(curl -s "http://api.189.cn/ChinaTelecom/getFileDownloadUrl.action?app_id=$APP_ID&access_token=$ACCESS_TOKEN&fileId=$dl_file_id")
dl_file_url=$(echo $dl_file_url | jq ".fileDownloadUrl")
dl_file_url=$(echo ${dl_file_url#\"}) && dl_file_url=$(echo ${dl_file_url%\"})

echo -e "\n"
echo "File name: $dl_file_name2"
echo "File size: $dl_file_size"
echo "File MD5:  $dl_file_md5"
echo -e "\n"

echo -e "$dl_file_name2""\n""$dl_file_url""\n" >> url.txt
echo -e "\nDownload links saved to url.txt"

echo -e "\n"
echo "Done!"
}


if [[ $1 == "ls" ]]; then
    list_file
elif [[ $1 == "init" ]]; then
    init
elif [[ $1 == "quota" ]]; then
    quota
elif [[ $1 == "download" ]]; then
    download
elif [[ $1 == "dl-url" ]]; then
    dl-url
else
    echo "Usage:"
    echo "init         Initialization."
    echo "ls           List files and folders."
    echo "quota        Show the quotas."
    echo "download     Download guide."
    echo "dl-url       Get download links."
    exit
fi
