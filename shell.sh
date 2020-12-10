#!/bin/bash
# 引入 PATH
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# 安装 lolcat
Install_lolcat(){
    wget https://github.com/busyloop/lolcat/archive/master.zip
    unzip master.zip
    cd locat-master/bin
    gem install lolcat
    cd ../../
    rm -rf lolcat-master/ master.zip
}

# 安装软件函数，两个参数，$1 系统，$2 要安装的软件名字
Install_software(){
    for f in "$@"
    do 
        if test ${f} == $1
        then
            continue 
        fi 
        if ! type ${f} > /dev/null 2>&1; then
            echo -e "\033[41;30m ${f} Not Installed \033[0m"
            case $1 in
                debian|ubuntu|devuan|deepin)
                    if test ${f} == "lolcat"
                    then
                        apt autoremove libevent-core libevent-pthreads libopts25 sntp
                        Install_lolcat
                    else
                        apt-get install ${f}
                    fi
                    ;;
                centos|fedora|rhel)
                    yumdnf="yum"
                    if test "$(echo "$VERSION_ID >=22" | bc)" -ne 0; then
                        yumdnf="dnf"
                    fi
                    if test ${f} == "lolcat"
                    then
                        Install_lolcat
                    else
                        ${yumdnf} install ${f}
                    fi
                    ;;
                arch|manjaro)
                    pacman -S ${f}
                    if [ $? -ne 0 ]; then
                        echo -e "\033[33m Use pacman to install ${f} failed, try to install with yay \033[0m"
                        # yay_var 记录下原本安装的软件
                        yay_var=${f}
                        Install_software $1 yay
                        yay -S ${yay_var}
                    fi
                    ;;
                *)
                    echo -e "\033[43;37m The script is not applicable to the $1 system \033[0m"
                    exit 1
                ;;
            esac
        else
            echo -e "\033[45;37m ${f} is installed \033[0m"
        fi
    done
}

# 切换 root 用户
Check_root(){
    [[ $EUID != 0 ]] && echo -e "\033[31m The current account is not ROOT (or does not have ROOT permissions), and you cannot continue to operate, please use 'sudo su' to obtain temporary ROOT permissions (you will be prompted to enter the password of the current account after execution) \033[0m" && exit 1
}

# 检测网络链接畅通
Network_check()
{
    #超时时间
    local timeout=1
    #目标网站
    local target=www.baidu.com
    #获取响应状态码
    local ret_code=`curl -I -s --connect-timeout ${timeout} ${target} -w %{http_code} | tail -n1`
    if [ "x$ret_code" = "x200" ]; then
        #网络畅通
        echo -e "\033[36mNetwork: connected \033[0m"
        return 1
    else
        #网络不畅通
        return 0
    fi
    return 0
}

Network_link(){
    echo -e "\033[45;37mEnter the number [1~n] to select the networking method (recommended: WIFI) \033[0m"
    select net in "WIFI" "DHCP" "ADSL" "SKIP"
    do
        case ${net} in
            "WIFI")
                echo "Use WIFI connection"
                wifi-menu
                break
                ;;
            "DHCP")
                echo "Use DHCP connection"
                dhcpcd
                break
                ;;
            "ADSL")
                echo "Use ADSL connection"
                pppoe-setup
                systemctl start adsl
                break
                ;;
            "SKIP")
                echo -e "\033[41;30m Skip network connection failed \033[0m"
                exit 1
                ;;
            *)
                echo -e "\033[43;37m Input errors, please re-enter \033[0m"
        esac
    done

}

# 系统检查
System_check(){
    # 切换 root 用户
    Check_root

    # 检查系统类型
    echo -e "\033[45;37m Check the current operating system \033[0m"
    source /etc/os-release
    echo "System: $ID"
    
    # 检查 x86_64 架构
    bit=`uname -m`
    if test ${bit} == "x86_64" ;then
        bit="x86_64"
        echo "Architecture: ${bit}"
    else
        echo -e "\033[43;37m The script is not applicable to non-x86_64 architecture systems \033[0m"
        exit 1
    fi
    
    # 检查网络
    Network_check
    if [ $? -eq 0 ];then
        echo
        echo -e "\033[31m The network is not smooth, please check the network settings \033[0m"
        Network_link
        exit 1
    fi

    # 安装终端彩虹屁
    #Install_software $ID ruby lolcat

}

# 脚本标题图案
System_check 
echo -e "\033[5m"
echo -e "\033[33m 
    ___              __    __    _                     ____           __        ____
   /   |  __________/ /_  / /   (_)___  __  ___  __   /  _/___  _____/ /_____ _/ / /
  / /| | / ___/ ___/ __ \/ /   / / __ \/ / / / |/_/   / // __ \/ ___/ __/ __ \`/ / / 
 / ___ |/ /  / /__/ / / / /___/ / / / / /_/ />  <   _/ // / / (__  ) /_/ /_/ / / /  
/_/  |_/_/   \___/_/ /_/_____/_/_/ /_/\__,_/_/|_|  /___/_/ /_/____/\__/\__,_/_/_/   
                                                                                    
\033[0m"
# TITLE 生成: http://patorjk.com/software/taag/#p=display&f=Slant&t=teaper

# 定义全局变量
sh_ver="2020.12.01"
system_os="$ID"
# 镜像大小（MB）
iso_size=682
# 引导方式
grub=UEFI

# 脚本描述
echo -e "========================\033[43;37m Quick Start \033[0m=========================="
echo "*     OS: Arch Linux ${bit}"
echo "*     Description: ArchLinux system installation script"
echo -e "*     Version:${sh_ver}"
echo "*     Author: teaper"
echo "*     Home：https://teaper.dev"
echo "==============================================================="

# 函数
Test_function(){
    echo -e "Hello ${USER}"
}

# 制作启动盘
Dd_iso(){
    echo -e "\033[45;37m About to make a boot disk \033[0m"
    # 判断是否插入 U 盘
    usb_status=`ls /proc/scsi/ | grep usb-storage`
    if [[ ${usb_status} != "" ]]; then
        echo "USB flash drive has been inserted" && echo
        # 判断 U 盘大小
        lsblk
        read -e -p "Enter the device you want to write to (default: sdb):" dd_disk
        if [[ ${dd_disk} == "" ]]; then
            dd_disk="sdb"
        fi
        
        # 判断路径是否正确
        ls /dev/${dd_disk} >/dev/null 2>&1
        if test $? != 0 ;then
            echo -e "\033[41;37m Path does not exist \033[0m"
            exit 1
        fi
        echo "USB flash drive path: /dev/${dd_disk}" && echo

        # 判断 U 盘是 TB 还是 GB
        disk_unit=`fdisk -l /dev/${dd_disk} | awk -F " " 'NR==1{print $4}' | cut -d "," -f 1`
        disk_GB=`fdisk -l /dev/${dd_disk} | awk -F " " 'NR==1{print $3}' | cut -d "." -f 1`
        if test $disk_unit == "GiB"; then
            dd_disk_size=`awk 'BEGIN{print '${disk_GB}'*1024*1024*1024}'`
        elif test $disk_unit == "TiB"; then
            dd_disk_size=`awk 'BEGIN{print '${disk_GB}'*1024*1024*1024*1024}'`
        else
            echo -e "\033[41;30m The available space of the USB flash drive is insufficient, please replace the USB flash drive and try again \033[0m"
            exit 1
        fi
        
        echo -e "\033[45;37m USB flash drive size: `fdisk -l /dev/${dd_disk} | awk -F " " 'NR==1{print $3}'` `fdisk -l /dev/${dd_disk} | awk -F " " 'NR==1{print $4}' | cut -d "," -f 1` \033[0m"
        if test $[dd_disk_size] -gt $[iso_d_size]; then
            echo -e "\033[43;37m Start writing \033[0m"
            dd if=archlinux-${sh_ver}-${bit}.iso of=/dev/${dd_disk} bs=1440k oflag=sync
            echo -e "\033[45;37m Write complete\033[0m"
        else
            echo -e "\033[41;30m The USB flash drive has insufficient free space, please replace the USB flash drive and try again \033[0m"
        fi
    else
        echo -e "\033[31m Please insert the USB flash drive and try again \033[0m"
    fi
}

#下载 iso 镜像
Download_iso(){
    echo -e "\033[45;37m Download iso image \033[0m"
    if [[ -e ./archlinux-${sh_ver}-${bit}.iso ]] ;then 
        iso_d_size=`ls -l archlinux-${sh_ver}-${bit}.iso | awk '{print $5}'`
        echo "archlinux-${sh_ver}-${bit}.iso Image file already exists（size: $(( ${iso_d_size}/1024/1024 )) MiB）" && echo
        
        #判断文件大小是否正确
        iso_f_size=$(( ${iso_size}*1024*1024 ))
        if test $[iso_d_size] -le $[iso_f_size]; then
            echo -e "\033[41;30m iso The file is corrupted and is being downloaded again \033[0m"
            wget -N "http://mirrors.163.com/archlinux/iso/${sh_ver}/archlinux-${sh_ver}-${bit}.iso" archlinux-${sh_ver}-${bit}.iso
            Dd_iso
        else
            Dd_iso
        fi
    else 
        read -e -p "There is no archlinux-${sh_ver}-${bit}.iso image in the current folder, whether to download it now [y/n]:" iso_yn
        [[ -z ${iso_yn} ]] && iso_yn="y"
        if [[ ${iso_yn} == [Yy] ]]; then
            echo "\nDownloading iso image file"
            wget -N "http://mirrors.163.com/archlinux/iso/${sh_ver}/archlinux-${sh_ver}-${bit}.iso" archlinux-${sh_ver}-${bit}.iso
            Dd_iso
        else
            echo -e "\033[43;37m Startup disk creation cancelled \033[0m"
        fi
    fi
}

# 检查分区情况是否合理
Cfdisk_check(){
    echo -e "\033[45;37m Check partition results \033[0m"
    # part_count:类型为 part 的分区个数<int>
    part_lines=`lsblk -nlo TYPE |  sed -n  '/part/='`
    part_count=`lsblk -nlo TYPE | sed -n '/part/=' | awk 'END{print NR}'`
    NO=0

    # 判断分区个数
    if ((${part_count} != 4)) ; then
        echo -e "\033[31m Unreasonable number of partitions, go back and repartition \033[0m" 
        Cfdiak_ALL
        # 不进行自动挂载
    else
        # 检查分区情况和策略匹配程度
        echo -e "Number of available disks:${part_count}"
        for part_line in ${part_lines}
        do
            name=`lsblk -nlo NAME | sed -n ${part_line}p`
            size=`lsblk -nlo SIZE | sed -n ${part_line}p`
            # 存储单位G/T<byte>
            size_bit=${size: -1}
            # 去掉存储单位后的数字<double>
            size_num=`echo ${size} | cut -d "T" -f 1 | cut -d "G" -f 1 | cut -d "M" -f  1`
            # 转化成 GB 之后的存储大小<double>
            size_GB=${size_num}

            # 单位转化成 GB
            if test ${size_bit} == "T" ; then
                size_GB=`awk 'BEGIN{printf "%.1f\n",'${size_num}'*1024}'`
            elif test ${size_bit} == "M" ; then
                size_GB=`awk 'BEGIN{printf "%.1f\n",'${size_num}'/1024}'`
            fi

            # 获取 partmap 中记录的分盘数据
            partmap_name=`cut partmap  -d " " -f 1 | grep ${name}`
            partmap_size=`cat partmap | grep ${name} | cut -d " " -f 2`
            if [[ "${size_GB}G" == ${partmap_size} ]] ; then
                echo -e "${name} \033[35m[OK]\033[0m"
            else
                echo -e "${name} \033[31m[NO]\033[0m SIZE: ${size_GB}G \033[31m!=\033[0m ${partmap_size}"
                NO=`awk 'BEGIN{print '${NO}'+1}'`
            fi
        done
        echo
        if ((${NO} != 0)) ; then
            echo -e "\033[33mWarning: You have ${NO} partitions unreasonable (recommendation: repartition)\033[0m"
            select num in "Repartition" "Next" "Exit"
            do
                case ${num} in
                    "Repartition")
                        Cfdiak_ALL
                        break
                        ;;
                    "Next")
                        # 格式化分区
                        Mkfs_disks
                        break
                        ;;
                    "Exit")
                        echo -e "\033[41;30m Exit script \033[0m"
                        rm diskmap >/dev/null 2>&1 && echo
                        exit 1
                        break
                        ;;
                    *)
                        echo -e "\033[43;37m Input errors, please re-enter \033[0m"
                esac
            done
        fi
        rm diskmap >/dev/null 2>&1 && echo
    fi
}

# 开始分区
Cfdiak_ALL(){
    echo -e "\033[45;37m Read partition strategy \033[0m"
    cat diskmap && echo
    echo -e "\033[43;37m Partition order \033[0m"
    echo "Single disk:   EFI > SWAP > HOME > /"
    echo "Dual disk:   EFI > SWAP > / > HOME"
    read -e -p "During the partitioning process, the partitioning strategy cannot be viewed. It is recommended to take a picture and record before continuing [y/n]:" cfdisk_yn
    [[ -z ${cfdisk_yn} ]] && cfdisk_yn="y"
    if [[ ${cfdisk_yn} == [Yy] ]]; then
        echo
        echo -e "\033[45;37m Start partition \033[0m"
        for disk_line in ${disk_lines}
        do
            var=`lsblk -nlo NAME | sed -n ${disk_line}p`
            cfdisk /dev/${var}
        done
        # 分区完成查看一眼睛
        echo "分区成功" && echo
        echo -e "\033[43;37m View partition results \033[0m"
        lsblk && echo
        echo
    else
        echo -e "\033[43;37mUnpartitioned \033[0m"
        echo
    fi

    # 检查分区是否合理
    Cfdisk_check
}

# 手动格式化
Cm_disks(){
    echo -e "\033[45;37m Manual format \033[0m"
    lsblk -nlo NAME,SIZE,TYPE,MOUNTPOINT | grep part
    echo -e "\033[33m \nTip: Some commands are as follows:\033[0m"
    echo -e "\033[36m [format] mkfs.ext4 /dev/Root partition \033[0m"
    echo -e "\033[36m [format] mkfs.vfat /dev/EFI partition \033[0m"
    echo -e "\033[36m [format] mkswap -f /dev/Swap partition \033[0m"
    echo -e "\033[32m [open] swapon /dev/Swap partition \033[0m"
    echo -e "\033[36m [format] mkfs.ext4 /dev/HOME partition \033[0m"
    echo -e "\033[33m \n(Tip: Type q and press Enter to end the command input)  \033[0m"
    while true
    do
        read -e -p " >> " cmd
        [[ -z ${cmd} ]] && cmd=""
        if [[ ${cmd} != [Qq] ]] ; then
            echo "#!/bin/bash" > cmd.sh
            echo "${cmd}" >> cmd.sh
            echo "[$(date "+%Y-%m-%d %H:%M:%S")] Running '${cmd}'" >> cmd.log
            /bin/bash cmd.sh 
            rm cmd.sh
        else
            break
        fi
    done
    echo -e "\n\033[33m[Operation log]\033[0m"
    cat cmd.log >/dev/null 2>&1 
    rm cmd.log >/dev/null 2>&1 
    echo 
}

# 手动挂载
Cm_mount(){
    echo -e "\033[45;37m Manually mount \033[0m"
    lsblk -nlo NAME,SIZE,TYPE,MOUNTPOINT | grep part
    echo -e "\033[33m \nTip: Some commands are as follows: \033[0m"
    echo -e "\033[36m [Mount] mount /dev/Root partition /mnt \033[0m"
    echo -e "\033[36m [create] mkdir /mnt/home \033[0m"
    echo -e "\033[36m [create] mkdir -p /mnt/boot/EFI \033[0m"
    echo -e "\033[32m [Mount] mount /dev/HOME partition /mnt/home \033[0m"
    echo -e "\033[36m [Mount] mount /dev/EFI partition /mnt/boot/EFI \033[0m"
    echo -e "\033[33m \n(Tip: Type q and press Enter to end the command input)  \033[0m"
    
    while true
    do
        read -e -p " >> " cmd
        [[ -z ${cmd} ]] && cmd=""
        if [[ ${cmd} != [Qq] ]] ; then
            echo "#!/bin/bash" > cmd.sh
            echo "${cmd}" >> cmd.sh
            echo "[$(date "+%Y-%m-%d %H:%M:%S")] Running '${cmd}'" >> cmd.log
            /bin/bash cmd.sh 
            rm cmd.sh
        else
            break
        fi
    done
    echo -e "\n\033[33m[Operation log]\033[0m"
    cat cmd.log >/dev/null 2>&1 
    rm cmd.log >/dev/null 2>&1 
    echo 
}

# 挂载分区
Mount_parts(){
    echo
    echo -e "\033[45;37m Mount partition \033[0m"
    if [ ! -d "/mnt/home" ]; then
        mkdir /mnt/home
   fi
   if [ ! -d "/mnt/boot/EFI" ]; then
        mkdir -p /mnt/boot/EFI
   fi
    
    if ((${NO} != 0)) ; then
        #手动挂载分区
        echo -e "\033[33mWarning: You have ${NO} partitions unreasonable (recommendation: mount manually)\033[0m"
        select num in "Repartition" "Manuallymount" "Next" "Exit"
        do
            case ${num} in
                "Repartition")
                    Cfdiak_ALL
                    break
                    ;;
                "Manuallymount")
                    rm diskmap >/dev/null 2>&1 && echo
                    rm partmap >/dev/null 2>&1 && echo
                    # 手动挂载
                    Cm_mount
                    #Cm_disks
                    break
                    ;;
                "Next")
                    rm diskmap >/dev/null 2>&1 && echo
                    rm partmap >/dev/null 2>&1 && echo
                    break
                    ;;
                "Exit")
                    echo -e "\033[41;30m Exit script \033[0m"
                    rm diskmap >/dev/null 2>&1 && echo
                    rm partmap >/dev/null 2>&1 && echo
                    exit 1
                break
                    ;;
                *)
                    echo -e "\033[43;37m Input errors, please re-enter \033[0m"
            esac
        done

    else
        # 自动挂载分区
        #part_lines:所有类型为 part 的分区行号<list>
        part_lines=`lsblk -nlo TYPE | sed -n '/part/='`

        for part_line in ${part_lines}
        do
            name=`lsblk -nlo NAME | sed -n ${part_line}p`
            name_top=`echo ${name} | cut -b 1-3`
            name_end=${name: -1}

            # 格式化
            if ((${disk_count} == 1)) ; then
                # 单个硬盘
                if ((${name_end} == 1)) ; then
                    echo -e "\033[33m[OK]\033[0m mount /dev/${name} /mnt/boot/EFI"
                    mount /dev/${name} /mnt/boot/EFI
                elif ((${name_end} == 2)) ; then
                    echo "No need to mount swap partition"
                elif ((${name_end} == 3)) ; then
                    # 第三 home 分区
                    echo -e "\033[33m[OK]\033[0m mount /dev/${name} /mnt/home"
                    mount /dev/${name} /mnt/home
                elif ((${name_end} == 4)) ; then
                    echo -e "\033[33m[OK]\033[0m mount /dev/${name} /mnt"
                    mount /dev/${name} /mnt
                else
                    echo "Unmounted partition:/dev/${name}"
                fi

            elif ((${disk_count} == 2)) ; then
                # 两个硬盘
                if [[ ${name_top} == "nvm" ]] ; then
                    if ((${name_end} == 1)) ; then
                        echo -e "\033[33m[OK]\033[0m mount /dev/${name} /mnt/boot/EFI"
                        mount /dev/${name} /mnt/boot/EFI
                    elif ((${name_end} == 2)) ; then
                        echo "No need to mount swap partition"
                    elif ((${name_end} == 3)) ; then
                        # 第三个根分区
                        echo -e "\033[33m[OK]\033[0m mount /dev/${name} /mnt"
                        mount /dev/${name} /mnt
                    else
                        echo "Unmounted partition: /dev/${name}"
                    fi
                else
                    echo -e "\033[33m[OK]\033[0m mount /dev/${name} /mnt/home"
                    mount /dev/${name} /mnt/home
                fi
            else
                echo -e "\033[43;37m Unable to mount unknown partition \033[0m"
            fi
        done
    fi
    rm diskmap >/dev/null 2>&1 && echo
    rm partmap >/dev/null 2>&1 && echo
}

# 格式化分区
Mkfs_disks(){
    echo
    echo -e "\033[45;37m Format partition \033[0m"
    if ((${NO} != 0)) ; then
        #手动格式化分区
        echo -e "\033[33mWarning: You have ${NO} partitions unreasonable (recommendation: format manually) \033[0m"
        select num in "Repartition" "Manualformat" "Next" "Exit"
        do
            case ${num} in
                "Repartition")
                    Cfdiak_ALL
                    break
                    ;;
                "Manualformat")
                    rm diskmap >/dev/null 2>&1 && echo
                    # 手动格式化
                    Cm_disks
                    # 挂载分区
                    Mount_parts
                    break
                    ;;
                "Next")
                    rm diskmap >/dev/null 2>&1 && echo
                    # 挂载分区
                    Mount_parts
                    break
                    ;;
                "Exit")
                    echo -e "\033[41;30m Exit script \033[0m"
                    rm diskmap >/dev/null 2>&1 && echo
                    exit 1
                break
                    ;;
                *)
                    echo -e "\033[43;37m Input errors, please re-enter \033[0m"
            esac
        done

    else
        # 自动格式化分区
        #part_lines:所有类型为 part 的分区行号<list>
        part_lines=`lsblk -nlo TYPE | sed -n '/part/='`

        for part_line in ${part_lines}
        do
            name=`lsblk -nlo NAME | sed -n ${part_line}p`
            name_top=`echo ${name} | cut -b 1-3`
            name_end=${name: -1}

            # 格式化
            if ((${disk_count} == 1)) ; then
                # 单个硬盘
                if ((${name_end} == 1)) ; then
                    echo -e "\033[33m[OK]\033[0m mkfs.vfat /dev/${name}"
                    mkfs.vfat /dev/${name}
                elif ((${name_end} == 2)) ; then
                    echo -e "\033[33m[OK]\033[0m mkswap -f /dev/${name}"
                    mkswap -f /dev/${name}
                    echo -e "\033[33m[OK]\033[0m swapon /dev/${name}"
                    swapon /dev/${name}
                elif ((${name_end} == 3)) ; then
                    # 第三 home 分区
                    echo -e "\033[33m[OK]\033[0m mkfs.ext4 /dev/${name}"
                    mkfs.ext4 /dev/${name}
                elif ((${name_end} == 4)) ; then
                    echo -e "\033[33m[OK]\033[0m mkfs.ext4 /dev/${name}"
                    mkfs.ext4 /dev/${name}
                else
                    echo "Unformatted partition: /dev/${name}"
                fi

            elif ((${disk_count} == 2)) ; then
                # 两个硬盘
                if [[ ${name_top} == "nvm" ]] ; then
                    if ((${name_end} == 1)) ; then
                        echo -e "\033[33m[OK]\033[0m mkfs.vfat /dev/${name}"
                        mkfs.vfat /dev/${name}
                    elif ((${name_end} == 2)) ; then
                        echo -e "\033[33m[OK]\033[0m mkswap -f /dev/${name}"
                        mkswap -f /dev/${name}
                        echo -e "\033[33m[OK]\033[0m swapon /dev/${name}"
                        #swapon /dev/${name}
                    elif ((${name_end} == 3)) ; then
                        # 第三个根分区
                        echo -e "\033[33m[OK]\033[0m mkfs.ext4 /dev/${name}"
                        mkfs.ext4 /dev/${name}
                    else
                        echo "Unformatted partition: /dev/${name}"
                    fi
                else
                    echo -e "\033[33m[OK]\033[0m mkfs.ext4 /dev/${name}"
                    mkfs.ext4 /dev/${name}
                fi
            else
                echo -e "\033[43;37m Unable to format unknown partition \033[0m"
            fi
        done
        # 挂载分区
        Mount_parts
    fi
}


# 分区策略
Disk_map(){
    echo -e "\033[45;37m Current disk partition situation \033[0m"
    lsblk -l
    # disk_names:所有磁盘和分区的名字<list>
    disk_names=`lsblk -nlo NAME`
    # disk_lines:类型为 disk 的磁盘行号<list>
    disk_lines=`lsblk -nlo TYPE |  sed -n  '/disk/='`
    # disk_count:类型为 disk 的磁盘个数<int>
    disk_count=`lsblk -nlo TYPE | sed -n '/disk/=' | awk 'END{print NR}'`
    
    echo -e "\nn Number of available disks: ${disk_count}"
    for disk_line in ${disk_lines}
    do
        name=`lsblk -nlo NAME | sed -n ${disk_line}p`
        size=`lsblk -nlo SIZE | sed -n ${disk_line}p`

        echo "PATH: /dev/${name}  SIZE: ${size}"
    done
    echo
    
    #生成策略
    echo -e "\033[45;37m Generate partitioning strategy \033[0m"
    echo "NAME    SIZE    TYPE    MOUNTPOINT" > diskmap
    echo "NAME SIZE" > partmap
    for disk_line in ${disk_lines}
    do
        # 获取磁盘名称和大小
        name=`lsblk -nlo NAME | sed -n ${disk_line}p`
        size=`lsblk -nlo SIZE | sed -n ${disk_line}p`
        # 存储单位G/T<byte>
        size_bit=${size: -1}
        # 去掉存储单位后的数字<double>
        size_num=`echo ${size} | cut -d "T" -f 1 | cut -d "G" -f 1 | cut -d "M" -f  1`
        # 转化成 GB 之后的存储大小<double>
        size_GB=${size_num}

        # 单位转化成 GB
        if test ${size_bit} == "T" ; then
            size_GB=`awk 'BEGIN{printf "%.1f\n",'${size_num}'*1024}'`
        elif test ${size_bit} == "M" ; then
            size_GB=`awk 'BEGIN{printf "%.1f\n",'${size_num}'/1024}'`
        fi
        
        # 内存
        memory=`awk '($1 == "MemTotal:"){print $2/1048576}' /proc/meminfo | cut -d "." -f 1`
        #两种分盘策略
        echo "${name}    ${size}  disk" >> diskmap
        if ((${disk_count} == 1)) ; then
            # 单个磁盘
            if [[ ${name} == "nvme0n1" ]] ; then
                # EFI 分区大小
                efi_size=`echo ${size_GB} | cut -d "." -f 2`
                efi_size=`awk 'BEGIN{printf "%.1f\n",'${efi_size}'/10}'`
                sed -i "/${name}/a├─${name}p1    ${efi_size}G   EFI Filesystem     /boot/EFI" diskmap
                echo "${name}p1 ${efi_size}G" >> partmap
                # swap 分区大小
                if ((${memory} <= 4)); then
                    swap_size=4
                elif (( ${memory} > 4 && ${memory} <= 16)); then
                    swap_size=$((${memory}+2))
                elif ((${memory} > 16 && ${memory} <=64)); then
                    swap_size=16
                else
                    swap_size=32
                fi
                sed -i "/${name}p1/a├─${name}p2    ${swap_size}G   Linux Swap     [SWAP]" diskmap
                echo "${name}p2 ${swap_size}G" >> partmap
                # 其他 / 根分区大小
                outher_size=`awk 'BEGIN{print '${size_GB}'-'${efi_size}'-'${swap_size}'}'`
                # home 分区大小
                home_size=`awk 'BEGIN{printf "%.1f\n",'${outher_size}'/2}'`
                sed -i "/${name}p2/a├─${name}p3    ${home_size}G    Linux Filesystem    /home" diskmap
                echo "${name}p3 ${home_size}G" >> partmap
                sed -i "/${name}p3/a└─${name}p4    ${home_size}G   Linux Filesystem     /" diskmap
                echo "${name}p4 ${home_size}G" >> partmap
                # 跳出循环
                break
            else
                # EFI 分区大小
                efi_size=`echo ${size_GB} | cut -d "." -f 2`
                efi_size=`awk 'BEGIN{printf "%.1f\n",'${efi_size}'/10}'`
                sed -i "/${name}/a├─${name}1    ${efi_size}G   EFI Filesystem     /boot/EFI" diskmap
                echo "${name}1 ${efi_size}G" >> partmap
                # swap 分区大小
                if ((${memory} <= 4)); then
                    swap_size=4
                elif (( ${memory} > 4 && ${memory} <= 16)); then
                    swap_size=$((${memory}+2))
                elif ((${memory} > 16 && ${memory} <=64)); then
                    swap_size=16
                else
                    swap_size=32
                fi
                sed -i "/${name}1/a├─${name}2    ${swap_size}G   Linux Swap     [SWAP]" diskmap
                echo "${name}2 ${swap_size}G" >> partmap
                # 其他 / 根分区大小
                outher_size=`awk 'BEGIN{print '${size_GB}'-'${efi_size}'-'${swap_size}'}'`
                # home 分区大小
                home_size=`awk 'BEGIN{printf "%.1f\n",'${outher_size}'/2}'`
                sed -i "/${name}2/a├─${name}3    ${home_size}G    Linux Filesystem    /home" diskmap
                echo "${name}3 ${home_size}G" >> partmap
                sed -i "/${name}3/a└─${name}4    ${home_size}G   Linux Filesystem     /" diskmap
                echo "${name}4 ${home_size}G" >> partmap
                # 跳出循环
                break
            fi

        elif ((${disk_count} == 2)) ; then
            # 多个磁盘
            if [[ ${name} == "nvme0n1" ]] ; then
                # EFI 分区大小
                efi_size=`echo ${size_GB} | cut -d "." -f 2`
                efi_size=`awk 'BEGIN{printf "%.1f\n",'${efi_size}'/10}'`
                sed -i "/${name}/a├─${name}p1    ${efi_size}G   EFI Filesystem     /boot/EFI" diskmap
                echo "${name}p1 ${efi_size}G" >> partmap
                # swap 分区大小
                if ((${memory} <= 4)); then
                    swap_size=4
                elif (( ${memory} > 4 && ${memory} <= 16)); then
                    swap_size=$((${memory}+2))
                elif ((${memory} > 16 && ${memory} <=64)); then
                    swap_size=16
                else
                    swap_size=32
                fi
                sed -i "/${name}p1/a├─${name}p2    ${swap_size}G   Linux Swap     [SWAP]" diskmap
                echo "${name}p2 ${swap_size}G" >> partmap
                # 其他 / 根分区大小
                outher_size=`awk 'BEGIN{print '${size_GB}'-'${efi_size}'-'${swap_size}'}'`
                sed -i "/${name}p2/a└─${name}p3    ${outher_size}G   Linux Filesystem     /" diskmap
                echo "${name}p3 ${outher_size}G" >> partmap
            else
                sed -i "/${name}/a└─${name}1    ${size}    Linux Filesystem    /home" diskmap
                echo "${name}1 ${size_GB}G" >> partmap
            fi

        else
            echo -e "\033[43;37m There is no suitable partition strategy for you at the moment \033[0m"
        fi
    done
}

# 安装 linux 内核和 base
Install_linux(){
    echo -e "\033[45;37m Install Linux-Kernel and base \033[0m"
    pacstrap /mnt base
    pacstrap /mnt base-devel
    pacstrap /mnt linux linux-firmware

    echo 
    echo -e "\033[45;37m The partition mount status is written to fstab \033[0m"
    genfstab -U /mnt >> /mnt/etc/fstab
    cat /mnt/etc/fstab
    echo
}

# 切换到安装的系统
Arch_chroot(){
    echo -e "\033[45;37m Switching system arch-chroot \033[0m"
    arch-chroot /mnt
    echo
    echo -e "\033[45;37m Set time arch-chroot \033[0m"
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    hwclock --systohc --utc
    echo
    echo -e "\033[45;37m Modify the encoding format arch-chroot \033[0m"
    Install_software ${system_os} vim
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
    echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen
    locale-gen
    echo LANG=en_US.UTF-8 > /etc/locale.conf
    cat /etc/locale.conf && echo
    echo -e "\033[45;37m Create hostname \033[0m"
    read -e -p "Please enter your hostname（default: Arch）:" host_name
    [[ -z ${host_name} ]] && host_name="Arch"
    if [[ ${host_name} != "Arch" ]]; then
        echo ${host_name} > /etc/hostname
    else
        echo Arch > /etc/hostname
    fi
    echo "127.0.0.1   localhost.localdomain   localhost"
    echo "::1         localhost.localdomain   localhost"
    echo "127.0.1.1   ${host_name}.localdomain    ${host_name}"
    echo
    echo -e "\033[45;37m Install network connection components (recommended: WIFI) \033[0m"
    select net in "WIFI" "DHCP" "ADSL"
    do
        case ${net} in
            "WIFI")
                Install_software ${system_os} iw wpa_supplicant dialog netctl dhcpcd
                systemctl disable dhcpcd.service
                break
                ;;
            "DHCP")
                Install_software ${system_os} dhcpcd
                systemctl enable dhcpcd
                systemctl start dhcpcd
                break
                ;;
            "ADSL")
                Install_software ${system_os} rp-pppoe pppoe-setup
                systemctl start adsl
                break
                ;;
            *)
                Install_software ${system_os} iw wpa_supplicant dialog netctl dhcpcd
                systemctl disable dhcpcd.service
        esac
    done
    echo 
    echo -e "\033[45;37m Set ROOT user password \033[0m"
    passwd
    echo 
    echo -e "\033[45;37m Install Intel-ucode \033[0m"
    cat /proc/cpuinfo | grep "model name" >/dev/null 2>&1
    if (($? == 0)) ; then
        Install_software ${system_os} intel-ucode
    fi
    echo
    echo -e "\033[45;37m Install bootloader \033[0m"
    # 删除多余引导菜单
    efiboot_menu=`efibootmgr | grep "ArchLinux" | cut -c 5-8`
    if [[ -z ${efiboot_menu} ]] ; then
        efibootmgr -b ${efiboot_menu} -B
    fi

    if [[ ${grub} == "UEFI" ]] ;then
        Install_software ${system_os} grub efibootmgr
        grub-install --target=x86_64-efi --efi-directory=/boot/EFI --bootloader-id=ArchLinux
        grub-mkconfig -o /boot/grub/grub.cfg
    else
        Install_software ${system_os} grub
        read -e -p "Please enter the name of your primary disk, note that it is a disk, not a partition, used to install GRUB boot (default: sda):" grub_install_path
        [[ -z ${grub_install_path} ]] && grub_install_path="sda"
        if [[ ${grub_install_path} != "sda" ]]; then
            grub-install --target=i386-pc /dev/${grub_install_path}
        else
            grub-install --target=i386-pc /dev/sda
        fi
        grub-mkconfig -o /boot/grub/grub.cfg
    fi
    # 检查引导是否正常
    cat /boot/grub/grub.cfg | grep "Arch Linux" >/dev/null 2>&1
    if (( $? == 0)) ; then
        echo "${grub} The boot setup is successful"
    else
        echo "${grub} Boot setup failed"
    fi
    #多系统自动添加到引导目录
    Install_software ${system_os} os-prober
    echo
    echo -e "\033[45;37m Reboot the system \033[0m"
    exit
    umount -R /mnt
    reboot

}

# 安装系统
Install_system(){
    echo -e "\033[45;37m install the system \033[0m"
    
    # 确认引导方式
    ls /sys/firmware/efi/efivars >/dev/null 2>&1
    if test $? != 0 ;then
        echo -e "\033[41;37m Does not support UEFI boot, has been switched to BIOS mode \033[0m"
        ${grub}="BIOS"
    fi

    # 更新系统时间
    timedatectl set-ntp true

    # 修改源文件
    cat /etc/pacman.d/mirrorlist | sed -n '1,2'p | grep mirrors.ustc.edu.cn >/dev/null 2>&1
    if (($? != 0)); then
        sed -i '1iServer = http://mirrors.aliyun.com/archlinux/$repo/os/$arch' /etc/pacman.d/mirrorlist
        sed -i '1iServer = https://mirrors.ustc.edu.cn/archlinux/$repo/os/$arch' /etc/pacman.d/mirrorlist
    fi

    # 分区策略
    Disk_map

    # 开始分区
    Cfdiak_ALL
    read -e -p "The system is about to be officially installed. The whole process is connected to the Internet and cannot be suspended. Are you ready? [yn][yn]:" iyn
    [[ -z ${iyn} ]] && iyn="n"
    if [[ ${iyn} == [Nn] ]] ; then
        echo -e "\033[41;30m Exit script \033[0m"
        exit 1
    fi
    # 安装 Linux 系统 base | base-devel
    Install_linux

    # 切换到安装的系统
    Arch_chroot

}

# 操作菜单
echo -e "\033[45;37mPlease enter the menu number [1~n] \033[0m"
select num in "Make a boot disk" "Install the system" "Install NVIDIA driver"  "Exit"
do
        case ${num} in
                "Make a boot disk")
                    Download_iso
                    break
                    ;;
                "Install the system")
                    Install_system
                    #Mkfs_disks
                    break
                    ;;
                "Install NVIDIA driver")
                        echo "Install QQ Music"
                        Install_software ${system_os} qqmusic-bin jstock
                        break
                        ;;
                "Exit")
                        break
                        ;;
                *)
                        echo -e "\033[43;37m Input errors, please re-enter \033[0m"
        esac
done
