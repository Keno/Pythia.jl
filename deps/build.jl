using BinDeps

@BinDeps.setup

pythia = library_dependency("pythia",aliases=["libpythia","libpythia8"])
fastjet = library_dependency("fastjet",aliases=["libfastjet"])

provides(Sources,URI("http://fastjet.fr/repo/fastjet-3.1.2.tar.gz"),fastjet)
sources = provides(Sources,URI("http://home.thep.lu.se/~torbjorn/pythia8/pythia8205.tgz"),pythia)
builddir = joinpath(BinDeps.builddir(pythia),pythia.name)
bindir = joinpath(builddir,"bin")
steps = BinDeps.generate_steps(pythia, Autotools(configure_options=["--enable-shared"]),Dict())
options = ["--enable-shared","--enable-debug"]
@osx_only push!(options,"--cxx=clang")
provides(BuildProcess,(@build_steps begin
        GetSources(pythia)
        CreateDirectory(builddir)
        # Copy the entire source directory here, since Pythia does not support out of tree builds
        `cp -rpf $(BinDeps.srcdir(pythia,BinDeps.gethelper(pythia,Sources)[1],Dict()))/ $builddir/`
        @build_steps begin
            ChangeDirectory(builddir)
            # Not an actual configure
            `./configure $options --prefix=$(BinDeps.usrdir(pythia))`
            MakeTargets()
            MakeTargets(["install"])
            `chmod +x $(BinDeps.bindir(pythia))/pythia8-config`
        end
    end),pythia)

provides(BuildProcess,Autotools(libtarget = "src/.libs/libfastjet.la"),fastjet)

@BinDeps.install Dict( :pythia => :libpythia, :fastjet => :libfastjet )
