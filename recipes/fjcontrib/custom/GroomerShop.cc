#include "GroomerShop.hh"

#include <limits>
#include <vector>
#include <algorithm>
#include <cmath>
#include <sstream>
#include <fastjet/LimitedWarning.hh>

FASTJET_BEGIN_NAMESPACE      // defined in fastjet/internal/base.hh

namespace contrib
{
	namespace GroomerShopUtil
	{
	    static LundDeclustering _zero_split = LundDeclustering();
	    static LundDeclustering *zero_split()
	    {
	    	_zero_split.reset();
	    	return &_zero_split;
	    }
    	static LimitedWarning _warnings = LimitedWarning();
    };

	// credit: https://thispointer.com/c-how-to-find-an-element-in-vector-and-get-its-index/
	// unfortunately the == operator not implemented for LundDeclustering

	bool operator==(const LundDeclustering &ld1, const LundDeclustering &ld2)
	{
		if (ld1.pair() == ld2.pair())
			return true;
		return false;
	}

	template < typename T>
	std::pair<bool, int > findInVector(const std::vector<T>  & vecOfElements, const T  & element)
	{
		std::pair<bool, int > result;

		// Find given element in vector
		auto it = std::find(vecOfElements.begin(), vecOfElements.end(), element);

		if (it != vecOfElements.end())
		{
			result.second = distance(vecOfElements.begin(), it);
			result.first = true;
		}
		else
		{
			result.first = false;
			result.second = -1;
		}

		return result;
	}

    GroomerShop::GroomerShop()
    : _lund_gen(JetDefinition(JetAlgorithm::cambridge_algorithm, JetDefinition::max_allowable_R))
    , _lund_splits()
    , _jet(0)
  	{;}

    GroomerShop::GroomerShop(const JetAlgorithm& jet_alg)
    : _lund_gen(JetDefinition(jet_alg, JetDefinition::max_allowable_R))
    , _lund_splits()
    , _jet(0)
  	{;}

    GroomerShop::GroomerShop(const int& jet_alg)
    : _lund_gen(JetDefinition(static_cast<JetAlgorithm>(jet_alg), JetDefinition::max_allowable_R))
    , _lund_splits()
    , _jet(0)
  	{;}

    GroomerShop::GroomerShop(const PseudoJet& jet)
    : _lund_gen(JetDefinition(JetAlgorithm::cambridge_algorithm, JetDefinition::max_allowable_R))
    , _lund_splits()
    , _jet(&jet)
    {
      recluster(jet);
    }

    GroomerShop::GroomerShop(const PseudoJet& jet, const JetAlgorithm& jet_alg)
    : _lund_gen(JetDefinition(jet_alg, JetDefinition::max_allowable_R))
    , _lund_splits()
    , _jet(&jet)
    {
      recluster(jet);
    }

    GroomerShop::GroomerShop(const PseudoJet& jet, const int& jet_alg)
    : _lund_gen(JetDefinition(static_cast<JetAlgorithm>(jet_alg), JetDefinition::max_allowable_R))
    , _lund_splits()
    , _jet(&jet)
    {
      recluster(jet);
    }

    GroomerShop::GroomerShop(const PseudoJet& jet, const double& R0, const JetAlgorithm& jet_alg)
    : _lund_gen(JetDefinition(jet_alg, R0))
    , _lund_splits()
    , _jet(&jet)
    {
      recluster(jet);
    }

    GroomerShop::GroomerShop(const PseudoJet& jet, const double& R0, const int& jet_alg)
    : _lund_gen(JetDefinition(static_cast<JetAlgorithm>(jet_alg), R0))
    , _lund_splits()
    , _jet(&jet)
    {
      recluster(jet);
    }

    GroomerShop::GroomerShop(const PseudoJet& jet, const double& R0)
    : _lund_gen(JetDefinition(JetAlgorithm::cambridge_algorithm, R0))
    , _lund_splits()
    , _jet(&jet)
    {
      recluster(jet);
    }

    GroomerShop::GroomerShop(const JetDefinition& jet_def)
    : _lund_gen(jet_def)
    , _lund_splits()
    , _jet(0)
    {;}

    GroomerShop::GroomerShop(const PseudoJet& jet, const JetDefinition& jet_def)
    : _lund_gen(jet_def)
    , _lund_splits()
    , _jet(&jet)
  	{
      recluster(jet);
  	}

	/// description of the class
	std::string GroomerShop::description() const
	{
		std::ostringstream oss;
		oss << "GroomerShop with " << _lund_gen.description();
		return oss.str();
	}

    const PseudoJet* GroomerShop::jet() const
    {
    	return _jet;
    }

    /// return the LundGenerator used
    const LundGenerator& GroomerShop::lund_generator() const
    {
    	return _lund_gen;
    }

	int GroomerShop::index(const LundDeclustering &l)
	{
		int result = -1;

		std::pair<bool, int> rpair = findInVector(_lund_splits, l);

		if (rpair.first)
			result = rpair.second;

		return result;
	}

	/// recluster and set the vector of primary lund plane splittings
	bool GroomerShop::recluster(const PseudoJet& jet)
	{
		_lund_splits.clear();
		_lund_splits = _lund_gen.result(jet);
		_jet = &jet;
		return (_lund_splits.size() > 0);
	}


	/// obtain the declusterings of the primary plane of the jet
	std::vector<LundDeclustering> GroomerShop::lund_splits() const
	{
		return _lund_splits;
	}

 	/// set the declusterings of the primary plane of the jet
	void GroomerShop::set_lund_splits(const std::vector<LundDeclustering>& lunds)
	{
		_lund_splits = lunds;
	}

	// return the split of dynamical grooming with alpha
	// https://arxiv.org/abs/1911.00375
	LundDeclustering* GroomerShop::dynamical(const double& alpha)
	{
		LundDeclustering* result = GroomerShopUtil::zero_split();
		double min_kappa = std::numeric_limits<double>::max();
		for (unsigned int i = 0; i < _lund_splits.size(); i++)
		{
			// double kappa = 1/(z * (1-z) * pt * pow(theta,a_));
			double kappa = 1. / ( _lund_splits[i].z() * (1. - _lund_splits[i].z()) * _lund_splits[i].pair().pt() * pow(_lund_splits[i].Delta(), alpha));
			if (min_kappa > kappa)
			{
				min_kappa = kappa;
				result = &_lund_splits[i];
			}
		}
		if (min_kappa == std::numeric_limits<double>::max())
		{
			// throw Error("minimum kappa not found for a given jet");
			GroomerShopUtil::_warnings.warn("minimum kappa not found for a given jet - jet with no substructure? returning an 'empty' split");
		}
		return result;
	}

	/// max pT split grooming ----
	/// obtain the splitting of max{pT's of softer prongs}
	LundDeclustering* GroomerShop::max_pt_softer()
	{
		LundDeclustering* result = GroomerShopUtil::zero_split();
		double max_pt_softer = std::numeric_limits<double>::min();
		for (unsigned int i = 0; i < _lund_splits.size(); i++)
		{
			if (_lund_splits[i].softer().pt() > max_pt_softer)
			{
				max_pt_softer = _lund_splits[i].softer().pt();
				result = &_lund_splits[i];
			}
		}
		if (max_pt_softer == std::numeric_limits<double>::min())
		{
			// throw Error("max pt softer not found for a given jet");
			GroomerShopUtil::_warnings.warn("max pt softer not found for a given jet - jet with no substructure? returning an 'empty' split");
		}
		return result;
	}

	/// max z split grooming ----
	/// obtain the splitting of max{z_i}
	LundDeclustering* GroomerShop::max_z()
	{
		LundDeclustering* result = GroomerShopUtil::zero_split();
		double max_z = std::numeric_limits<double>::min();
		for (unsigned int i = 0; i < _lund_splits.size(); i++)
		{
			if (_lund_splits[i].z() > max_z)
			{
				max_z = _lund_splits[i].z();
				result = &_lund_splits[i];
			}
		}
		if (max_z == std::numeric_limits<double>::min())
		{
			// throw Error("max z not found for a given jet");
			GroomerShopUtil::_warnings.warn("max z not found for a given jet - jet with no substructure? returning an 'empty' split");
		}
		return result;
	}

	/// max kt split grooming ----
	/// obtain the splitting of max{kt_i}
	LundDeclustering* GroomerShop::max_kt()
	{
		LundDeclustering* result = GroomerShopUtil::zero_split();
		double max_kt = std::numeric_limits<double>::min();
		for (unsigned int i = 0; i < _lund_splits.size(); i++)
		{
			if (_lund_splits[i].kt() > max_kt)
			{
				max_kt = _lund_splits[i].kt();
				result = &_lund_splits[i];
			}
		}
		if (max_kt == std::numeric_limits<double>::min())
		{
			// throw Error("max kt not found for a given jet");
			GroomerShopUtil::_warnings.warn("max kt not found for a given jet - jet with no substructure? returning an 'empty' split");
		}
		return result;
	}

        /// `Late-kT' grooming ----
        /// Obtain the smallest angle splitting which passes some kT cut
        /// https://arxiv.org/abs/2211.11789
        LundDeclustering* GroomerShop::late_kt(const double& kT_cut)
        {
                LundDeclustering* result = GroomerShopUtil::zero_split();
                double min_delta_ij = std::numeric_limits<double>::max();
                for (unsigned int i = 0; i < _lund_splits.size(); i++)
                {
                        if (_lund_splits[i].Delta() < min_delta_ij && _lund_splits[i].kt() > kT_cut)
                        {
                                min_delta_ij = _lund_splits[i].Delta();
                                result = &_lund_splits[i];
                        }
                }
                if (min_delta_ij == std::numeric_limits<double>::max())
                {
                        // throw Error("Late kT not found for a given jet");
                        GroomerShopUtil::_warnings.warn("Late kT not found for a given jet - jet with no substructure? returning an 'empty' split");
                }
                return result;
        }

	/// max kappa split grooming ----
	/// obtain the splitting of max{kappa_i}
	LundDeclustering* GroomerShop::max_kappa()
	{
		LundDeclustering* result = GroomerShopUtil::zero_split();
		double max_kappa = std::numeric_limits<double>::min();
		for (unsigned int i = 0; i < _lund_splits.size(); i++)
		{
			if (_lund_splits[i].kappa() > max_kappa)
			{
				max_kappa = _lund_splits[i].kappa();
				result = &_lund_splits[i];
			}
		}
		if (max_kappa == std::numeric_limits<double>::min())
		{
			// throw Error("max kappa not found for a given jet");
			GroomerShopUtil::_warnings.warn("max kappa not found for a given jet - jet with no substructure? returning an 'empty' split");
		}
		return result;
	}

	/// max tf split grooming ----
	/// obtain the splitting of min{tf_i}
	/// note t_f = 1/(z\Delta^2) - so we maximize z\Delta^2
	LundDeclustering* GroomerShop::min_tf()
	{
		LundDeclustering* result = GroomerShopUtil::zero_split();
		double max_tf = std::numeric_limits<double>::min();
		for (unsigned int i = 0; i < _lund_splits.size(); i++)
		{
			double _tf = _lund_splits[i].z() * _lund_splits[i].Delta() * _lund_splits[i].Delta();
			if (_tf > max_tf)
			{
				max_tf = _tf;
				result = &_lund_splits[i];
			}
		}
		if (max_tf == std::numeric_limits<double>::min())
		{
			// throw Error("max tf not found for a given jet");
			GroomerShopUtil::_warnings.warn("max tf not found for a given jet - jet with no substructure? returning an 'empty' split");
		}
		return result;
	}

	/// min tf split grooming ----
	/// obtain the splitting of max{tf_i}
	/// note t_f = 1/(z\Delta^2) - so we minimize z\Delta^2
	LundDeclustering* GroomerShop::max_tf()
	{
		LundDeclustering* result = GroomerShopUtil::zero_split();
		double min_tf = std::numeric_limits<double>::max();
		for (unsigned int i = 0; i < _lund_splits.size(); i++)
		{
			double _tf = _lund_splits[i].z() * _lund_splits[i].Delta() * _lund_splits[i].Delta();
			if (_tf < min_tf)
			{
				min_tf = _tf;
				result = &_lund_splits[i];
			}
		}
		if (min_tf == std::numeric_limits<double>::max())
		{
			// throw Error("min tf not found for a given jet");
			GroomerShopUtil::_warnings.warn("min tf not found for a given jet - jet with no substructure? returning an 'empty' split");
		}
		return result;
	}

	// soft drop
	LundDeclustering* GroomerShop::soft_drop(double beta, double zcut, double R0)
	{
		LundDeclustering* result = GroomerShopUtil::zero_split();
		for (unsigned int i = 0; i < _lund_splits.size(); i++)
		{
			if (_lund_splits[i].z() > zcut * pow(_lund_splits[i].Delta() / R0, beta))
			{
				result = &_lund_splits[i];
				break;
			}
		}
		// no warning about no SD splits - consider returning the jet + last clustering step (but this would have the wrong z)
		// if (result == GroomerShopUtil::zero_split())
		// {
		// 	std::stringstream os;
		// 	os << "softdrop returning 'empty' split " << result->z();
		// 	GroomerShopUtil::_warnings.warn(os.str().c_str());
		// }
		return result;
	}

};

FASTJET_END_NAMESPACE

 
