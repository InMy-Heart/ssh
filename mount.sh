
#!/bin/bash

echo "请输入iso镜像完整路径"
read  v_iso_path
echo "请输入镜像要挂载的目录"
read  v_mount_dir

v_curr_date=`date +%y%m%d%h%m`

mount -t iso9660 -o loop ${v_iso_path} ${v_mount_dir}


v_is_mount=`df -h |grep ${v_iso_path}`
if [ -z "${v_is_mount}" ]
        then
                echo "挂载未成功，请检查挂载过程"
        else
                echo "挂载iso镜像成功,开始配置yum……"
                echo "配置光盘挂载开机自启动"
                echo "备份/etc/fstab文件至/etc/fstab.${v_curr_date}.bak"
                cp /etc/fstab /etc/fstab.${v_curr_date}.bak
                echo "${v_iso_path}  ${v_mount_dir} iso9660  loop  0 0" >>/etc/fstab
                mount -a
                echo -ne "[base]\nname=base\nbaseurl=file://${v_mount_dir}\nenabled=1\ngpgcheck=0\n\n[server]\nname=server\nbaseurl=file://${v_mount_dir}/server\nenabled=1\ngpgcheck=0\n" >/etc/yum.repos.d/local.repo
                yum clear all
                yum update
fi

