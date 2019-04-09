"""
This code is based on Hannah Wakeford's IDL code for lightcurve extraction with marginalization over a set of systematic models.
The original IDL scipts used are
G141_lightcurve_circle.pro - the translation of this code is in the G141_lightcurve_circle() function
W17_lightcurve_test.pro - the translation of this code is in the main() function

IDL's WHERE function returns -1 if nothing is found vs python returning an empty array. There are cases where this
is important and is taken into account in the occultation functions.

Running python G141_lightcurve_circle.py from the command line will execute the main() function.
The code has only been tested significantly up to the first attempt at fitting the transit models, even that may contain
yet to be discovered bugs. This point is marked in the code.  Everything after that point was a best attempt at
quick translation from IDL. Running the code end to end does NOT produce consistent results with the IDL code so there
are definitely bugs somewhere.

The python code uses a python translation of the IDL MPFIT library instead of built LM fitters because for some reason
neither the script least_squares method, the Astropy wrapper, or the lmfit package find the same minimum as the IDL code.
The python translation of MPFIT is consistent with the IDL code. In theory, all of these packages use the same method,
so there may be some tuning parameters that need to be adjusted to agree with MPFIT (error tolerance, etc.).
The python translation of mpfit (mpfit.py) comes from;
https://github.com/scottransom/presto/blob/master/lib/python/mpfit.py

limb_darkening.py contains a python translation of the 3D limb darkening code in the original IDL. It uses Astropy
for fitting the models. Again, the two are not exactly consistent but in this case the difference is small (good to
about 3 decimals).

Initial translation of Python to IDL was done by Matthew Hill (mhill92@gmail).
Continued by Iva Laginja (laginja.iva@gmail.com).
"""

import numpy as np
import os
import time
import sys
import matplotlib.pyplot as plt
from astropy import stats
from shutil import copy

from config import CONFIG_INI
from mpfit import mpfit
#from mgefit.cap_mpfit import mpfit
#from presto_mpfit import mpfit
from limb_darkening import limb_dark_fit
import hstmarg_retired as hstmarg


def G141_lightcurve_circle(x, y, err, sh, wavelength, outDir, run_name, plotting=True):
    """
    Produce marginalized transit parameters from WFC3 G141 lightcurve for specified wavelength range.

    Perform Levenberg-Marquardt least-squares minimization across a grid of stochastic systematic models to produce
    marginalised transit parameters given a WFC3 G141 lightcurve for a specified wavelength range.

    AUTHOR:
    Hannah R. Wakeford,
    stellarplanet@gmail.com

    CITATIONS:
    This procedure follows the method outlined in Wakeford, et al. (2016, ApJ, 819, 1), using marginalisation across a
    stochastic grid of models. The program makes use of the analytic transit model in Mandel & Agol (2002, ApJ Letters,
    580, L171-175) and Lavenberg-Markwardt least squares minimisation using the IDL routine MPFIT (Markwardt, 2009,
    Book:Astronomical Data Analysis Software and Systems XVIII, 411, 251, Astronomical Society of the Pacific
    Conference Series).
    Here, a 4-parameter limb darkening law is used as outlined in Claret, 2010 and Sing et al. 2010.

    MAJOR PROGRAMS INCLUDED IN THIS ROUTINE:
    - LIMB-DARKENING (from limb_darkening.py)
        This requires the G141.WFC3.sensitivity.sav file, template.sav, kuruczlist.sav, and the kurucz folder with all
        models, as well as the 3D models in the folder 3DGrid.
    - MANDEL & AGOL (2002) transit model (occultnl.pro/.py)
    - GRID OF SYSTEMATIC MODELS for WFC3 to test against the data (hstmarg.wfc3_systematic_model_grid_selection() )
    - IMPACT PARAMETER calculated if given an eccentricity (tap_transite2.pro)

    :param img_date: time array
    :param y: array of normalised flux values equal to the length of the x array
    :param err: array of error values corresponding to the flux values in y
    :param sh: array corresponding to the shift in wavelength position on the detector throughout the visit. (same length as x, y and err)
    :param data_params: priors for each parameter used in the fit passed in an array of the form
        data_params = [rl, epoch, inclin, MsMpR, ecc, omega, Per, FeH, Teff, logg]
        - rl: transit depth (Rp/R*)
        - epoch: center of transit time (in MJD)
        - inclin: inclination of the planetary orbit
        - MsMpR: density of the system where MsMpR = (Ms+Mp)/(R*^3D0) this can also be calculated from the a/R* following
               constant1 = (G*Per*Per/(4*!pi*!pi))^(1/3) -> MsMpR = (a_Rs/constant1)^3
        - ecc: eccentricity of the system
        - omega: omega of the system (degrees)
        - Per: Period of the planet in days
        - FeH: Stellar metallicity - limited ranges available
        - Teff: Stellar temperature - for 1D models: steps of 250 starting at 3500 and ending at 6500
        - logg: stellar gravity - depends on whether 1D or 3D limb darkening models are used
    :param wavelength: array of wavelengths covered to compute y
    :param grid_selection: either one from 'fix_time', 'fit_time', 'fit_inclin', 'fit_msmpr' or 'fit_ecc'
    :param out_folder: string of folder path to save the data to, e.g. '/Volumes/DATA1/user/HST/Planet/sav_file/'
    :param run_name: string of the individual run name, e.g. 'whitelight', or 'bin1', or '115-120micron'
    :param plotting: bool, default=True; whether or not interactive plots should be shown
    :return:
    """

    print(
        'Welcome to the Wakeford WFC3 light curve analysis pipeline. We will now compute the evidence associated with'
        '50 systematic models to calculate the desired lightcurve parameters. This should only take a few minutes'
        'Please hold.')

    # Copy the config.ini to the experiment folder.
    #copy(os.path.join('config_local.ini'), outDir)

    # READ THE CONSTANTS
    Gr = CONFIG_INI.getfloat('constants', 'big_G')
    day_to_sec = CONFIG_INI.getfloat('constants', 'dtosec')
    HST_period = CONFIG_INI.getfloat('constants', 'HST_period')

    # We want to keep the raw data as is, so we generate helper arrays that will get changed from model to model
    img_date = x    # time array
    img_flux = y    # flux array
    flux0 = img_flux[0]   # first flux data point
    T0 = img_date[0]      # first time data point
    nexposure = len(img_date)   # Total number of exposures in the observation

    # READ IN THE PLANET STARTING PARAMETERS
    rl = CONFIG_INI.getfloat('planet_parameters', 'rl')          # Rp/R* estimate
    epoch = CONFIG_INI.getfloat('planet_parameters', 'epoch')    # center of transit time in MJD
    inclin = CONFIG_INI.getfloat('planet_parameters', 'inclin') * ((2 * np.pi) / 360)   # inclination, converting it to radians
    ecc = CONFIG_INI.getfloat('planet_parameters', 'ecc')                            # eccentricity
    omega = CONFIG_INI.getfloat('planet_parameters', 'omega') * ((2 * np.pi) / 360)    # orbital omega, converting it to radians
    Per = CONFIG_INI.getfloat('planet_parameters', 'Per') * day_to_sec               # period in seconds

    constant1 = ((Gr * np.square(Per)) / (4 * np.square(np.pi))) ** (1 / 3)
    aor = CONFIG_INI.getfloat('planet_parameters', 'aor')
    MsMpR = (aor / constant1) ** 3.                          # density of the system

    # SET THE STARTING PARAMETERS FOR THE SYSTEMATIC MODELS
    m_fac = 0.0  # Linear Slope
    HSTP1 = 0.0  # Correct HST orbital phase
    HSTP2 = 0.0  # Correct HST orbital phase^2
    HSTP3 = 0.0  # Correct HST orbital phase^3
    HSTP4 = 0.0  # Correct HST orbital phase^4
    xshift1 = 0.0  # X-shift in wavelength
    xshift2 = 0.0  # X-shift in wavelength^2
    xshift3 = 0.0  # X-shift in wavelength^3
    xshift4 = 0.0  # X-shift in wavelength^4

    # =======================
    # LIMB DARKENING
    # NEW: Implement a suggestion for the user to use 3D if his parameters match the options available in the 3D models

    M_H = CONFIG_INI.getfloat('limb_darkening', 'metallicity')    # metallicity
    Teff = CONFIG_INI.getfloat('limb_darkening', 'Teff')   # effective temperature
    logg = CONFIG_INI.getfloat('limb_darkening', 'logg')   # log(g), gravitation

    # Defien limb darkening directory, which is inside this package
    limbDir = os.path.join('..', 'Limb-darkening')
    ld_model = CONFIG_INI.get('limb_darkening', 'ld_model')
    grat = CONFIG_INI.get('technical_parameters', 'grating')
    uLD, c1, c2, c3, c4, cp1, cp2, cp3, cp4, aLD, bLD = limb_dark_fit(grat, wavelength, M_H, Teff, logg, limbDir,
                                                                      ld_model)
    # =======================

    # PLACE ALL THE PRIORS IN AN ARRAY
    # p0 =        [0,    1,     2,      3,     4,    5,    6,    7,  8,  9,  10, 11, 12,  13,    14,    15,    16,    17,     18,      19,      20,      21   ]
    p0 = np.array([rl, flux0, epoch, inclin, MsMpR, ecc, omega, Per, T0, c1, c2, c3, c4, m_fac, HSTP1, HSTP2, HSTP3, HSTP4, xshift1, xshift2, xshift3, xshift4])

    # Create an array with the names of the priors
    p0_names = np.array(['rl', 'flux0', 'epoch', 'inclin', 'MsMpR', 'ecc', 'omega', 'Per', 'T0', 'c1', 'c2', 'c3', 'c4',
                         'm_fac', 'HSTP1', 'HSTP2', 'HSTP3', 'HSTP4', 'xshift1', 'xshift2', 'xshift3', 'xshift4'])

    # Create a dictionary for easier use in calculations
    p0_dict = {key: val for key, val in zip(p0_names, p0)}

    # SELECT THE SYSTEMATIC GRID OF MODELS TO USE
    # 1 in the grid means the parameter is fixed, 0 means it is free
    grid_selection = CONFIG_INI.get('technical_parameters', 'grid_selection')
    grid = hstmarg.wfc3_systematic_model_grid_selection(grid_selection)
    nsys, nparams = grid.shape   # nsys = number of systematic models, nparams = number of parameters

    #  SET UP THE ARRAYS

    # save arrays for the first step through to get the err inflation
    w_scatter = np.zeros(nsys)
    w_params = np.zeros((nsys, nparams))   # p0 parameters, but for all the systems in one single array, so that we can acces each one of the individually during the second fit

    #################################
    #           FIRST FIT           #
    #################################

    print('\n 1ST FIT \n')
    print(
        'The first run through the data for each of the WFC3 stochastic models outlined in Table 2 of Wakeford et '
        'al. (2016) is now being preformed. Using this fit we will scale the uncertainties you input to incorporate '
        'the inherent scatter in the data for each model.')

    # Loop over all systems (= parameter combinations)
    for s in range(nsys):
        print('\n################################')
        print('SYSTEMATIC MODEL {} of {}'.format(s+1, nsys))
        systematics = grid[s, :]
        print('Systematics - fixed and free parameters:')
        print_dict = {name: fix for name, fix in zip(p0_names, systematics)}   # this is just for printing purposes
        print(print_dict)
        print(systematics)
        print('  ')

        # Displaying img_date in terms of HST PHASE, on an interval between -0.5 and 0.5
        HSTphase = hstmarg.phase_calc(img_date, p0_dict['T0'], HST_period)

        # Displaying img_date in terms of PLANET PHASE, on interval between -0.5 and 0.5
        phase = hstmarg.phase_calc(img_date, p0_dict['epoch'], p0_dict['Per']/day_to_sec)


        ###############
        # MPFIT - ONE #
        ###############

        # Create two dictionaries in which each parameter in p0 gets some extra parameters assigned, which we then feed
        # into mpfit. This dictionary has the sole purpose of preparing the input data for mpfit in such a way that
        # it works.
        parinfo = []
        for i, value in enumerate(p0):
            info = {'value': 0., 'fixed': 0, 'limited': [0, 0], 'limits': [0., 0.]}
            info['value'] = value
            info['fixed'] = systematics[i]
            parinfo.append(info)
        fa = {'x': img_date, 'y': img_flux, 'err': err, 'sh': sh}

        print('\nSTART MPFIT\n')
        mpfit_result = mpfit(hstmarg.transit_circle, functkw=fa, parinfo=parinfo, quiet=True)

        print('\nTHIS ROUND OF MPFIT IS DONE\n')

        # Count free parameters by figuring out how many zeros we have in the current systematics
        nfree = sum([not p['fixed'] for p in parinfo])

        # The python mpfit does not populate the covariance matrix correctly so mpfit_result.perror is not correct
        # the mpfit_result.covar is filled sequentially by row with the values of only free parameters, this works if
        # all parameters are free but not if some are kept fixed.  The code below should work to get the proper error
        # values i.e. what should be the diagonals of the covariance.

        pcerror = mpfit_result.perror  # this is how it should be done if it was right
        """
        pcerror = np.zeros_like(mpfit_result.perror)
        covar_res = np.zeros(nfree)
        covar_res[:nfree] = np.sqrt(
            np.diag(mpfit_result.covar.flatten()[:nfree ** 2].reshape(nfree, nfree)))  # this might work...

        ind = np.where(systematics == 0)
        pcerror[ind] = covar_res
        """


        # Redefine all of the parameters given the MPFIT output
        w_params[s, :] = mpfit_result.params
        # Populate parameters with fits results
        p0_fit = w_params[s, :]
        # Recreate the dictionary
        p0_fit_dict = {key: val for key, val in zip(p0_names, p0_fit)}


        # Populate some errors from pcerror array
        # pcerror = [rl_err, flux0_err, epoch_err, inclin_err, msmpr_err, ecc_err, omega_err, per_err, T0_err,
        #           c1_err, c2_err, c3_err, c4_err, m_err, hst1_err, hst2_err, hst3_err, hst4_err, sh1_err, sh2_err,
        #           sh3_err, sh4_err]
        rl_err = pcerror[0]
        print('\nTRANSIT DEPTH rl in model {} of {} = {} +/- {}, centered at  {}'.format(s+1, nsys, p0_fit_dict['rl'], rl_err, p0_fit_dict['epoch']))


        # OUTPUTS
        # Re-Calculate each of the arrays dependent on the output parameters
        HSTphase = hstmarg.phase_calc(img_date, p0_fit_dict['T0'], HST_period)
        phase = hstmarg.phase_calc(img_date, p0_fit_dict['epoch'], p0_fit_dict['Per']/day_to_sec)


        # ...........................................
        # TRANSIT MODEL fit to the data
        # Calculate the impact parameter based on the eccentricity function
        b0 = hstmarg.impact_param(p0_fit_dict['Per'], p0_fit_dict['MsMpR'], phase, p0_fit_dict['inclin'])

        mulimb01, mulimbf1 = hstmarg.occultnl(p0_fit_dict['rl'], p0_fit_dict['c1'], p0_fit_dict['c2'], p0_fit_dict['c3'], p0_fit_dict['c4'], b0)

        systematic_model = hstmarg.sys_model(phase, HSTphase, sh, p0_fit_dict['m_fac'], p0_fit_dict['HSTP1'], p0_fit_dict['HSTP2'], p0_fit_dict['HSTP3'],
                                             p0_fit_dict['HSTP4'], p0_fit_dict['xshift1'], p0_fit_dict['xshift2'],
                                             p0_fit_dict['xshift3'], p0_fit_dict['xshift4'])

        # Calculate final form of the model fit
        w_model = mulimb01 * p0_fit_dict['flux0'] * systematic_model   # see Wakeford et al. 2016, Eq. 1
        # Calculate the residuals
        w_residuals = (img_flux - w_model) / p0_fit_dict['flux0']
        # Calculate more stuff
        corrected_data = img_flux / (p0_fit_dict['flux0'] * systematic_model)
        w_scatter[s] = np.std(w_residuals)
        print('Scatter on the residuals = {}'.format(w_scatter[s]))   # this result is rather different to IDL result

    np.savez(os.path.join(outDir, 'run1_scatter_'+run_name), w_scatter=w_scatter, w_params=w_params)


    ################################
    #          SECOND FIT          #
    ################################

    print('..........................................')
    print('\n 2ND FIT \n')
    print('Each systematic model will now be re-fit with the previously determined parameters serving as the new starting points.')

    # Initializing arrays for each systematic model, which we will save once we got through all systems with two fits.
    sys_stats = np.zeros((nsys, 5))                 # stats       # NEW: why 5? (trying to get rid of hard coded things)
    sys_date = np.zeros((nsys, nexposure))          # img_date
    sys_phase = np.zeros((nsys, nexposure))         # phase
    sys_rawflux = np.zeros((nsys, nexposure))       # raw lightcurve flux
    sys_rawflux_err = np.zeros((nsys, nexposure))   # raw lightcurve flux error
    sys_flux = np.zeros((nsys, nexposure))          # corrected lightcurve flux
    sys_flux_err = np.zeros((nsys, nexposure))      # corrected lightcurve flux error
    sys_residuals = np.zeros((nsys, nexposure))     # residuals
    sys_model = np.zeros((nsys, 4000))              # smooth model       # NEW: why 4000?
    sys_model_phase = np.zeros((nsys, 4000))        # smooth phase       # NEW: why 4000?
    sys_systematic_model = np.zeros((nsys, nexposure))  # systematic model
    sys_params = np.zeros((nsys, nparams))          # parameters
    sys_params_err = np.zeros((nsys, nparams))      # parameter errors
    sys_depth = np.zeros(nsys)                      # depth
    sys_depth_err = np.zeros(nsys)                  # depth error
    sys_epoch = np.zeros(nsys)                      # transit time
    sys_epoch_err = np.zeros(nsys)                  # transit time error
    sys_evidenceAIC = np.zeros(nsys)                # evidence AIC
    sys_evidenceBIC = np.zeros(nsys)                # evidence BIC

    for s in range(nsys):
        print('\n################################')
        print('SYSTEMATIC MODEL {} of {}'.format(s+1, nsys))
        systematics = grid[s, :]
        print_dict = {name: fix for name, fix in zip(p0_names, systematics)}
        print(print_dict)
        print(systematics)
        print('  ')

        # Rescale the err array by the standard deviation of the residuals from the fit.
        err *= (1.0 - w_scatter[s])   # w_scatter are residuals
        # Reset the arrays and start again. This is to ensure that we reached a minimum in the chi-squared space.
        p0 = w_params[s, :]   # populate with results from first run FOR THE SYSTEM nsys WE'RE CURRENTLY IN
        # Recreate the dictionary
        p0_dict = {key: val for key, val in zip(p0_names, p0)}

        # HST Phase
        HSTphase = hstmarg.phase_calc(img_date, p0_dict['T0'], HST_period)
        phase = hstmarg.phase_calc(img_date, p0_dict['epoch'], p0_dict['Per']/day_to_sec)

        ###############
        # MPFIT - TWO #
        ###############

        parinfo = []

        for i, value in enumerate(p0):
            info = {'value': 0., 'fixed': 0, 'limited': [0, 0], 'limits': [0., 0.]}
            info['value'] = value
            info['fixed'] = systematics[i]
            parinfo.append(info)

        fa = {'x': img_date, 'y': img_flux, 'err': err, 'sh': sh}
        mpfit_result = mpfit(hstmarg.transit_circle, functkw=fa, parinfo=parinfo, quiet=1)
        nfree = sum([not p['fixed'] for p in parinfo])

        pcerror = mpfit_result.perror  # this is how it should be done if it was right
        """
        # The python mpfit does not populate the covariance matrix correctly so m.perror is not correct
        ind = np.where(systematics == 0)

        # pcerror = np.zeros_like(mpfit_result.perror)
        # covar_res = np.zeros(nfree)
        # covar_res = np.sqrt(
        #     np.diag(mpfit_result.covar.flatten()[:nfree ** 2].reshape(nfree, nfree)))  # this might work...

        # pcerror[ind] = covar_res
        """

        # From mpfit define the DOF, BIC, AIC & CHI
        bestnorm = mpfit_result.fnorm  # chi squared of resulting fit
        BIC = bestnorm + nfree * np.log(len(img_date))
        AIC = bestnorm + nfree
        DOF = len(img_date) - sum([p['fixed'] != 1 for p in parinfo])  # nfree
        CHI = bestnorm

        # EVIDENCE BASED on the AIC and BIC
        Npoint = len(img_date)
        sigma_points = np.median(err)

        evidence_BIC = - Npoint * np.log(sigma_points) - 0.5 * Npoint * np.log(2 * np.pi) - 0.5 * BIC
        evidence_AIC = - Npoint * np.log(sigma_points) - 0.5 * Npoint * np.log(2 * np.pi) - 0.5 * AIC

        # Redefine all of the parameters given the MPFIT output
        # Redefine array
        res_sec = mpfit_result.params
        # Recreate the dictionary
        res_sec_dict = {key: val for key, val in zip(p0_names, res_sec)}

        # pcerror = [rl_err, flux0_err, epoch_err, inclin_err, msmpr_err, ecc_err, omega_err, per_err, T0_err,
        #           c1_err, c2_err, c3_err, c4_err, m_err, HSTP1_err, HSTP2_err, HSTP3_err, HSTP4_err, xshift1_err,
        #           xshift2_err, xshift3_err, xshift4_err]
        rl_err = pcerror[0]
        epoch_err = pcerror[2]

        # Recalculate a/R* (actually the constant for it) based on the new MsMpR value which may have been fit in the routine.
        constant1 = (Gr * res_sec_dict['Per'] * res_sec_dict['Per'] / (4 * np.pi * np.pi)) ** (1 / 3.)

        print('\nTRANSIT DEPTH rl in model {} of {} = {} +/- {}     centered at  {}'.format(s+1, nsys, res_sec_dict['rl'], rl_err, res_sec_dict['epoch']))

        # OUTPUTS
        # Re-Calculate each of the arrays dependent on the output parameters for the epoch
        phase = hstmarg.phase_calc(img_date, res_sec_dict['epoch'], res_sec_dict['Per']/day_to_sec)
        HSTphase = hstmarg.phase_calc(img_date, res_sec_dict['T0'], HST_period)

        # ...........................................
        # TRANSIT MODEL fit to the data
        # Calculate the impact parameter based on the eccentricity function
        b0 = hstmarg.impact_param(res_sec_dict['Per'], res_sec_dict['MsMpR'], phase, res_sec_dict['inclin'])

        mulimb01, mulimbf1 = hstmarg.occultnl(res_sec_dict['rl'], res_sec_dict['c1'], res_sec_dict['c2'], res_sec_dict['c3'], res_sec_dict['c4'], b0)

        # ...........................................
        # SMOOTH TRANSIT MODEL across all phase
        # Calculate the impact parameter based on the eccentricity function
        x2 = np.arange(4000) * 0.0001 - 0.2
        b0 = hstmarg.impact_param(res_sec_dict['Per'], res_sec_dict['MsMpR'], x2, res_sec_dict['inclin'])

        mulimb02, mulimbf2 = hstmarg.occultnl(res_sec_dict['rl'], res_sec_dict['c1'], res_sec_dict['c2'], res_sec_dict['c3'], res_sec_dict['c4'], b0)

        systematic_model = hstmarg.sys_model(phase, HSTphase, sh, res_sec_dict['m_fac'], res_sec_dict['HSTP1'], res_sec_dict['HSTP2'],
                                             res_sec_dict['HSTP3'], res_sec_dict['HSTP4'], res_sec_dict['xshift1'], res_sec_dict['xshift2'],
                                             res_sec_dict['xshift3'], res_sec_dict['xshift4'])

        fit_model = mulimb01 * res_sec_dict['flux0'] * systematic_model
        residuals = (img_flux - fit_model) / res_sec_dict['flux0']
        resid_scatter = np.std(w_residuals)
        fit_data = img_flux / (res_sec_dict['flux0'] * systematic_model)
        fit_err = np.copy(err)  # * (1.0 + resid_scatter)

        if plotting:
            plt.figure(2)
            plt.clf()
            plt.scatter(phase, img_flux, s=5)
            plt.plot(x2, mulimb02, 'k')
            plt.errorbar(phase, fit_data, yerr=err, fmt='m.')
            plt.xlim(-0.03, 0.03)
            plt.title('Model ' + str(s+1) + '/' + str(nsys))
            plt.xlabel('Planet Phase')
            plt.ylabel('Data')
            plt.draw()
            plt.pause(0.05)

        # .............................
        # Fill info into arrays to save to file once we iterated through all systems with both fittings.

        sys_stats[s, :] = [AIC, BIC, DOF, CHI, resid_scatter]   # stats
        sys_date[s, :] = img_date                               # input time data (x, date)
        sys_phase[s, :] = phase                                 # phase
        sys_rawflux[s, :] = img_flux                            # raw lightcurve flux
        sys_rawflux_err[s, :] = err
        sys_flux[s, :] = fit_data                               # corrected lightcurve flux
        sys_flux_err[s, :] = fit_err
        sys_residuals[s, :] = residuals                         # residuals
        sys_model[s, :] = mulimb02                              # smooth model
        sys_model_phase[s, :] = x2                              # smooth phase
        sys_systematic_model[s, :] = systematic_model           # systematic model
        sys_params[s, :] = mpfit_result.params                  # parameters
        sys_params_err[s, :] = pcerror                          # parameter errors
        sys_depth[s] = res_sec_dict['rl']                       # depth
        sys_depth_err[s] = rl_err                               # depth error
        sys_epoch[s] = res_sec_dict['epoch']                    # transit time
        sys_epoch_err[s] = epoch_err                            # transit time error
        sys_evidenceAIC[s] = evidence_AIC                       # evidence AIC
        sys_evidenceBIC[s] = evidence_BIC                       # evidence BIC

        print('Another round done')

    # Save to file
    # For details on how to deal with this kind of file, see the notebook "NumpyData.ipynb"
    np.savez(os.path.join(outDir, 'analysis_circle_G141_'+run_name), sys_stats=sys_stats, sys_date=sys_date, sys_phase=sys_phase,
             sys_rawflux=sys_rawflux, sys_rawflux_err=sys_rawflux_err, sys_flux=sys_flux, sys_flux_err=sys_flux_err,
             sys_residuals=sys_residuals, sys_model=sys_model, sys_model_phase=sys_model_phase,
             sys_systematic_model=sys_systematic_model, sys_params=sys_params, sys_params_err=sys_params_err,
             sys_depth=sys_depth, sys_depth_err=sys_depth_err, sys_epoch=sys_epoch, sys_epoch_err=sys_epoch_err,
             sys_evidenceAIC=sys_evidenceAIC, sys_evidenceBIC=sys_evidenceBIC)


    #####################################
    #          MARGINALISATION          #
    #####################################

    a = (np.sort(sys_evidenceAIC))[::-1]
    print('\nTOP 10 SYSTEMATIC MODELS')

    # What is getting printed here?
    print(a[:10])
    # What is getting printed here?
    print(sys_evidenceAIC)

    # REFORMAT all arrays with just positive values
    pos = np.where(sys_evidenceAIC > -500)
    if len(pos) == 0:
        pos = -1
    npos = len(pos[0])   # NOT-REUSED
    # What is getting printed here?
    print('POS positions = {}'.format(pos))

    count_AIC = sys_evidenceAIC[pos]

    count_depth = sys_depth[pos]
    count_depth_err = sys_depth_err[pos]

    count_epoch = sys_epoch[pos]
    count_epoch_err = sys_epoch_err[pos]

    count_residuals = sys_residuals[pos]
    count_date = sys_date[pos]
    count_flux = sys_flux[pos]
    count_flux_err = sys_flux_err[pos]
    count_phase = sys_phase[pos]
    count_model_y = sys_model[pos]
    count_model_x = sys_model_phase[pos]

    beta = np.min(count_AIC)
    w_q = (np.exp(count_AIC - beta)) / np.sum(np.exp(count_AIC - beta))

    n01 = np.where(w_q >= 0.05)
    print('{} models have a weight over 0.1. -> Models:'.format(len(n01), n01, w_q[n01]))
    print('Most likely model is number {} at w_q={}'.format(np.argmax(w_q), np.max(w_q)))

    best_sys = np.max(w_q)

    rl_sdnr = np.zeros(len(w_q))
    for i in range(len(w_q)):
        rl_sdnr[i] = (np.std(count_residuals[:, i]) / np.sqrt(2)) * 1e6
    best_sys = np.argmin(rl_sdnr)

    ### Radius ratio
    marg_rl, marg_rl_err = hstmarg.marginalization(count_depth, count_depth_err, w_q)
    print('Rp/R* = {} +/- {}'.format(marg_rl, marg_rl_err))

    print('SDNR best model = {}'.format(np.std(count_residuals[:, best_sys]) / np.sqrt(2) * 1e6))
    print('SDNR best = {} for model {}'.format(np.min(rl_sdnr), np.argmin(rl_sdnr)))

    if plotting:
        plt.figure(3)
        plt.subplot(3,1,1)
        plt.plot(w_q)
        plt.title('w_q')
        plt.subplot(3,1,2)
        plt.plot(rl_sdnr)
        plt.title('rl_sdnr')
        plt.subplot(3,1,3)
        plt.errorbar(np.arange(1, len(count_depth)+1), count_depth, yerr=count_depth_err, fmt='.')
        plt.title('count_depth')
        plt.draw()
        plt.pause(0.05)

        plt.figure(4)
        plt.subplot(3, 1, 1)
        plt.scatter(sys_phase[0,:], sys_flux[0,:])
        plt.ylim(np.min(sys_flux[0,:]) - 0.001, np.max(sys_flux[0,:]) + 0.001)
        plt.xlabel('sys_phase')
        plt.ylabel('sys_flux')

        plt.subplot(3,1,2)
        plt.scatter(count_phase[best_sys,:], count_flux[best_sys,:])
        plt.plot(count_model_x[best_sys,:], count_model_y[best_sys,:])
        plt.ylim(np.min(count_flux[0,:]) - 0.001, np.max(count_flux[0,:]) + 0.001)
        plt.xlabel('count_phase')
        plt.ylabel('count_flux')

        plt.subplot(3,1,3)
        plt.errorbar(count_phase[best_sys,:], count_residuals[best_sys,:], yerr=count_flux_err[best_sys,:], fmt='.')
        plt.ylim(-1000, 1000)
        plt.xlabel('count_phase')
        plt.ylabel('count_residuals')
        plt.hlines(0.0, xmin=np.min(count_phase[best_sys,:]), xmax=np.max(count_phase[best_sys,:]), colors='r', linestyles='dashed')
        #plt.hlines(0.0 - (rl_sdnr[best_sys] * cut_down), xmin=np.min(count_phase[best_sys,:]), xmax=np.max(count_phase[best_sys,:]), colors='r', linestyles='dotted')
        #plt.hlines(0.0 + (rl_sdnr[best_sys] * cut_down), xmin=np.min(count_phase[best_sys,:]), xmax=np.max(count_phase[best_sys,:]), colors='r', linestyles='dotted')
        plt.draw()
        plt.show()

    ### Center of transit time
    marg_epoch, marg_epoch_err = hstmarg.marginalization(count_epoch, count_epoch_err, w_q)
    print('Epoch = {} +/- {}'.format(marg_epoch, marg_epoch_err))

    ### Inclination in radians
    marg_inclin_rad, marg_inclin_rad_err = hstmarg.marginalization(sys_params[:, 3], sys_params_err[:, 3], w_q)
    print('inc (rads) = {} +/- {}'.format(marg_inclin_rad, marg_inclin_rad_err))

    ### Inclination in degrees
    conv1 = sys_params[:, 3] / (2 * np.pi / 360)
    conv2 = sys_params_err[:, 3] / (2 * np.pi / 360)
    marg_inclin_deg, marg_inclin_deg_err = hstmarg.marginalization(conv1, conv2, w_q)
    print('inc (deg) = {} +/- {}'.format(marg_inclin_deg, marg_inclin_deg_err))

    ### MsMpR
    marg_msmpr, marg_msmpr_err = hstmarg.marginalization(sys_params[:, 4], sys_params_err[:, 4], w_q)
    print('MsMpR = {} +/- {}'.format(marg_msmpr, marg_msmpr_err))

    marg_aors = constant1 * (marg_msmpr ** 0.333)
    marg_aors_err = constant1 * (marg_msmpr_err ** 0.3333) / marg_aors
    print('a/R* = {} +/- {}'.format(marg_aors, marg_aors_err))

    ### Save to file
    # For details on how to deal with this kind of file, see the notebook "NumpyData.ipynb"
    np.savez(os.path.join(outDir, 'analysis_circle_G141_marginalised_'+run_name), w_q=w_q, best_sys=best_sys,
             marg_rl=marg_rl, marg_rl_err=marg_rl_err, marg_epoch=marg_epoch, marg_epoch_err=marg_epoch_err,
             marg_inclin_rad=marg_inclin_rad, marg_inclin_rad_err=marg_inclin_rad_err, marg_inclin_deg=marg_inclin_deg,
             marg_inclin_deg_err=marg_inclin_deg_err, marg_msmpr=marg_msmpr, marg_msmpr_err=marg_msmpr_err,
             marg_aors=marg_aors, marg_aors_err=marg_aors_err, rl_sdnr=rl_sdnr, pos=pos)


if __name__ == '__main__':
    """
    This is a translation of the W17_lightcurve_test.pro
    """

    # Figure out how much time it takes to run this code.
    start_time = time.time()

    localDir = CONFIG_INI.get('data_paths', 'local_path')
    outDir = os.path.join(localDir, CONFIG_INI.get('data_paths', 'output_path'))
    curr_model = CONFIG_INI.get('data_paths', 'current_model')
    dataDir = os.path.join(localDir, os.path.join(localDir, CONFIG_INI.get('data_paths', 'data_path')), curr_model)

    # Read in the txt file for the lightcurve data
    x, y, err, sh = np.loadtxt(os.path.join(dataDir, 'W17_white_lightcurve_test_data.txt'), skiprows=7, unpack=True)
    wavelength = np.loadtxt(os.path.join(dataDir, 'W17_wavelength_test_data.txt'), skiprows=3)

    # What to call the run and whether to turn plotting on
    run_name = CONFIG_INI.get('technical_parameters', 'run_name')
    plotting = CONFIG_INI.getboolean('technical_parameters', 'plotting')

    # Run the main function
    G141_lightcurve_circle(x, y, err, sh, wavelength, outDir, run_name, plotting)

    end_time = time.time()
    print('\nTime it took to run the code:', (end_time-start_time)/60, 'min')

    print("\n--- ALL IS DONE, LET'S GO HOME AND HAVE A DRINK! ---\n")