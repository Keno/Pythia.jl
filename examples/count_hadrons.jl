using Pythia
pythia = newPythia()

icxx"""$pythia->readString("Beams:idA = 11");"""
icxx"""$pythia->readString("Beams:idB = -11");"""
icxx"""$pythia->readString("Beams:eCM = 10.");"""
icxx"""$pythia->readString("WeakSingleBoson:ffbar2ffbar(s:gm) = on");"""
icxx"""$pythia->init();"""

# Check if this is a e⁺e⁻ -> qqbar process
function isqqbar(e)
    # Look through the particles to find those in the hard process
    for p in particles(e)
        if abs(icxx"$p.status();") == 23
            id = icxx"$p.id();"
            # quarks
            return 1 <= abs(id) <= 5
        end
    end
end

count_hadrons(e) = sum([icxx"$p.isHadron();" for p in particles(e)])

energies = linspace(10,120,6)
nhadrons = map(energies) do eCM
   pythia = newPythia()

   icxx"""$pythia->readString("Beams:idA = 11");"""
   icxx"""$pythia->readString("Beams:idB = -11");"""
   readString(pythia,"Beams:eCM = $eCM")
   icxx"""$pythia->readString("WeakSingleBoson:ffbar2ffbar(s:gm) = on");"""
   icxx"""$pythia->init();"""

   mean(filter(x->x != -1, map(e->isqqbar(e) ? count_hadrons(e) : -1, take(events(pythia),1000))))
end
plot(x = energies, y = nhadron, Geom.point, Geom.smooth(method=:loess,smoothing=0.9), Guide.xlabel("√s [GeV]"), Guide.ylabel("⟨Nhadron⟩"))
