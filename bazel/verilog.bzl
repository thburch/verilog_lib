"""System Verilog rules."""

SvFileInfo = provider(
    "A system verilog file info.",
    fields = {"transitive_sources": "The dependent system verilog sources."},
)

def get_transitive_srcs(srcs, deps):
    """Obtain the source files for a target and its transitive dependencies.

    Args:
      srcs: a list of source files
      deps: a list of targets that are direct dependencies
    Returns:
      a collection of the transitive sources
    """
    return depset(
        srcs,
        transitive = [dep[SvFileInfo].transitive_sources for dep in deps],
    )

def _sv_library(ctx):
    trans_srcs = get_transitive_srcs(ctx.files.srcs, ctx.attr.deps)

    return [
        DefaultInfo(
            files = trans_srcs,
            runfiles = ctx.runfiles(collect_data = True),
        ),
        SvFileInfo(transitive_sources = trans_srcs),
    ]

sv_library = rule(
    implementation = _sv_library,
    attrs = {
        "deps": attr.label_list(),
        "srcs": attr.label_list(
            allow_files = True,
        ),
    },
)

def _sv_flist_impl(ctx):
    sv_flist_py = ctx.executable._sv_flist_py
    flist = ctx.outputs.flist
    trans_srcs = get_transitive_srcs([], [ctx.attr.top])
    srcs_list = trans_srcs.to_list()

    ctx.actions.run(
        executable = sv_flist_py,
        arguments = [
            "--output=%s" % flist.path,
            "--srcs=%s" % (" ".join([src.path for src in srcs_list])),
        ],
        inputs = srcs_list,
        tools = [sv_flist_py],
        outputs = [flist],
    )

sv_flist = rule(
    implementation = _sv_flist_impl,
    attrs = {
        # maybe use a label with allow_single_file
        "top": attr.label(),
        "_sv_flist_py": attr.label(
            default = Label("//bazel:gen_sv_flist"),
            allow_files = True,
            executable = True,
            cfg = "host",
        ),
    },
    outputs = {
        "flist": "gen_%{name}",
    },
)

def nextpnr(name, frequency, part_family, part_package, constraints, json, asc):
    native.genrule(
        name = "%s.asc" % name,
        outs = ["gen_%s.asc" % name],
        cmd = "nextpnr-ice40 --freq {frequency} --{part_family} --package {part_package} --json $(location {json}) --pcf $(location {constraints}) --asc $@".format(frequency = frequency, constraints = constraints, part_family = part_family, part_package = part_package, json = json),
        srcs = [
            ":%s.json" % name,
            constraints,
        ],
    )

def bitstream(name, constraints):
    """Handy macro for building a bitstream.

    Args:
      name: The name of the project. This name should match the top module as
            well. (e.g. Given the name foobar, the top module name should be
            foobar_top)
      constraints: The constraints file used for the bitstream.
    """

    # Create a list of files needed to synthesize.
    sv_flist(
        name = "%s_top.flist" % name,
        top = "%s_top" % name,
    )

    # Create a project file to be run by yosys.
    native.genrule(
        name = "%s.ys" % name,
        outs = ["gen_%s.ys" % name],
        cmd = "$(location //bazel:gen_yosys) --output=$@ --top={name}_top --flist=$(location :{name}_top.flist)".format(name = name),
        tools = ["//bazel:gen_yosys"],
        srcs = [
            ":%s_top.flist" % name,
        ],
    )

    # Run yosys to create a json file.
    native.genrule(
        name = "%s.json" % name,
        outs = ["gen_%s.json" % name],
        cmd = 'yosys $(location :%s.ys) -p "write_json $@"' % name,
        srcs = [
            ":%s.ys" % name,
            ":%s_top" % name,
        ],
    )

    # Run place and route.
    nextpnr(
        name = name,
        frequency = 36,
        part_family = "up5k",
        part_package = "sg48",
        json = ":%s.json" % name,
        constraints = constraints,
        asc = ":%s.asc" % name,
    )

    # Run icepack
    native.genrule(
        name = "%s.bin" % name,
        outs = ["gen_%s.bin" % name],
        cmd = "icepack $(location :%s.asc) $@" % name,
        srcs = [
            ":%s.asc" % name,
        ],
    )

    # Create a programming utility
    native.sh_binary(
        name = "program_%s" % name,
        srcs = ["//bazel:iceprog_program.sh"],
        args = ["$(location :%s.bin)" % name],
        data = [":%s.bin" % name],
    )
