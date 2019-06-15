<!-- PROJECT SHIELDS -->
[![MIT License][license-shield]][license-url]
![Python version][python-version-url]


# HST marginalization - NEWNAME

This code performs Levenberg-Marquardt least-squares minimization across a grid of stochastic systematic models to produce marginalized transit parameters given a lightcurve for a specified wavelength range.

This was developed and tested for data from Wide Field Camera 3 (WFC3) on the Hubble Space Telescope (HST), specifically with the G141 spectroscopic grism, as published in Wakeford et al. (2016, ApJ, 819, 1). Future work includes plans to extend this to other WFC3 grids, STIS data, and eventually data from the James Webb Space Telescope (JWST).

This code follows the method outlined in Wakeford, et al. (2016), using marginalization across a stochastic grid of models. The program makes use of the analytic transit model in Mandel & Agol (2002, ApJ Letters, 580, L171-175) and a Levenberg-Marquardt least squares minimization using [Sherpa](https://sherpa.readthedocs.io/en/latest/), a Python package for modeling and fitting data. The transit model uses a 4-parameter limb darkening law, as outlined in Claret (2010) and Sing et al. (2010).

This package was built from the original IDL code used for the analysis in Wakeford et al. (2016), initially translated by Matthew Hill and then further adapted and transformed into a full astronomy Python package by Iva Laginja.

Note how this is not an installable package, but you will  always need to clone it if you want to work with it.

## Getting Started

###  Quickstart

This is not an installable package, so you will  always need to clone it if you want to work with it.

This section will you give all the necessary terminal commands to go from opening our GitHub page in the browser to having 
reduced results on your local machine. For a more thorough description of the individual steps, please continue to the section 
**Prerequisites** and beyond.

We assume that you have `conda` and `git` installed.

- Create the `hstmarg` environment:  
```$ conda env create --file environment.yml```

- Navigate to the directory you want to clone the repository  into:  
```$ cd /User/YourUser/repos/```

- Clone the repository:  
```$ git clone https://github.com/hrwakeford/HST_Marginalization.git```

- Copy the file `config.ini`, name the copy `config_local.ini` and add the line `config_local.ini` into your `.gitignore`.

- Open your local configfile `config_loca.ini` and edit the entries `[data_paths][local_path]` to point to your local repo clone, e.g.:  
```ini
[data_paths]
local_path = /Users/YourUser/repos/HST_Marginalization
```

- In the same file, define with `[data_paths][output_path]` where your output data should be saved to, e.g.:  
```ini
[data_paths]
...
output_path = /Users/YourUser/<path-to-data>
```

- Navigate to inside the actual package:  
```$ cd HST_python```

- Run the marginalization on the demo data from the template:  
```$ python marginalization.py```

The script takes a short while to run and will output messages to the terminal and save the final data to the path you 
specified under `[data_paths][output_path]` in your `config_local.ini`!

### Prerequisites

We highly recommend the usage of the package and environment manager [Conda](https://docs.conda.io/projects/conda/en/latest/index.html), 
which is free and runs on Windows, macOS and Linux. We have included an [environment](environment.yml) file in our repository 
from which you can directly build a new conda environment in which we have tested our package. We developed and tested our 
 package with **Python 3.6.8** in **conda 4.6.7**. 
 
 Run

```
conda env create --file environment.yml
```

to build the environment, or optionally

```
conda env create --name <myEnvName> --file environment.yml
```

to give the environment your own name.

### Configuration file

The main configuration file is config.ini, which holds all of your simulation paramers. This specific file,
however, is version controlled, and the paths to local directories will get messed up if you push or pull this
file; you might also lose the changes you made to the parameters. This is why config.ini is supposed to be used as a **TEMPLATE**.

In order to make it work for you, copy `config.ini` and rename the copy to `config_local.ini`. In this **local configfile**, 
you can set all your parameters, and it will override the config.ini at runtime. **Make sure you add `config_local.ini` to 
your `.gitignore` file!**

### Output data

The relevant data files and plots from your run will be saved to the directory you specify under **`output_path`** in your 
local configfile. *This data will be overwritten with every new run*, so make sure to move  or rename results you want to 
keep permanently.

### Changing data or the parameters

We provide demo data for the exoplanet WASP-17b, which is one of the datasets analyzed in Wakeford et al. (2016).
Currently we only support the marginalization of WFC3/G141 datasets. If you want to perform the marginalization on a different 
transit dataset, you have to add it to the data folder and update the planetary parameters in your local configfile. 

## Contributing

We still need to create this file, but once it's there:  
Please read [CONTRIBUTING.md]() for details on our code of conduct, and the process for submitting pull requests to us.

## Authors

* **Hannah R. Wakeford** - *Method author* - [@hrwakeford](https://github.com/hrwakeford)
* **Iva Laginja** - *Upgrades and builds leading up to release 1.0.0* - [@ivalaginja](https://github.com/ivalaginja)
* **Matthew Hill** - *Translation from IDL to Python* - [@mattjhill](https://github.com/mattjhill)

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.txt) file for details

## Acknowledgments

* Matthew Hill for a functional translation from IDL to Python
* Iva Laginja for finding `Sherpa`, making the clunky `mpfit` dispensable
* The [`Sherpa` team](https://github.com/sherpa/sherpa), providing a fantastic package and answering fast to GitHub issues


<!-- MARKDOWN LINKS & IMAGES -->
[license-shield]: https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square
[license-url]: https://choosealicense.com/licenses/mit
[python-version-url]: https://img.shields.io/badge/Python-3.6,-green.svg?style=flat