# yasp

Yet Another Software Package[r]

# recommendation

- use within a conda env (it does make life simpler ;-)
- packages here likely do not exist in conda or need a custom install

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

or you can use it from command line

```
./yasp.py -q feature prefix
./yasp.py -q files ClusterSequence*
./yasp.py -q dirs Lund*
```
