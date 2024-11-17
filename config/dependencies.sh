#!/bin/bash
# dependencies

# 依赖包
declare -A DEPENDENCIES
declare -A DEPENDENCIES_NGINX
declare -A DEPENDENCIES_REDIS
declare -A DEPENDENCIES_JAVA

# 通用依赖包
DEPENDENCIES["COMMON"]="gcc libpcre3-dev zlib1g-dev libssl-dev make"

# Nginx 依赖包
DEPENDENCIES_NGINX["centos"]="gcc c++ kernel-devel autogen autoconf"
DEPENDENCIES_NGINX["ubuntu"]="gcc c++ kernel-devel autogen autoconf"

# Redis 依赖包
DEPENDENCIES_REDIS["centos"]="gcc"
DEPENDENCIES_REDIS["ubuntu"]="gcc"

# Java 依赖包
DEPENDENCIES_JAVA["centos"]=""
DEPENDENCIES_JAVA["ubuntu"]=""

export DEPENDENCIES
export DEPENDENCIES_NGINX
export DEPENDENCIES_REDIS
export DEPENDENCIES_JAVA
