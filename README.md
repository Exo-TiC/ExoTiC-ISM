<!-- PROJECT SHIELDS -->
[![MIT License][license-shield]][license-url]


# HST marginalization - NEWNAME

This code performs Levenberg-Marquardt least-squares minimization across a grid of stochastic systematic models to produce marginalized transit parameters given a lightcurve for a specified wavelength range.

This was developed and tested for data from Wide Field Camera 3 (WFC3) on the Hubble Space Telescope (HST), specifically with the G141 grid, as published in Wakeford et al. (2016, ApJ, 819, 1). Future work includes plans to extend this to other WFC3 grids, STIS data, and eventually data from the James Webb Space Telescope (JWST).

This code follows the method outlined in Wakeford, et al. (2016), using marginalization across a stochastic grid of models. The program makes use of the analytic transit model in Mandel & Agol (2002, ApJ Letters, 580, L171-175) and a Levenberg-Marquardt least squares minimization using [Sherpa](https://sherpa.readthedocs.io/en/latest/), a Python package for modeling and fitting data. The model uses a 4-parameter limb darkening law, as outlined in Claret (2010) and Sing et al. (2010).

This package was built from the original IDL code used for the analysis in Wakeford et al. (2016), initially translated by Matthew Hill and then further adapted and transformed into a full astronomy Python package by Iva Laginja.

## Getting Started

### Prerequisites

What things you need to install the software and how to install them

```
Give examples
```

### Configuration file

The main configuration file is config.ini, which holds all of your simulation paramers. This file,
however, is version controlled, and the paths to local directories will get messed up if you push this
file. This is why config.ini is supposed to be a TEMPLATE. In order to make it work for you,
use config_local.ini to set all your parametere, since it will override the config.ini. Make sure you tell your version control system to ignore config_local.ini!

### Output data

Where your data will be saved.

### Minimum working example

A step by step series of examples that tell you how to get a development env running

Say what the step will be

```
Give the example
```

And repeat

```
until finished
```

End with an example of getting some data out of the system or using it for a little demo

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