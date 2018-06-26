# HST Marginalization

This code performs Levenberg-Marquardt least-squares minimization across a grid of stochastic systematic models to produce marginalised transit parameters given a WFC3 G141 lightcurve for a specified wavelength range. 

This code follows the method outlined in Wakeford, et al. (2016, ApJ, 819, 1), using marginalisation across a stochastic grid of models.
The program makes use of the analytic transit model in Mandel & Agol (2002, ApJ Letters, 580, L171-175) and Lavenberg-Markwardt least squares minimisation using the IDL routine MPFIT (Markwardt, 2009, Book:Astronomical Data Analysis Software and Systems XVIII, 411, 251, Astronomical Society of the Pacific Conference Series). 
Here a 4-parameter limb darkening law is used as outlined in Claret, 2010 and Sing et al. 2010.

#######################################
Current instructions to make stuff run:


CONFIGURATION FILE:

The main configuration file is config.ini, which holds all of your simulation paramers. This file,
however, is version controlled, and the paths to local directories will get messed up if you push this
file. This is why config.ini is supposed to be a TEMPLATE. In order to make it work for you,
use config_local.ini to set all your parametere, since it will override the config.ini. Make sure you tell your version control system to ignore config_local.ini!
