#ifndef __FASTJET_CONTRIB_GROOMERSHOP_HH__
#define __FASTJET_CONTRIB_GROOMERSHOP_HH__

#include <sstream>
#include "LundGenerator.hh"

FASTJET_BEGIN_NAMESPACE

namespace contrib
{
  bool operator==(const LundDeclustering &ld1, const LundDeclustering &ld2);
  template < typename T>
  std::pair<bool, int > findInVector(const std::vector<T>  & vecOfElements, const T  & element);

  class GroomerShop
  {
  public:

    /// constructors
    GroomerShop();
  	GroomerShop(const JetAlgorithm& jet_alg);
    GroomerShop(const int& jet_alg);

    GroomerShop(const PseudoJet& jet);
    GroomerShop(const PseudoJet& jet, const JetAlgorithm& jet_alg);
    GroomerShop(const PseudoJet& jet, const int& jet_alg);
    GroomerShop(const PseudoJet& jet, const double& R0, const JetAlgorithm& jet_alg);
    GroomerShop(const PseudoJet& jet, const double& R0, const int& jet_alg);
    GroomerShop(const PseudoJet& jet, const double& R0);

  	GroomerShop(const JetDefinition& jet_def);
    GroomerShop(const PseudoJet& jet, const JetDefinition& jet_def);

    /// destructor
    virtual ~GroomerShop() 
    {;}

    /// description of the class
    virtual std::string description() const;

    // return the pointer to the last groomed jet
    virtual const fastjet::PseudoJet* jet() const; 

    /// return the LundGenerator used
    virtual const LundGenerator &lund_generator() const;

    /// a convenienve - once you have the split - get it's index in the vector of primary lund
    virtual int index(const LundDeclustering &l);

    /// recluster and set the vector of primary lund plane splittings
    virtual bool recluster(const PseudoJet& jet);

    /// obtain the declusterings of the primary plane of the jet
    virtual std::vector<LundDeclustering> lund_splits() const;

    /// set the declusterings of the primary plane of the jet
    virtual void set_lund_splits(const std::vector<LundDeclustering>& lunds);

    /// obtain the splitting after dynamical grooming of the primary plane of the jet
    // https://arxiv.org/abs/1911.00375
    virtual LundDeclustering* dynamical(const double& alpha);

    /// obtain the splitting of max{pT's of softer prongs}
    virtual LundDeclustering* max_pt_softer();

    /// obtain the splitting of max{z_i}
    virtual LundDeclustering* max_z();

    /// obtain the splitting of max{kt_i}
    virtual LundDeclustering* max_kt();

    /// obtain the smallest angle splitting which passes some kT cut
    virtual LundDeclustering* late_kt(const double& kT_cut);

    /// obtain the splitting of max{kappa_i}
    virtual LundDeclustering* max_kappa();

    /// obtain the splitting of max{tf_i} : tf = z\theta^2
    virtual LundDeclustering* max_tf();

    /// obtain the splitting of min{tf_i} : tf = z\theta^2
    virtual LundDeclustering* min_tf();

    /// soft drop - returns zero_split in case no substructure found
    virtual LundDeclustering* soft_drop(double beta, double zcut, double R0 = JetDefinition::max_allowable_R);

  private:
    LundGenerator _lund_gen;
    std::vector<LundDeclustering> _lund_splits;
    const fastjet::PseudoJet* _jet;
  };

} // namespace contrib

FASTJET_END_NAMESPACE

#endif // __FASTJET_CONTRIB_DYGROOMER_HH__
