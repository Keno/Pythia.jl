using Pythia
cxx"""
#include "fastjet/PseudoJet.hh" 
#include "fastjet/ClusterSequence.hh"
"""

jetdef = icxx"""
  double Rparam = 0.4;
  fastjet::Strategy               strategy = fastjet::Best;
  fastjet::RecombinationScheme    recombScheme = fastjet::E_scheme;
  new fastjet::JetDefinition(fastjet::kt_algorithm, Rparam,
                                      recombScheme, strategy);
"""
fjinputs = icxx"new std::vector <fastjet::PseudoJet>";

pythia = newPythia()

icxx"""$pythia->readString("Beams:idA = 2212");"""
icxx"""$pythia->readString("Beams:idB = 2212");"""
icxx"""$pythia->readString("Beams:eCM = 8000.");"""
icxx"""$pythia->readString("HardQCD:gg2qqbar = on");"""
icxx"""$pythia->readString("PhaseSpace:pTHatMin = 50.0");"""
icxx"""$pythia->init();"""

function cluster(jetDef,e)
    icxx"$fjInputs->resize(0);"
    for p in particles(e)
        # Final State only
        if !icxx"$p.isFinal();"
            continue
        end

        # No neutrinos
        idabs = abs(icxx"$p.id();")
        if idabs == 12 || idabs == 14 || idabs == 16
            continue
        end

        if abs(icxx"$p.eta();" > 3.6)
            continue
        end

        icxx"$fjInputs->push_back( fastjet::PseudoJet( $p.px(),
        $p.py(), $p.pz(), $p.e() ) );"
    end
    icxx"new fastjet::ClusterSequence(*$fjinputs, *$jetDef);"
end

function jets(jetDef,e)
    clusterSeq = cluster(jetDef,e)
    sortedJets = icxx"""
        vector <fastjet::PseudoJet> inclusiveJets;
        inclusiveJets = $clusterSeq->inclusive_jets(20.0);
        new vector <fastjet::PseudoJet> (sorted_by_pt(inclusiveJets));
    """
end

for e in take(events(pythia),10)
    icxx"$pythia->process->list()"
    sortedJets = jets(jetDef,e)
    icxx"""
        for(unsigned int j = 0; j < $sortedJets->size(); j++) { 
        cout << "Jet #" << j << " (px,py,pz,E) = (" << (*$sortedJets)[j].px() << ", " << (*$sortedJets)[j].py() << ", " << (*$sortedJets)[j].pz() << ", "
        << (*$sortedJets)[j].e() << ")\n";
        }
    """
end
