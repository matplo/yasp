# yasp

Yet Another Software Package[r]

# help output

```
> ./yasp.py -h
usage: yasp.py [-h] [--configure] [--use-config USE_CONFIG] [--yasp YASP] [--cleanup] [-i INSTALL [INSTALL ...]] [-d DOWNLOAD] [--clean]
               [--redownload] [--dry-run] [--recipe-dir RECIPE_DIR] [-o OUTPUT] [--prefix PREFIX] [-w WORKDIR] [-g] [-l]
               [--donwload-command DONWLOAD_COMMAND] [-q QUERY QUERY]

options:
  -h, --help            show this help message and exit
  --configure           set and write default configuration
  --use-config USE_CONFIG
                        use particular configuration file - default=$PWD/.yasp.yaml
  --yasp YASP           point to yasp.py executable - default: this script
  --cleanup             clean the main workdir (downloaded and build items)
  -i INSTALL [INSTALL ...], --install INSTALL [INSTALL ...]
                        name of the recipe to process
  -d DOWNLOAD, --download DOWNLOAD
                        download file
  --clean               start from scratch
  --redownload          redownload even if file already there
  --dry-run             dry run - do not execute output script
  --recipe-dir RECIPE_DIR
                        dir where recipes info sit - default: /Users/ploskon/devel/yasp/recipes
  -o OUTPUT, --output OUTPUT
                        output definition - for example for download
  --prefix PREFIX       prefix of the installation /Users/ploskon/yasp
  -w WORKDIR, --workdir WORKDIR
                        set the work dir for the setup - default is /Users/ploskon/yasp/.workdir
  -g, --debug, --verbose
                        print some extra info
  -l, --list            list recipes
  --donwload-command DONWLOAD_COMMAND
                        overwrite download command - default is wget; could be curl
  -q QUERY QUERY, --query QUERY QUERY
                        query for a feature or files or directory for a file - join with feature <name> files <pattern> or dirs <pattern> (where
                        file located) to match a query - "PseudoJet.hh" for example
```

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
['/tmp/yasp/include/fastjet']

> python -c "from yasp import yasp_find_files as yff; print(yff('PseudoJet.hh'));"
['/tmp/yasp/include/fastjet/PseudoJet.hh']
```

or you can use it from command line

```
./yasp.py -q feature prefix
./yasp.py -q files ClusterSequence*
./yasp.py -q dirs Lund*
```
