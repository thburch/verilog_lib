# load("@rules_python//python:defs.bzl", "py_binary")

package(default_visibility = ["//visibility:public"])

exports_files(["iceprog_program.sh"])

py_binary(
    name = "gen_yosys",
    srcs = ["gen_yosys.py"],
)

py_binary(
    name = "gen_sv_flist",
    srcs = ["gen_sv_flist.py"],
)