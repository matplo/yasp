# yasp

Yet Another Software Package[r]

# recommendation

- use within a conda env (it does make life simpler ;-)
- packages here likely do not exist in conda or need a custom install
- for example this will install fastjet, fastjet contributed algos, and pythia8 to prefix dir (default is $HOME/yasp)

```
./yasp.py --install fastjet/3.4.0 fjcontrib/1.050 pythia8/8308 --prefix /tmp/yaspsoft
```

- yasp can write a small file for automatic configuration in the future (`.yasp.yml`) in --use-config location (default is where yasp.py is)
```
./yasp.py --configure --prefix /tmp/yaspsoft --workdir /tmp/yaspsoftworkdir
```

- --configure will take --prefix --workdir and --recipe-dir into account
- location of the config file can be overwritten with --use-config
- use --list to list known recipes (simple scripts with some templating)
- use --recipe-dir to use a different location of the recipes
- note the workdir by default is `$HOME/yasp/.workdir`

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
