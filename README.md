# yasp

Yet Another Software Package[r]

# recommendation

- use within a conda env (it does make life simpler ;-)
- packages here likely do not exist in conda or need a custom install

# to do

- this could be used by other packages

# use from within python

- consider these examples (see source file)

```
> python -c "from yasp import yasp_feature as yf; print(yf('prefix'));" 
/tmp/yasp

> python -c "from yasp import yasp_find_files_dirnames as yffd; print(yffd('PseudoJet.hh'));"
['/tmp/yasp/include/fastjet/PseudoJet.hh']

> python -c "from yasp import yasp_find_files as yff; print(yff('PseudoJet.hh'));"
['/tmp/yasp/include/fastjet']
```