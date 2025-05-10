FROM ubuntu:12.04

# 1) 把所有官方源都换成 old-releases
RUN sed -i -e 's|archive.ubuntu.com|old-releases.ubuntu.com|g' \
           -e 's|security.ubuntu.com|old-releases.ubuntu.com|g' /etc/apt/sources.list \
# 2) 忽略过期签名
 && echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99ignore-release-date \
# 3) 更新索引（再次关闭签名时间检查），安装工具链（不再钉死版本号）
 && apt-get update -o Acquire::Check-Valid-Until=false \
 && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
      gcc make flex bison \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /work
