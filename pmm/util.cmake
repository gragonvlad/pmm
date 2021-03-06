cmake_minimum_required(VERSION 3.10)

function(_pmm_read_script_argv var)
    set(got_p FALSE)
    set(got_script FALSE)
    set(ret)
    foreach(i RANGE "${CMAKE_ARGC}")
        set(arg "${CMAKE_ARGV${i}}")
        if(got_p)
            if(got_script)
                list(APPEND ret "${arg}")
            else()
                set(got_script TRUE)
            endif()
        elseif(arg STREQUAL "-P")
            set(got_p TRUE)
        endif()
    endforeach()
    set("${var}" "${ret}" PARENT_SCOPE)
endfunction()

# Argument parser helper. This may look like magic, but it is pretty simple:
# - Call this at the top of a function
# - It takes three "list" arguments: `.`, `-` and `+`.
# - The `.` arguments specify the "option/boolean" values to parse out.
# - The `-` arguments specify the one-value arguments to parse out.
# - The `+` argumenst specify mult-value arguments to parse out.
# - Specify `-nocheck` to disable warning on unparse arguments.
# - Parse values are prefixed with `ARG`
#
# This macro makes use of some very horrible aspects of CMake macros:
# - Values appear the caller's scope, so no need to set(PARENT_SCOPE)
# - The ${${}ARGV} eldritch horror evaluates to the ARGV *OF THE CALLER*, while
#   ${ARGV} evaluates to the macro's own ARGV value. This is because ${${}ARGV}
#   inhibits macro argument substitution. It is painful, but it makes this magic
#   work.
macro(_pmm_parse_args)
    cmake_parse_arguments(_ "-nocheck" "" ".;-;+" "${ARGV}")
    _pmm_parse_arglist("${${}ARGV}" "${__.}" "${__-}" "${__+}")
endmacro()

macro(_pmm_parse_script_args)
    cmake_parse_arguments(_ "-nocheck" "" ".;-;+" "${ARGV}")
    _pmm_read_script_argv(__script_argv)
    _pmm_parse_arglist("${__script_argv}" "${__.}" "${__-}" "${__+}")
endmacro()

macro(_pmm_parse_arglist argv opt args list_args)
    cmake_parse_arguments(ARG "${opt}" "${args}" "${list_args}" "${argv}")
    if(NOT __-nocheck)
        foreach(arg IN LISTS ARG_UNPARSED_ARGUMENTS)
            message(WARNING "Unknown argument: ${arg}")
        endforeach()
    endif()
endmacro()

macro(_pmm_lift)
    foreach(varname IN ITEMS ${ARGN})
        set("${varname}" "${${varname}}" PARENT_SCOPE)
    endforeach()
endmacro()

function(_pmm_exec)
    execute_process(
        COMMAND ${ARGN}
        OUTPUT_VARIABLE out
        ERROR_VARIABLE out
        RESULT_VARIABLE rc
        )
    set(_PMM_RC "${rc}" PARENT_SCOPE)
    set(_PMM_OUTPUT "${out}" PARENT_SCOPE)
endfunction()
