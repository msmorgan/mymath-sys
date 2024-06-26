# Toolchain file is processed multiple times, however, it cannot access CMake cache on some runs.
# We store the search path in an environment variable so that we can always access it.
if (NOT "${PICO_TOOLCHAIN_PATH}" STREQUAL "")
    set(ENV{PICO_TOOLCHAIN_PATH} "${PICO_TOOLCHAIN_PATH}")
endif ()

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}")

# Find the compiler executable and store its path in a cache entry ${compiler_path}.
# If not found, issue a fatal message and stop processing. PICO_TOOLCHAIN_PATH can be provided from
# commandline as additional search path.
function(pico_find_compiler compiler_path compiler_exe)
    # Search user provided path first.
    find_program(
            ${compiler_path} ${compiler_exe}
            PATHS ENV PICO_TOOLCHAIN_PATH
            PATH_SUFFIXES bin
            NO_DEFAULT_PATH
    )

    # If not then search system paths.
    if ("${${compiler_path}}" STREQUAL "${compiler_path}-NOTFOUND")
        if (DEFINED ENV{PICO_TOOLCHAIN_PATH})
            message(WARNING "PICO_TOOLCHAIN_PATH specified ($ENV{PICO_TOOLCHAIN_PATH}), but ${compiler_exe} not found there")
        endif()
        find_program(${compiler_path} ${compiler_exe})
    endif ()
    if ("${${compiler_path}}" STREQUAL "${compiler_path}-NOTFOUND")
        set(PICO_TOOLCHAIN_PATH "" CACHE PATH "Path to search for compiler.")
        message(FATAL_ERROR "Compiler '${compiler_exe}' not found, you can specify search path with\
            \"PICO_TOOLCHAIN_PATH\".")
    endif ()
endfunction()

# include our Platform/PICO.cmake
set(CMAKE_SYSTEM_NAME PICO)
set(CMAKE_SYSTEM_PROCESSOR cortex-m0plus)

if (NOT PICO_GCC_TRIPLE)
    if (DEFINED ENV{PICO_GCC_TRIPLE})
        set(PICO_GCC_TRIPLE $ENV{PICO_GCC_TRIPLE})
        message("PICO_GCC_TRIPLE set from environment: $ENV{PICO_GCC_TRIPLE}")
    else()
        set(PICO_GCC_TRIPLE arm-none-eabi)
        #pico_message_debug("PICO_GCC_TRIPLE defaulted to arm-none-eabi")
    endif()
endif()

# Find GCC for ARM.
pico_find_compiler(PICO_COMPILER_CC ${PICO_GCC_TRIPLE}-gcc)
pico_find_compiler(PICO_COMPILER_CXX ${PICO_GCC_TRIPLE}-g++)
set(PICO_COMPILER_ASM "${PICO_COMPILER_CC}" CACHE INTERNAL "")
pico_find_compiler(PICO_OBJCOPY ${PICO_GCC_TRIPLE}-objcopy)
pico_find_compiler(PICO_OBJDUMP ${PICO_GCC_TRIPLE}-objdump)

# Specify the cross compiler.
set(CMAKE_C_COMPILER ${PICO_COMPILER_CC} CACHE FILEPATH "C compiler")
set(CMAKE_CXX_COMPILER ${PICO_COMPILER_CXX} CACHE FILEPATH "C++ compiler")
set(CMAKE_C_OUTPUT_EXTENSION .o)

# todo should we be including CMakeASMInformation anyway - i guess that is host side
set(CMAKE_ASM_COMPILER ${PICO_COMPILER_ASM} CACHE FILEPATH "ASM compiler")
set(CMAKE_ASM_COMPILE_OBJECT "<CMAKE_ASM_COMPILER> <DEFINES> <INCLUDES> <FLAGS> -o <OBJECT>   -c <SOURCE>")
set(CMAKE_INCLUDE_FLAG_ASM "-I")
set(CMAKE_OBJCOPY ${PICO_OBJCOPY} CACHE FILEPATH "")
set(CMAKE_OBJDUMP ${PICO_OBJDUMP} CACHE FILEPATH "")

# Add target system root to cmake find path.
get_filename_component(PICO_COMPILER_DIR "${PICO_COMPILER_CC}" DIRECTORY)
get_filename_component(CMAKE_FIND_ROOT_PATH "${PICO_COMPILER_DIR}" DIRECTORY)

# Look for includes and libraries only in the target system prefix.
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)

option(PICO_DEOPTIMIZED_DEBUG "Build debug builds with -O0" 0)

# on ARM -mcpu should not be mixed with -march
set(ARM_TOOLCHAIN_COMMON_FLAGS " -mcpu=cortex-m0plus -mthumb")

get_property(IS_IN_TRY_COMPILE GLOBAL PROPERTY IN_TRY_COMPILE)
foreach(LANG IN ITEMS C CXX ASM)
    set(CMAKE_${LANG}_FLAGS_INIT "${ARM_TOOLCHAIN_COMMON_FLAGS}")
    if (PICO_DEOPTIMIZED_DEBUG)
        set(CMAKE_${LANG}_FLAGS_DEBUG_INIT "-O0")
    else()
        set(CMAKE_${LANG}_FLAGS_DEBUG_INIT "-Og")
    endif()
    set(CMAKE_${LANG}_LINK_FLAGS "-Wl,--build-id=none")

    # try_compile is where the feature testing is done, and at that point,
    # pico_standard_link is not ready to be linked in to provide essential
    # functions like _exit. So pass -nostdlib so it doesn't link in an exit()
    # function at all.
    if(IS_IN_TRY_COMPILE)
        set(CMAKE_${LANG}_LINK_FLAGS "${CMAKE_${LANG}_LINK_FLAGS} -nostdlib")
    endif()
endforeach()


