#ifndef __FASTJET_CONTRIB_UTIL_HH__
#define __FASTJET_CONTRIB_UTIL_HH__

#include <fastjet/PseudoJet.hh>
#include "SoftDrop.hh"

FASTJET_BEGIN_NAMESPACE      // defined in fastjet/internal/base.hh

namespace contrib {
	class SDinfo
	{
	public:
		SDinfo();
		~SDinfo();
		double z;
		double dR;
		double mu;
	};

	SDinfo get_SD_jet_info(const fastjet::PseudoJet &j);
};

FASTJET_END_NAMESPACE

#endif
