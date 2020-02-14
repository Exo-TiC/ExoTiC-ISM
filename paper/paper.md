---
title: 'ExoTiC-ISM: A Python package for marginalised transit parameters across a grid of systematic instrument models'
tags:
  - Python
  - astronomy
  - exoplanets
  - transit spectroscopy
  - marginalisation
  - instrument systematics
authors:
  - name: Iva Laginja
    orcid: 0000-0003-1783-5023
    affiliation: "1, 2"
  - name: Hannah R. Wakeford
    orcid: 0000-0003-4328-3867
    affiliation: "3"
affiliations:
 - name: Space Telescope Science Institute, Baltimore, USA
   index: 1
 - name: Office national d’études et de recherches aérospatiales, Paris, France
   index: 2
 - name: School of Physics, University of Bristol, HH Wills Physics Laboratory, Tyndall Avenue, Bristol BS8 1TL, UK
date: 13 February 2020
bibliography: paper.bib

---

# Science background

The scientific context for the Python package presented herein is the characterization of exoplanet atmospheres. 
There has been a slew of detections of planets outside our own solar system over the past two decades and several 
characterization methods can be used to determine their chemical compositions. One of them is transit spectroscopy. 
With this technique, astronomers measure the star light passing through an exoplanet's atmosphere while it is 
transiting in front of its host star. Imprinted on this light are the absorption signatures of different 
materials - atoms and molecules in the gas phase, or solid or liquid aerosols - in the transiting planet's atmosphere. 
Using a spectrograph the flux is recorded as a function of wavelength, allowing them to construct 
absorption/transmission spectra, with the goal to identify the chemical composition of the atmosphere.

A majority of the exoplanets studied via transmission spectroscopy are close-in, on several day orbits around their 
stars, giant Jupiter- or Neptune-sized worlds. For these giant close-in exoplanets the most dominant source of 
absorption will be from water vapour, which is expected to be well mixed throughout their atmosphere. H$_2$O has 
strong absorption in the near-infrared (IR) with broad peaks at 0.9, 1.4, 1.9, and 2.7\,$\mu$m. However, these 
absorption features cannot be measured from the ground as the Earth's atmosphere, filled with water vapour, gets in 
the way. To measure H$_2$O in the atmospheres of exoplanets, astronomers use the Hubble Space Telescope's Wide Field 
Camera 3 (HST WFC3) infrared capabilities to detect the absorption signatures of H$_2$O at 0.9\,$\mu$m with the G102, 
grism and 1.4\,$\mu$m with the G141 grism [e.g. @kreidberg2015; @sing2016; @wakeford2017; @wakeford2018; @spake2018].

# Package functionality

``ExoTiC-ISM`` (Exoplanet Timeseries Characterisation - Instrument Systematic Marginalisation) is a Python package that 
computes the transit depth from a timeseries lightcurve, while sampling a grid of pseudo-stochastic models to account 
for instrument based systematics that may impact the measurement, following the method proposed by @gibson2014. The 
instrument systematic grid is composed of a series of 49  polynomial functions that are specifically designed to 
account for systematics associated with the detectors on HST WFC3 [@wakeford2016], however, can be adapted to other 
instruments.
The package performs a Levenberg-Marquardt least-squares minimization across all systematic models with the 
Sherpa package [@sherpa.v4.11.0] for modeling and fitting data, and then uses the resulting Akaike Information 
Criterion (AIC) to calculate each model’s evidence (marginal likelihood) and normalised weight. The final transit 
depth and other transit parameters selected to be fit (e.g., inclination, a/R$_*$, center of transit time) are then 
calculated using the weights by marginalising over the fit parameters using each systematic model. This can then be 
performed for each lightcurve constructed at each wavelength from the measured spectrum, resulting in the measured 
transmission spectrum of the exoplanet. This method is different from evaluating each systematic model independently 
and selecting the ``best'' one purely by minimising the scatter of its residuals as that would not include a 
penalisation for increased model complexity nor information from similarly likely systematic corrections. As the 
authors of the original method paper state [@wakeford2016]: “The use of marginalisation 
allows for transparent interpretation and understanding of the instrument and the impact of each systematic [model] 
evaluated statistically for each data set, expanding the ability to make true and comprehensive comparisons between 
exoplanet atmospheres.”

``ExoTiC-ISM`` is written in Python and makes use of the packages numpy [@numpy1; @numpy2], astropy 
[@astropy:2013; astropy:2018], pandas [@pandas] as well as some custom functions, like an implementation of the 
transit function by @mandel2002 and a 4-parameter limb darkening law as outlined in @claret2000 and @sing2010. The 
original code was written in IDL, which was used to publish marginalised transit parameters for five different 
exoplanets [@wakeford2016] observed in the IR with the G141 grism on HST's WFC3. The ``ExoTiC-SIM`` package described 
in this paper implements a marginalisation for that same grism and extends its functionality to the G102 grism, which 
uses the same grid of systematic models [see results by @wakeford2017; @wakeford2018}]. The development in Python and 
hosting the repository on GitHub will facilitate the usage of the package by researchers, as well as further 
functional development.

While its current capabilities are limited to WFC3 data taken with the G141 and G102 grism, the package’s 
functionality will be extended to the UVIS G280 grism and the G430L and G750L gratings of the Space Telescope 
Imaging Spectrograph (STIS) on HST. This will lay the groundwork for the envisioned future extension to implement 
systematic grids for select instruments on the James Webb Space Telescope (JWST) and obtain robust transit spectra 
for JWST data.

# Acknowledgements

The authors would like to acknowledge Matthew Hill who translated the first part of the IDL version of this code to 
Python. We also thank the Sherpa team for their fast and detailed responses to questions we had during the 
implementation of their package. This work is based on observations made with the NASA/ESA Hubble Space Telescope, 
HST-GO-14918, that were obtained at the Space Telescope Science Institute, which is operated by the Association of 
Universities for Research in Astronomy, Inc.

# References