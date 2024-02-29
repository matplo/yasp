#include "RecursiveTools/Util.hh"

FASTJET_BEGIN_NAMESPACE      // defined in fastjet/internal/base.hh

namespace contrib {
	SDinfo::SDinfo() : z(0), dR(0), mu(0) {;}
	SDinfo::~SDinfo() {;}

	SDinfo get_SD_jet_info(const fastjet::PseudoJet &j)
	{
		SDinfo ifo;
		if (j.has_structure_of<fastjet::contrib::SoftDrop>())
		{
			ifo.dR = j.structure_of<fastjet::contrib::SoftDrop>().delta_R();
			ifo.z = j.structure_of<fastjet::contrib::SoftDrop>().symmetry();
			ifo.mu = j.structure_of<fastjet::contrib::SoftDrop>().mu();
		}
		return ifo;
	}
};

FASTJET_END_NAMESPACE

