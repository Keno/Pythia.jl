using Pythia

pythia = newPythia()

icxx"""$pythia->readString("Beams:idA = 2212");"""
icxx"""$pythia->readString("Beams:idB = 2212");"""
icxx"""$pythia->readString("Beams:eCM = 8000.");"""
icxx"""$pythia->readString("HardQCD:gg2qqbar = on");"""
icxx"""$pythia->init();"""

ρ⁺ = Array(Float64,0)
ρ⁻ = Array(Float64,0)
ρ⁰ = Array(Float64,0)
for e in take(events(pythia),5)
    for p in particles(e)
        id = icxx"$p.id();"
        m = icxx"$p.m();"
        if id == 213
            push!(ρ⁺,m)
        elseif id == -213
            push!(ρ⁻,m)
        elseif id == 113
            push!(ρ⁰,m)
        end
    end
end

particles = [ρ⁺; ρ⁻; ρ⁰]
colors = [
    [:ρ⁺ for _ in 1:length(ρ⁺)];
    [:ρ⁻ for _ in 1:length(ρ⁻)];
    [:ρ⁰ for _ in 1:length(ρ⁰)]]
plot(y = particles, color = colors, Geom.point)

function track_decay(it,id)
    p = it[id]
    daughter1 = icxx"$p.daughter1();"
    daughter2 = icxx"$p.daughter2();"
    if daughter1 == daughter2 == 0
        println("$id ($(name(it[id]))) does not decay")
        return
    end
    for d in daughter1:daughter2
        println("$id ($(name(it[id]))) decays to $d ($(name(it[d])))")
        track_decay(it,d)
    end
end

for e in take(events(pythia),5)
    ps = particles(e)
    for (i,p) in enumerate(ps)
        # Look for Delta0 or 3112
        id = icxx"$p.id();"
        (2114 == id || 3112 == id) && track_decay(ps,i-1)
    end
    println()
end
