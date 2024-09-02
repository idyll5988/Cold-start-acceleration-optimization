#!/system/bin/sh
[ ! "$MODDIR" ] && MODDIR=${0%/*}
MODPATH="/data/adb/modules/AA+™"
[[ ! -e ${MODDIR}/ll/log ]] && mkdir -p ${MODDIR}/ll/log
source "${MODPATH}/scripts/GK.sh"
km1() {
	echo -e "$@" >>优先.log
	echo -e "$@"
}
km2() {
	echo -e "❗️ $@" >>优先.log
	echo -e "❗️ $@"
}
function log() {
    logfile="1000000"
    maxsize="1000000"
    if [ "$(stat -c %s "${MODDIR}/ll/log/优先.log")" -eq "$maxsize" ] || [ "$(stat -c %s "${MODDIR}/ll/log/优先.log")" -gt "$maxsize" ]; then
        rm -f "${MODDIR}/ll/log/优先.log"
    fi
}
# 获取所有已安装的包
function get_all_packages() {
    all_packages=($(pm list packages | awk -F: '{print $2}'))
}
# 定义启动Activity类名
main_activity_class=".MainActivity"
# 设置CPU最高优先级（可能需要root权限）
function set_cpu_priority() {
    for package in "${all_packages[@]}"; do
        pid=$(top -n 1 | grep "$package" | grep -v grep | awk '{print $2}')
        renice -n -20 -p $pid &>/dev/null || true
    done
}

# 优化内存管理
function optimize_memory() {
    echo "$date *优化内存管理*" >>优先.log
    sync; echo 3 > /proc/sys/vm/drop_caches
}

# 提前加载所有依赖库和资源并优化启动
function optimize_app_startup() {
    package=$1
    # 检查应用是否包含目标Activity
    if pm dump "$package" | grep -q "$main_activity_class"; then
        # 获取所有依赖库
        libs=$(ldd "$(which ${package}/${main_activity_class})" | grep -v '^=>' | awk '{print $3}')
        LD_PRELOAD="$libs"
        
        # 优化内存
        optimize_memory
        # 冷启动加速优化并设置CPU优先级
        am start -n "$package/$main_activity_class" --activity-clear-top --activity-no-history &
        pid=$!
        set_cpu_priority
        wait $pid

        if [[ $? -eq 0 ]]; then
            echo "$date *应用启动优化完成$package*" >>优先.log
        else
            echo "$date *应用启动优化失败$package*" >>优先.log
        fi
    else
        echo "$date *应用不包含目标Activity $package*" >>优先.log
    fi
}
cd ${MODDIR}/ll/log
log
# 清理后台进程和服务以释放内存
function clean_background_processes() {
am kill-all
}
# 主程序
clean_background_processes
get_all_packages
for package in "${all_packages[@]}"; do
    optimize_app_startup "$package" >>优先.log
done

