load("//bazel:verilog.bzl", "bitstream", "sv_library")

sv_library(
    name = "or_gate",
    srcs = ["or_gate.sv"],
)

sv_library(
    name = "example_top",
    srcs = ["example_top.sv"],
    deps = [
        ":or_gate",
    ],
)


bitstream(
    name = "example",
    constraints = "//constraints:example.pcf",
)
