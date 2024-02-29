#ifndef __FASTJET_CONTRIB_DYGROOMER_HH__
#define __FASTJET_CONTRIB_DYGROOMER_HH__

#include <sstream>
#include <fastjet/LimitedWarning.hh>
#include "LundGenerator.hh"

FASTJET_BEGIN_NAMESPACE

namespace contrib
{
  class DynamicalGroomer
  {
  public:

  	DynamicalGroomer(JetAlgorithm jet_alg = cambridge_algorithm)
    : _cached_jet(0)
  	, _lund_gen(JetDefinition(jet_alg, JetDefinition::max_allowable_R))
    , _lund_splits()
    , _result()
  	{}

  	DynamicalGroomer(const JetDefinition & jet_def) 
    : _cached_jet(0)
  	, _lund_gen(jet_def)
    , _lund_splits()
    , _result()
  	{;}

    /// destructor
    virtual ~DynamicalGroomer() 
    {;}

    /// obtain the index of the splitting after dynamical grooming of the primary plane of the jet
    int result_split_index(const std::vector<LundDeclustering>& lunds, const double& alpha);
    static LundDeclustering& result_split(const std::vector<LundDeclustering>& lunds, const double& alpha);

    /// obtain the splitting after dynamical grooming of the primary plane of the jet
    virtual LundDeclustering result(const PseudoJet& jet, const double& alpha);

    /// obtain the declusterings of the primary plane of the jet
    virtual std::vector<LundDeclustering> lund_splits() const;

    /// description of the class
    virtual std::string description() const;

    /// obtain the splitting of max{pT's of softer prongs}
    virtual LundDeclustering max_pt_softer(const PseudoJet& jet);
    /// obtain the index of the max{pT's of softer prongs} the primary plane of the jet
    int max_pt_softer_split_index(const std::vector<LundDeclustering>& lunds);
    static LundDeclustering& max_pt_softer_split(const std::vector<LundDeclustering>& lunds);

    /// obtain the splitting of max{z_i}
    virtual LundDeclustering max_z(const PseudoJet& jet);
    /// obtain the index of the max{z_i} the primary plane of the jet
    int max_z_split_index(const std::vector<LundDeclustering>& lunds);
    static LundDeclustering& max_z_split(const std::vector<LundDeclustering>& lunds);

    /// obtain the splitting of max{kt_i}
    virtual LundDeclustering max_kt(const PseudoJet& jet);
    /// obtain the index of the max{kt_i} the primary plane of the jet
    int max_kt_split_index(const std::vector<LundDeclustering>& lunds);
    static LundDeclustering& max_kt_split(const std::vector<LundDeclustering>& lunds);

    /// obtain the splitting of late{kt_i}
    virtual LundDeclustering late_kt(const PseudoJet& jet, const double& kT_cut);
    /// obtain the index of the late{kt_i} the primary plane of the jet
    int late_kt_split_index(const std::vector<LundDeclustering>& lunds, const double& kT_cut);
    static LundDeclustering& late_kt_split(const std::vector<LundDeclustering>& lunds, const double& kT_cut);

    /// obtain the splitting of max{kappa_i}
    virtual LundDeclustering max_kappa(const PseudoJet& jet);
    /// obtain the index of the max{kappa_i} the primary plane of the jet
    int max_kappa_split_index(const std::vector<LundDeclustering>& lunds);
    static LundDeclustering& max_kappa_split(const std::vector<LundDeclustering>& lunds);

    /// obtain the splitting of max{tf_i} : tf = z\theta^2
    virtual LundDeclustering max_tf(const PseudoJet& jet);
    /// obtain the index of the max{tf_i} the primary plane of the jet
    int max_tf_split_index(const std::vector<LundDeclustering>& lunds);
    static LundDeclustering& max_tf_split(const std::vector<LundDeclustering>& lunds);

    /// obtain the splitting of min{tf_i} : tf = z\theta^2
    virtual LundDeclustering min_tf(const PseudoJet& jet);
    /// obtain the index of the min{tf_i} the primary plane of the jet
    int min_tf_split_index(const std::vector<LundDeclustering>& lunds);
    static LundDeclustering& min_tf_split(const std::vector<LundDeclustering>& lunds);

  private:
    PseudoJet *_cached_jet;
  	LundGenerator _lund_gen;
    std::vector<LundDeclustering> _lund_splits;
    LundDeclustering _result;
    static LundDeclustering _zero_split;
    static LimitedWarning _warnings;
  };

} // namespace contrib

FASTJET_END_NAMESPACE

#endif // __FASTJET_CONTRIB_DYGROOMER_HH__
