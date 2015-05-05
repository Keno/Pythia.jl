module Pythia

include("../deps/deps.jl")

export newPythia, newPythiaWithLHE, events, particles, name, readString

using Cxx
using Base.Libdl: dlopen
import Base: start, next, done, getindex, length
# TODO: This isn't right. Should add support in BinDeps
pythia_config() = joinpath(dirname(libpythia), "../bin/pythia8-config")
includedir() = strip(readall(`$(pythia_config()) --includedir`))
libdir() = strip(readall(`$(pythia_config()) --libdir`))
xmldir() = joinpath(includedir(),"..","xmldoc")

function __init__()
    addHeaderDir(includedir())
    include(Pkg.dir("Cxx","src","CxxREPL","replpane.jl"))
    cxx"""
        #include "Pythia8/Pythia.h"
        using namespace Pythia8;
    """
    # Dlopen the libraries so dlsym will find it
    dlopen(libpythia)
    dlopen(libfastjet)
end

newPythia() = icxx"new Pythia($(pointer(Pythia.xmldir())),false);"

function newPythiaWithLHE(file)
    pythia = newPythia()
    icxx"""$pythia->readString("Beams:frameType = 4");"""
    s = "Beams:LHEF = $file"
    icxx"""$pythia->readString($(pointer(s)));"""
    println(s)
    icxx"""$pythia->init();"""
    pythia
end

function readString(pythia,s)
    icxx"""$pythia->readString($(pointer(s)));"""
end

# Lazily generates event from the given pythia instances. Event pointers are only valid for the
# duration of the iteration
type EventIterator
    pythia::pcpp"Pythia8::Pythia"
    nabort::Int
    iabort::Int
    EventIterator(p::pcpp"Pythia8::Pythia",nabort = 10) = new(p,nabort,0)
end
events(p::pcpp"Pythia8::Pythia") = EventIterator(p)
start(it::EventIterator) = nothing
next(it::EventIterator,x) = (icxx"&$(it.pythia)->event;",nothing)
function done(it::EventIterator, x)
    if icxx"!$(it.pythia)->next();"
        if icxx"$(it.pythia)->info.atEndOfFile();"
            return true
        end
        it.iabort += 1
        if it.iabort < it.nabort
            return done(it, x)
        end
        return true
    end
    return false
end

# Iterates over the particles in the current event
immutable EventParticleIterator
    event::pcpp"Pythia8::Event"
    # Hidden gc root
    root::Any
    EventParticleIterator(data::pcpp"Pythia8::Event") = new(data)
end
particles(p::pcpp"Pythia8::Pythia") = PythiaParticleIterator(icxx"&$p->event;")
particles(p::pcpp"Pythia8::Event") = EventParticleIterator(p)
start(it::EventParticleIterator) = 0
getindex(it::EventParticleIterator,i) = icxx"(*$(it.event))[$i];"
length(it::EventParticleIterator) = icxx"$(it.event)->size();"
next(it::EventParticleIterator,i) = (it[i], i+1)
done(it::EventParticleIterator,i) = i >= length(it)

function name(p::Union(vcpp"Pythia8::Particle",rcpp"Pythia8::Particle"))
    n = icxx"$p.name();"
    return bytestring(icxx"$n.data();")
end

end # module
