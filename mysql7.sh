#!/bin/bash
PATH () {
a=`find / -name lnmp`
for i in $a
do
        ls $i|grep Bj &>/dev/null
        [ $? = 0 ]&&b=$i&&lnmpdir=$i
done
shdir=`ls $b`
for i in $shdir
do
        [ $i = 'nginx' ]&&ngdir=$b/$i
        [ $i = 'php' ]&&phpdir=$b/$i
        [ $i = 'mysql' ]&&mysqldir=$b/$i
        [ $i = 'discuz' ]&&discuzdir=$b/$i
        [ $i = 'run' ]&&rundir=$b/$i
done
}

PATH

install_mysql () {
# 安装依赖
yum install -y libaio 
yum install -y numactl

# 关闭selinux
a=`cat /etc/selinux/config |grep ^SELINUX|head -1|awk -F"=" '{print $2}'`
b='enforcing'
[ $a = $b ] && sed -i 's/SELINUX=.*/SELINUX=disabled/' /etc/selinux/config


# 配置脚本变量环境
wget_dir='/GET_DIR'
tar_dir='/usr/local/'
pid_dir='/var/run/mysql/'
sock_dir='/data/mysql/'
log_dir='/var/log/mysql/'
user='mysql'
mysql_dir='/usr/local/mysql/'
[ ! -e $wget_dir ] && mkdir $wget_dir

# 下载mysql源码
wget -P $wget_dir https://cdn.mysql.com//Downloads/MySQL-5.7/mysql-5.7.21-linux-glibc2.12-x86_64.tar.gz
 
[ $? != 0 ] && exit 4

# 解压mysql源码
filename=`ls $wget_dir|grep ^mysql`
tar xzvf ${wget_dir}/$filename -C $tar_dir
src_dir="${tar_dir}`ls $tar_dir|grep ^mysql`"
mv ${src_dir} ${mysql_dir}
rm -rf $wget_dir
export PATH=$PATH:${mysql_dir}bin

# 配置mysql启动文件
cat << EOF >/etc/my.cnf
[mysqld]
user=${user}
datadir=${sock_dir}
basedir=${mysql_dir}
socket=${sock_dir}mysql.sock
log-error=${log_dir}mysql_err.log

[mysqld_safe]
pid-file=${pid_dir}mysqld.pid

[client]
socket=${sock_dir}mysql.sock
EOF

# 创建用户与目录
useradd -s /sbin/nologin mysql
mkdir -p ${pid_dir} ${sock_dir} ${log_dir} 
chown -R mysql.mysql ${pid_dir} ${sock_dir} ${log_dir}

# 初始化数据库
${mysql_dir}/bin/mysql_install_db --insecure --user=${user} --basedir=${mysql_dir} --datadir=${sock_dir}
if [ $? = 0 ];then
    cp -a ${mysql_dir}support-files/mysql.server /etc/init.d/mysqld
    service mysqld start 
    /usr/local/mysql/bin/mysqladmin -u root password "123456"
    if [ $? = 0 ];then
        iptables -I INPUT -p tcp --dport 3306 -j ACCEPT
        sh $mysqldir/MY.sh
        echo "mysql安装并启动成功！"
    else
        echo "mysql启动失败！"
        exit 3
    fi
else
    echo "mysql初始化失败，请检查依赖是否正常！"
    exit 4
fi
}
install_mysql

