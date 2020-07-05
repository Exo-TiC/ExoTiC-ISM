<!-- PROJECT SHIELDS -->
[![DOI](https://joss.theoj.org/papers/10.21105/joss.02281/status.svg)](https://doi.org/10.21105/joss.02281)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.3923986.svg)](https://doi.org/10.5281/zenodo.3923986)
[![MIT License][license-shield]][license-url]
![Python version][python-version-url]

<img src="logo.png" align="left" />

# ExoTiC-ISM
**Exoplanet Timeseries Characterisation - Instrument Systematic Marginalisation**

This code performs Levenberg-Marquardt least-squares minimisation across a grid of pseudo-stochastic instrument systematic models to produce marginalised transit parameters given a lightcurve for a specified wavelength range.

This was developed and tested for data from Wide Field Camera 3 (WFC3) on the Hubble Space Telescope (HST), specifically with the G141 spectroscopic grism, as published in [Wakeford et al. (2016)](https://ui.adsabs.harvard.edu/abs/2016ApJ...819...10W/abstract). This method can also be applied to the WFC3 IR G102 grism, and UVIS G280 grism by selecting the correct parameters.
Future work includes plans to extend this to Space Telescope Imaging Spectrograph (STIS) instrument data, and eventually data from the James Webb Space Telescope (JWST).

This code follows the method outlined in [Wakeford et al. (2016)](https://ui.adsabs.harvard.edu/abs/2016ApJ...819...10W/abstract), using marginalisation across a stochastic grid of 50 polynomial models (see bottom for full grid). 
These 50 instrument systematic models contain a combination of corrective factors for likely HST systematics. These include a linear trend in time across the whole lightcurve, accounting for HST breathing effects caused by thermal changes in the telescope with up to a 4th order polynomial, and correcting for positional shifts of the target spectrum on the detector fitting up to a 4th order polynomial. See [Wakeford et al. (2016)](https://ui.adsabs.harvard.edu/abs/2016ApJ...819...10W/abstract) section 2.2 for details and Table 2 therein for the full grid of systematic models included. 

The evidence (marginal liklihood) is calculated from the AIC for each model when fit with the data and converted to a normalised weighting that is used to marginalise each of the global fit parameters. See equations 15 and 16 in [Wakeford et al. (2016)](https://ui.adsabs.harvard.edu/abs/2016ApJ...819...10W/abstract) to marginalise over the parameters and their uncertainties.

The program makes use of the analytic transit model in [Mandel & Agol (2002)](https://ui.adsabs.harvard.edu/abs/2002ApJ...580L.171M/abstract) and a Levenberg-Marquardt least squares minimisation using [Sherpa](https://sherpa.readthedocs.io/en/latest/), a Python package for modeling and fitting data. The transit model uses a 4-parameter limb darkening law, as outlined in [Claret (2010)](https://ui.adsabs.harvard.edu/abs/2000A%26A...363.1081C/abstract) and [Sing (2010)](https://ui.adsabs.harvard.edu/abs/2010A%26A...510A..21S/abstract).

This package was built from the original IDL code used for the analysis in [Wakeford et al. (2016)](https://ui.adsabs.harvard.edu/abs/2016ApJ...819...10W/abstract), initially translated by Matthew Hill and then further adapted and transformed into a full astronomy Python package with the help of Iva Laginja.

Note how this is not an installable package, but you will  always need to clone it if you want to work with it.

## Supported instruments and gratings
Current supported instruments and gratings are:  
**HST** *WFC3* IR/G102, IR/G141 grisms


##  Quickstart

*This section will you give all the necessary terminal commands to go from opening our GitHub page in the browser to having 
reduced results of the template data on your local machine. For a more thorough description of the individual steps, please continue to the section 
**Prerequisites** and beyond.*

For a tutorial on ExoTiC-ISM, please see `notebooks` --> `tutorials` --> `1_Intro-tutorial.ipynb`.

We assume that you have `conda` and `git` installed and that you're using `bash`.

### Clone the repo and create conda environment

- Navigate to the directory you want to clone the repository into:  
```bash
$ cd /User/<YourUser>/repos/
```

- Clone the repository:  
```bash
$ git clone https://github.com/hrwakeford/ExoTiC-ISM.git
```
or use SSH if that is your preferred way of cloning repositories:
```bash
$ git clone git@github.com:hrwakeford/ExoTiC-ISM.git
```

- Navigate into the cloned repository:  
```bash
$ cd ExoTiC-ISM
```

- Create the `exoticism` conda environment:  
```bash
$ conda env create --file environment.yml
```

- Activate the environment:
```bash
$ conda activate exoticism
```

- Install the package into this environment, in editable mode:
```bash
$ python setup.py develop
```

### Set up local configfile

- Go into the code directory:  
```bash
$ cd exoticism
```

- Copy the file `config.ini` and name the copy `config_local.ini`.

- Open your local configfile `config_local.ini` and edit the entry `[data_paths][local_path]` to point to your local repo clone that you just created, e.g.:  
```ini
[data_paths]
local_path = /Users/<YourUser>/repos/ExoTiC-ISM
```

- In the same file, define with `[data_paths][output_path]` where your output data should be saved to, e.g.:  
```ini
[data_paths]
...
output_path = /Users/<YourUser>/<path-to-data>
```

### Run the main script

- Activate the conda environment you just created:
```bash
$ conda activate exoticism
```

- Run the marginalisation on the demo data from the template:  
```bash
$ python marginalisation.py
```

The script takes a short while to run and will output messages to the terminal and save the final data to the path you 
specified under `[data_paths][output_path]` in your `config_local.ini`!

## Full setup

### Prerequisites

This is not an installable package (yet), so you will need to clone it if you want to work with it.
Sherpa is distributed for Mac and Linux, this means Windows users will have to use a Linux virtual machine or find an alternative solution. 

We highly recommend the usage of the package and environment manager [Conda](https://docs.conda.io/projects/conda/en/latest/index.html), 
which is free and runs on Windows, macOS and Linux. We have included an [environment](environment.yml) file in our repository 
from which you can directly build a new conda environment in which we have tested our package. We developed and tested our 
 package with **Python 3.7.3** in **conda 4.6.7**.
 
After cloning the repository, run

```bash
$ conda env create --file environment.yml
```

to build the environment, or optionally

```bash
$ conda env create --name <myEnvName> --file environment.yml
```

to give the environment your own name.

The last step is to install the `exoticism` package into your newly created environment. We do currently not support a
plain install ($ python setup.py install), instead please install it in editable mode:
```bash
$ python setup.py develop
```


### Configuration file

The main configuration file is `config.ini`, which holds all of your simulation parameters. This specific file,
however, is version controlled, and the paths to local directories will get messed up if you push or pull this
file; you might also lose the changes you made to the parameters. This is why `config.ini` is initially supposed to be used as a **template**.

In order to make it work for you, copy `config.ini` and rename the copy to `config_local.ini`. In this **local configfile**, 
you can set all your parameters, and it will override the `config.ini` at runtime. Whichever configfile is used in the end, 
the version controlled one or the local one, a copy of it is always saved together with the output data. In the case you 
want to version control the configfile you use, we recommend that you **fork** the repository and simply use the `config.ini` file directly.

**The configfile** has the following structure, except here we added some extra comments for clarity:
```ini
[data_paths]
local_path = /Users/MyUser/repos/ExoTiC-ISM           ; your global path to the repo clone
input_path = ${local_path}/data                       ; global path to the input data, defaults to template data in repo
output_path = /Users/MyUser/outputs                   ; global path ot the output directory 
run_name = testing                                    ; suffix for output data directory

[setup]
data_set = W17                                   ; data selection; refers to section in configfile
instrument = WFC3
grating = G141
grid_selection = fit_time
ld_model = 3D                     ; 3D or 2D limb darkening model
plotting = True
report = True

[smooth_model]
resolution = 0.0001
half_range = 0.2


; Stellar and planet system parameters - make a new section for each new data set

[W17]
lightcurve_file = W17_${setup:grating}_lightcurve_test_data.txt         ; lightcurve data file
wvln_file = W17_${setup:grating}_wavelength_test_data.txt               ; wavelength data file
rl = 0.12169232                                             ; Rp/R* estimate - the transit depth
epoch = 57957.970153390                                     ; in MJD
inclin = 87.34635                                           ; inclination in deg
ecc = 0.0                                                   ; eccentricity in deg
omega = 0.0                                                 ; deg
Per = 3.73548535                                            ; planet period in days
aor = 7.0780354                                             ;a/r* (unitless) --> "distance of the planet from the star (meters)/stellar radius (meters)"

; limb darkening parameters
metallicity = -1.0                ; stellar metallicity
Teff = 6550                       ; stellar effective temperature
logg = 4.5                        ; log gravity of star

[constants]
dtosec = 86400                    ; conversion factor from days to seconds
HST_period = 0.06691666           ; Hubbe Space Telescope period in days
```

### Output data

The relevant data files and plots from your run, together with the used configfile, will be saved to the directory you specify under **`output_path`** in your 
local configfile. The results of each new run will be saved in a subdirectory under `[data_paths] -> output_path` that is labelled with a time stamp, the
name of the stellar system data and a custom suffix, which you set in the configfile.

### Changing input data and/or input parameters

We provide demo data for the exoplanet WASP-17b, which is one of the datasets analyzed in [Wakeford et al. (2016)](https://ui.adsabs.harvard.edu/abs/2016ApJ...819...10W/abstract).
Please refer to section "Supported instruments and gratings" for a list of currently supported instruments and gratings. If you want to perform the marginalisation on a different 
transit dataset, you have to point the configfile to your input data folder and also update the planetary parameters by adding a new section to the configfile.

#### Input filenames

Due to the structure of the configfile (see above), we follow this naming convention for input files:  
star + grating + arbitrary string + .txt  
*E.g.: "W17_G141_lightcurve_test_data.txt"*

The star and grating can then be set once in the config section '[setup]', while the full filename needs to be added in 
the respective stellar and planetary parameters section, with a placeholder for the grating name.  
*E.g.: "W17_${setup:grating}_lightcurve_test_data.txt"*


### The Systematic Model Grid
<img src="Systematic_model_tabel.png" align="left" />
This table shows the functional form of the systematic models as presented in Wakeford et al. (2016). Each check mark shows which of the parameters are thawed in the model and fit to the data in combination. The grid contains corrections for a linear trend in time across the whole observation, corrections for thermal variations on the time scale of a HST orbit around the Earth, and positional shifts of the observed spectrum on the detector.



## About this repository

### Contributing and code of conduct

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines, and the process for submitting issues and pull requests to us.
Please also see our [CODE OF CONDUCT](CODE_OF_CONDUCT.md).

### Authors

* **Hannah R. Wakeford** - *Method author* - [@hrwakeford](https://github.com/hrwakeford)
* **Iva Laginja** - *Turning the code into a functional Python repository* - [@ivalaginja](https://github.com/ivalaginja)
* **Matthew Hill** - *Translation from IDL to Python* - [@mattjhill](https://github.com/mattjhill)

### License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.txt) file for details.

### Acknowledgments

* Tom J. Wilson for statistical testing of the code
* Matthew Hill for a functional translation from IDL to Python
* Iva Laginja for finding `Sherpa`, making the clunky `mpfit` dispensable
* The [`Sherpa` team](https://github.com/sherpa/sherpa), providing a fantastic package and answering fast to GitHub issues
* This work is  based  on  observations  made  with  the  NASA/ESA Hubble Space Telescope, HST-GO-14918, that were obtained at the Space Telescope Science Institute, which isoperated by the Association of Universities for Research in Astronomy, Inc.  


<!-- MARKDOWN LINKS & IMAGES -->
[license-shield]: https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square
[license-url]: https://choosealicense.com/licenses/mit
[python-version-url]: https://img.shields.io/badge/Python-3.6-green.svg?style=flat
