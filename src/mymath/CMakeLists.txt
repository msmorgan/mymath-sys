cmake_minimum_required(VERSION 3.10)
project(mymath)

add_library(mymath "src/mymath.c")
target_include_directories(mymath PUBLIC "include")