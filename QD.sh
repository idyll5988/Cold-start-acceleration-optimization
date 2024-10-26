#!/system/bin/sh
[! "$MODDIR" ] && MODDIR=${0%/*}
MODPATH="/data/adb/modules/AA+™"
[[! -e ${MODDIR}/ll/log ]] && mkdir -p ${MODDIR}/ll/log
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
logfile=1000000
maxsize=1000000
if  [[ "$(stat -t $MODDIR/ll/log/优先.log | awk '{print $2}')" -eq "$maxsize" ]] || [[ "$(stat -t $MODDIR/ll/log/优先.log | awk '{print $2}')" -gt "$maxsize" ]]; then
rm -f "$MODDIR/ll/log/优先.log"
fi
}
function get_all_packages() {
    all_packages=($(pm list packages -f | awk -F: '/com.android|android/ {next} {print $2}'))
}

main_activity_class=".MainActivity"
function set_cpu_priority() {
    for package in "${all_packages[@]}"; do
        pid=$(top -n 1 | grep "$package" | grep -v grep | awk '{print $2}')
        renice -n -20 -p $pid || km2 "设置进程优先级失败：$package"
    done
}
function optimize_memory() {
    date=$(date +"%Y-%m-%d %H:%M:%S")
    echo "$date *优化内存管理*" >>优先.log
    sync; su -c echo 3 > /proc/sys/vm/drop_caches
}
function optimize_app_startup() {
    package=$1
    if pm dump "$package" | grep -q "$main_activity_class"; then
        libs=$(ldd "$(which ${package}/${main_activity_class})" | grep -v '^=>' | awk '{print $3}')
        LD_PRELOAD="$libs"
        optimize_memory
        am start -n "$package/$main_activity_class" --activity-clear-top --activity-no-history &
        pid=$!
        set_cpu_priority
        wait $pid

        if [[ $? -eq 0 ]]; then
            date=$(date +"%Y-%m-%d %H:%M:%S")
            echo "$date *应用启动优化完成$package*" >>优先.log
        else
            date=$(date +"%Y-%m-%d %H:%M:%S")
            echo "$date *应用启动优化失败$package*" >>优先.log
        fi
    else
        date=$(date +"%Y-%m-%d %H:%M:%S")
        echo "$date *应用不包含 Activity $package*" >>优先.log
    fi
}
function clean_background_processes() {
    am kill-all || km2 "清理后台进程失败"
}
cd ${MODDIR}/ll/log
log
clean_background_processes
get_all_packages
for package in "${all_packages[@]}"; do
    optimize_app_startup "$package" >>优先.log
done

