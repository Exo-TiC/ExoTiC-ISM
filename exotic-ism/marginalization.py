"""
This code is based on Hannah Wakeford's IDL code for lightcurve extraction with marginalization over a set of
systematic models.

Initially, the python code used a python translation of the IDL MPFIT library instead of built LM fitters because for
some reason neither the script least_squares method, the Astropy wrapper, or the lmfit package find the same minimum
as the IDL code.
Using the python version of mpfit showed to be really flaky though, so we ditched all of that and are now using the
fitting package Sherpa.

limb_darkening.py contains a python translation of the 3D limb darkening code in the original IDL. It uses Astropy
for fitting the models.

Initial translation of Python to IDL was done by Matthew Hill (mhill92@gmail).
Continued translation and implementation of Sherpa by Iva Laginja (laginja.iva@gmail.com).
"""

import os
import time
from shutil import copy
import numpy as np
import matplotlib.pyplot as plt
import astropy.units as u
from astropy.constants import G

from sherpa.data import Data1D
from sherpa.optmethods import LevMar
from sherpa.stats import Chi2
from sherpa.fit import Fit
from sherpa.estmethods import Confidence

from config import CONFIG_INI
from limb_darkening import limb_dark_fit
import margmodule as marg


def total_marg(exoplanet, x, y, err, sh, wavelength, outDir, run_name, plotting=True):
    """
    Produce marginalized transit parameters from WFC3 G141 lightcurve for specified wavelength range.

    MAJOR PROGRAMS INCLUDED IN THIS ROUTINE:
    - LIMB-DARKENING (from limb_darkening.py)
        This requires the G141.WFC3.sensitivity.sav file, template.sav, kuruczlist.sav, and the kurucz folder with all
        models, as well as the 3D models in the folder 3DGrid.
    - MANDEL & AGOL (2002) transit model (occultnl.py)
    - GRID OF SYSTEMATIC MODELS for WFC3 to test against the data (marg.wfc3_systematic_model_grid_selection() )

    :param img_date: time array
    :param y: array of normalised flux values equal to the length of the x array
    :param err: array of error values corresponding to the flux values in y
    :param sh: array corresponding to the shift in wavelength position on the detector throughout the visit. (same length as x, y and err)
    :param wavelength: array of wavelengths covered to compute y
    :param outDir: string of folder path to save the data to, e.g. '/Users/MyUser/data/'
    :param run_name: string of the individual run name, e.g. 'whitelight', or 'bin1', or '115-120micron'
    :param plotting: bool, default=True; whether or not interactive plots should be shown
    :return:
    """

    print(
        'Welcome to the Wakeford WFC3 light curve analysis pipeline. We will now compute the evidence associated with'
        '50 systematic models to calculate the desired lightcurve parameters. This should only take a few minutes'
        'Please hold.'
        '\n This is the version using SHERPA for fitting.\n')

    # Copy the config.ini to the experiment folder.
    print('Saving the configfile to outputs folder.')
    copy(os.path.join('config_local.ini'), outDir)

    # READ THE CONSTANTS
    HST_period = CONFIG_INI.getfloat('constants', 'HST_period') * u.d

    # Errors from Hessian matrix in the fit or with 'Confidence' estimation?
    ERRORS = CONFIG_INI.get('technical_parameters', 'errors')

    # We want to keep the raw data as is, so we generate helper arrays that will get changed from model to model
    img_date = x * u.d    # time array
    img_flux = y    # flux array
    flux0 = y[0]   # first flux data point
    tzero = x[0] * u.d      # first time data point
    nexposure = len(img_date)   # Total number of exposures in the observation

    Per = CONFIG_INI.getfloat(exoplanet, 'Per') * u.d    # period, converted to seconds in next line
    Per = Per.to(u.s)

    constant1 = ((G * np.square(Per)) / (4 * np.square(np.pi))) ** (1 / 3)
    aor = CONFIG_INI.getfloat(exoplanet, 'aor')    # this is unitless -> "distance of the planet from the star (meters)/stellar radius (meters)"
    MsMpR = (aor / constant1) ** 3.     # density of the system in kg/m^3 "(Mass of star (kg) + Mass of planet (kg))/(Radius of star (m)^3)"

    # LIMB DARKENING
    M_H = CONFIG_INI.getfloat('limb_darkening', 'metallicity')    # stellar metallicity - limited ranges available
    Teff = CONFIG_INI.getfloat('limb_darkening', 'Teff')   # stellar temperature - for 1D models: steps of 250 starting at 3500 and ending at 6500
    logg = CONFIG_INI.getfloat('limb_darkening', 'logg')   # log(g), stellar gravity - depends on whether 1D or 3D limb darkening models are used

    # Define limb darkening directory, which is inside this package
    limbDir = os.path.join('..', 'Limb-darkening')
    ld_model = CONFIG_INI.get('limb_darkening', 'ld_model')
    grat = CONFIG_INI.get('system_parameters', 'grating')
    _uLD, c1, c2, c3, c4, _cp1, _cp2, _cp3, _cp4, _aLD, _bLD = limb_dark_fit(grat, wavelength, M_H, Teff, logg, limbDir,
                                                                      ld_model)

    # SELECT THE SYSTEMATIC GRID OF MODELS TO USE
    # 1 in the grid means the parameter is fixed, 0 means it is free
    # grid_selection: either one from 'fix_time', 'fit_time', 'fit_inclin', 'fit_msmpr' or 'fit_ecc'
    grid_selection = CONFIG_INI.get('system_parameters', 'grid_selection')
    grid = marg.wfc3_systematic_model_grid_selection(grid_selection)
    nsys, nparams = grid.shape   # nsys = number of systematic models, nparams = number of parameters

    #  SET UP THE ARRAYS
    # save arrays for the first step through to get the err inflation
    w_params = np.zeros((nsys, nparams))   # all parameters, but for all the systems in one single array

    # Parameters for smooth model
    resolution = CONFIG_INI.getfloat('smooth_model', 'resolution')
    half_range = CONFIG_INI.getfloat('smooth_model', 'half_range')

    # Set up the Sherpa data model
    # Instantiate a data object
    tdata = Data1D('Data', x, y, staterror=err)
    print(tdata)

    # Plot the data with Sherpa
    # dplot = DataPlot()
    # dplot.prepare(tdata)
    # dplot.plot()

    # Set up the Sherpa transit model
    tmodel = marg.Transit(tzero, MsMpR, c1, c2, c3, c4, flux0, name="TransitModel", sh=sh)
    print('Starting parameters for transit model:\n')
    print(tmodel)

    # Set up statistics and optimizer
    stat = Chi2()
    opt = LevMar()
    opt.config['epsfcn'] = np.finfo(float).eps

    print('Optimizer used:')
    print(opt)

    # Set up the fit object
    tfit = Fit(tdata, tmodel, stat=stat, method=opt)  # Instantiate fit object
    tfit.estmethod = Confidence()    # Set up error estimator we want.

    #################################
    #           FIRST FIT           #
    #################################
    # This fit just rescales the errors, should talk about it in the docs.

    print('\n 1ST FIT \n')
    print(
        'The first run through the data for each of the WFC3 stochastic models outlined in Table 2 of Wakeford et '
        'al. (2016) is now being preformed. Using this fit we will scale the uncertainties you input to incorporate '
        'the inherent scatter in the data for each model.')

    start_first_fit = time.time()
    # Loop over all systems (= parameter combinations)
    for i, sys in enumerate(grid):

        start_one_first_loop = time.time()

        print('\n################################')
        print('SYSTEMATIC MODEL {} of {}'.format(i+1, nsys))

        print('Systematics - fixed and free parameters:')
        print(sys)
        print('  ')

        # Set up systematics for current run
        for k, select in enumerate(sys):
            if select == 0:
                tmodel.pars[k].thaw()
            elif select == 1:
                tmodel.pars[k].freeze()

        print('\nSTART 1st FIT')
        tres = tfit.fit()  # do the fit
        if not tres.succeeded:
            print(tres.message)
        print('\n1st ROUND OF SHERPA FIT IS DONE\n')

        # Save results of fit
        w_params[i, :] = [par.val for par in tmodel.pars]

        # Calculate the error on rl
        print('Calculating error on rl...')
        if ERRORS == 'hessian':
            calc_errors = np.sqrt(tres.extra_output['covar'].diagonal())
            rl_err = calc_errors[0]
        elif ERRORS == 'confidence':
            calc_errors = tfit.est_errors(parlist=(tmodel.rl,))
            rl_err = max(np.abs(calc_errors.parmaxes[0]), np.abs(calc_errors.parmins[0]))

        print('\nTRANSIT DEPTH rl in model {} of {} = {} +/- {}, centered at {}'.format(i+1, nsys, tmodel.rl.val, rl_err, tmodel.epoch.val))

        # We could extract info from the fit at this point, but since the "real" fit is actually happening in the
        # second round of fitting, there is no need for that.

        # Reset the model parameters to the input parameters
        # Note on resetting: https://sherpa.readthedocs.io/en/latest/models/index.html#resetting-parameter-values
        tmodel.reset()

        # Show how long one iteration takes
        end_one_first_loop = time.time()
        one_loop = end_one_first_loop - start_one_first_loop
        print('This 1st loop took {} sec = {} min'.format(one_loop, one_loop/60))

    end_first_fit = time.time()
    print('First fit of all {} models took {} sec = {} min.'.format(nsys, end_first_fit-start_first_fit, (end_first_fit-start_first_fit)/60))

    ################################
    #          SECOND FIT          #
    ################################

    print('..........................................')
    print('\n 2ND FIT \n')
    print('Each systematic model will now be re-fit with the previously determined parameters serving as the new starting points.')

    # Initializing arrays for each systematic model, which we will save once we got through all systems with two fits.
    sys_stats = np.zeros((nsys, 5))                 # stats

    sys_date = np.zeros((nsys, nexposure))          # img_date
    sys_phase = np.zeros((nsys, nexposure))         # phase
    sys_rawflux = np.zeros((nsys, nexposure))       # raw lightcurve flux
    sys_rawflux_err = np.zeros((nsys, nexposure))   # raw lightcurve flux error
    sys_flux = np.zeros((nsys, nexposure))          # corrected lightcurve flux
    sys_flux_err = np.zeros((nsys, nexposure))      # corrected lightcurve flux error
    sys_residuals = np.zeros((nsys, nexposure))     # residuals
    sys_systematic_model = np.zeros((nsys, nexposure))  # systematic model

    sys_model = np.zeros((nsys, int(2*half_range/resolution)))              # smooth model
    sys_model_phase = np.zeros((nsys, int(2*half_range/resolution)))        # smooth phase

    sys_params = np.zeros((nsys, nparams))          # parameters
    sys_params_err = np.zeros((nsys, nparams))      # parameter errors

    sys_depth = np.zeros(nsys)                      # depth
    sys_depth_err = np.zeros(nsys)                  # depth error
    sys_epoch = np.zeros(nsys)                      # transit time
    sys_epoch_err = np.zeros(nsys)                  # transit time error
    sys_evidenceAIC = np.zeros(nsys)                # evidence AIC
    sys_evidenceBIC = np.zeros(nsys)                # evidence BIC

    start_second_fit = time.time()
    for i, sys in enumerate(grid):
        print('\n################################')
        print('SYSTEMATIC MODEL {} of {}'.format(i+1, nsys))
        print(sys)
        print('  ')

        # The errors at this point got rescaled to unity chi squared in the previous fit and were not reset
        # by model.reset()

        # Set up systematics for current run
        for k, select in enumerate(sys):
            if select == 0:
                tmodel.pars[k].thaw()
            elif select == 1:
                tmodel.pars[k].freeze()

        print('\nSTART 2nd FIT\n')
        tres = tfit.fit()  # do the fit
        if not tres.succeeded:
            print(tres.message)
        print('2nd ROUND OF SHERPA FIT IS DONE\n')

        print('Calculating errors...')

        # Errors directly from the covariance matrix in the fit
        if ERRORS == 'hessian':
            # change this such that it is still correct if epoch is frozen, see first point in issue #24
            calc_errors = np.sqrt(tres.extra_output['covar'].diagonal())
            rl_err = calc_errors[0]
            epoch_err = calc_errors[2]

            if not tmodel.inclin.frozen and not tmodel.msmpr.frozen:
                incl_err = calc_errors[3]
                msmpr_err = calc_errors[4]

            elif not tmodel.inclin.frozen:
                incl_err = calc_errors[3]

            elif not tmodel.msmpr.frozen:
                msmpr_err = calc_errors[3]

        # Errors from the 'Confidence' estimation method
        elif ERRORS == 'confidence':
            # change this such that it is still correct if epoch is frozen, see first point in issue #24
            # We can calculate errors only on thawed parameters, and inclin and msmpr are not always thawed - neither is epoch
            if not tmodel.inclin.frozen and not tmodel.msmpr.frozen:
                print("Est errors on rl, epoch, inclin and msmpr...")
                calc_errors = tfit.est_errors(parlist=(tmodel.rl, tmodel.epoch, tmodel.msmpr, tmodel.inclin,))
                msmpr_err = max(np.abs(calc_errors.parmaxes[2]), np.abs(calc_errors.parmins[2]))
                incl_err = max(np.abs(calc_errors.parmaxes[3]), np.abs(calc_errors.parmins[3]))

            elif not tmodel.inclin.frozen:
                print('Est errors on rl, epoch and inclin...')
                calc_errors = tfit.est_errors(parlist=(tmodel.rl, tmodel.epoch, tmodel.inclin))
                incl_err = max(np.abs(calc_errors.parmaxes[2]), np.abs(calc_errors.parmins[2]))

            elif not tmodel.msmpr.frozen:
                print('Est errors on rl, epoch and msmpr...')
                calc_errors = tfit.est_errors(parlist=(tmodel.rl, tmodel.epoch, tmodel.msmpr))
                msmpr_err = max(np.abs(calc_errors.parmaxes[2]), np.abs(calc_errors.parmins[2]))

            else:
                print('Est errors for rl and epoch...')
                calc_errors = tfit.est_errors(parlist=(tmodel.rl, tmodel.epoch))

            # rl and epoch are in this case of "fit_time" always thawed
            rl_err = max(np.abs(calc_errors.parmaxes[0]), np.abs(calc_errors.parmins[0]))
            epoch_err = max(np.abs(calc_errors.parmaxes[1]), np.abs(calc_errors.parmins[1]))

        print('\nTRANSIT DEPTH rl in model {} of {} = {} +/- {}, centered at {}'.format(i+1, nsys, tmodel.rl.val, rl_err, tmodel.epoch.val))

        # Count free parameters by figuring out how many zeros we have in the current systematics
        nfree = np.count_nonzero(sys == 0)

        # From the fit define the DOF, BIC, AIC & CHI
        CHI = tres.statval  # chi squared of resulting fit
        BIC = CHI + nfree * np.log(len(img_date))
        AIC = CHI + nfree
        DOF = tres.dof

        # EVIDENCE BASED on the AIC and BIC
        Npoint = len(img_date)
        sigma_points = np.median(tdata.staterror)

        evidence_BIC = - Npoint * np.log(sigma_points) - 0.5 * Npoint * np.log(2 * np.pi) - 0.5 * BIC
        evidence_AIC = - Npoint * np.log(sigma_points) - 0.5 * Npoint * np.log(2 * np.pi) - 0.5 * AIC

        # OUTPUTS
        # Re-Calculate each of the arrays dependent on the output parameters for the epoch
        phase = marg.phase_calc(img_date, tmodel.epoch.val*u.d, tmodel.period.val*u.d)
        HSTphase = marg.phase_calc(img_date, tmodel.tzero.val*u.d, HST_period)

        # ...........................................
        # TRANSIT MODEL fit to the data           # Issue #36
        # Calculate the impact parameter based on the eccentricity function - b0 in stellar radii
        b0 = marg.impact_param((tmodel.period.val*u.d).to(u.s), tmodel.msmpr.val, phase, tmodel.inclin.val*u.rad)
        mulimb01, _mulimbf1 = marg.occultnl(tmodel.rl.val, tmodel.c1.val, tmodel.c2.val, tmodel.c3.val, tmodel.c4.val, b0)  # recalculated model at data resolution

        # ...........................................
        # SMOOTH TRANSIT MODEL across all phase    # Issue #35
        # Calculate the impact parameter based on the eccentricity function - b0 in stellar radii
        x2 = np.arange(-half_range, half_range, resolution)   # this is the x-array for the smooth model
        b0 = marg.impact_param((tmodel.period.val*u.d).to(u.s), tmodel.msmpr.val, x2, tmodel.inclin.val*u.rad)
        mulimb02, _mulimbf2 = marg.occultnl(tmodel.rl.val, tmodel.c1.val, tmodel.c2.val, tmodel.c3.val, tmodel.c4.val, b0)

        systematic_model = marg.sys_model(phase, HSTphase, sh, tmodel.m_fac.val, tmodel.hstp1.val, tmodel.hstp2.val,
                                          tmodel.hstp3.val, tmodel.hstp4.val, tmodel.xshift1.val, tmodel.xshift2.val,
                                          tmodel.xshift3.val, tmodel.xshift4.val)

        fit_model = mulimb01 * tmodel.flux0.val * systematic_model     #  Issue #36
        residuals = (img_flux - fit_model) / tmodel.flux0.val
        resid_scatter = np.std(residuals)
        fit_data = img_flux / (tmodel.flux0.val * systematic_model)   # this is the data after taking the fitted systematics out

        if plotting:
            plt.figure(1)
            plt.clf()
            plt.scatter(phase, img_flux, s=5, label='Data')
            plt.plot(x2, mulimb02, 'k', label='Smooth model')
            plt.errorbar(phase, fit_data, yerr=tdata.staterror, fmt='m.', label='Fit')
            plt.xlim(-0.03, 0.03)
            plt.title('Model ' + str(i+1) + '/' + str(nsys))
            plt.xlabel('Planet Phase')
            plt.ylabel('Normalized flux')
            plt.legend()
            plt.draw()
            plt.pause(0.05)

        # .............................
        # Fill info into arrays to save to file once we iterated through all systems with both fits.
        sys_stats[i, :] = [AIC, BIC, DOF, CHI, resid_scatter]   # stats  - just saving

        sys_date[i, :] = img_date                               # input time data (x = date)  - reused but not really
        sys_phase[i, :] = phase                                 # phase  - used for plotting
        sys_rawflux[i, :] = img_flux                            # raw lightcurve flux  - just saving
        sys_rawflux_err[i, :] = err                             # raw flux error  - just saving
        sys_flux[i, :] = fit_data                               # corrected lightcurve flux
        sys_flux_err[i, :] = tdata.staterror                    # corrected flux error  - used for plotting
        sys_residuals[i, :] = residuals                         # residuals   - REUSED! also for plotting
        sys_systematic_model[i, :] = systematic_model           # systematic model  - just saving

        sys_model[i, :] = mulimb02                              # smooth model  - used for plotting
        sys_model_phase[i, :] = x2                              # smooth phase  - used for plotting

        sys_params[i, :] = [par.val for par in tmodel.pars]     # parameters  - REUSED!
        # We only really need the errors on rl, epoch, inclination and MsMpR, so I only calculate those. The rest
        # of the errors in this array will be zero (and hence false), but we'll be redesigning this in the near future.
        if not tmodel.inclin.frozen:
            sys_params_err[:, 3] = incl_err
        if not tmodel.msmpr.frozen:
            sys_params_err[:, 4] = msmpr_err

        sys_depth[i] = tmodel.rl.val                            # depth  - REUSED!
        sys_depth_err[i] = rl_err                               # depth error  - REUSED!
        sys_epoch[i] = tmodel.epoch.val                         # transit time  - REUSED!
        if not tmodel.epoch.frozen:
            sys_epoch_err[i] = epoch_err                            # transit time error  - REUSED!
        sys_evidenceAIC[i] = evidence_AIC                       # evidence AIC  - REUSED!
        sys_evidenceBIC[i] = evidence_BIC                       # evidence BIC  - REUSED!

        # Reset the model parameters to the input parameters
        # Note on resetting: https://sherpa.readthedocs.io/en/latest/models/index.html#resetting-parameter-values
        tmodel.reset()

    end_second_fit = time.time()
    print('Second fit of all {} models took {} sec = {} min.'.format(nsys, end_second_fit - start_second_fit,
                                                                     (end_second_fit - start_second_fit) / 60))

    # Save to file
    # For details on how to deal with this kind of file, see the notebook "NumpyData.ipynb"
    np.savez(os.path.join(outDir, 'full-fit_'+run_name), sys_stats=sys_stats, sys_date=sys_date, sys_phase=sys_phase,
             sys_rawflux=sys_rawflux, sys_rawflux_err=sys_rawflux_err, sys_flux=sys_flux, sys_flux_err=sys_flux_err,
             sys_residuals=sys_residuals, sys_model=sys_model, sys_model_phase=sys_model_phase,
             sys_systematic_model=sys_systematic_model, sys_params=sys_params, sys_params_err=sys_params_err,
             sys_depth=sys_depth, sys_depth_err=sys_depth_err, sys_epoch=sys_epoch, sys_epoch_err=sys_epoch_err,
             sys_evidenceAIC=sys_evidenceAIC, sys_evidenceBIC=sys_evidenceBIC)


    #####################################
    #          MARGINALISATION          #
    #####################################

    # Sort the systematic models from largest to smallest AIC
    sorted_aic = (np.sort(sys_evidenceAIC))[::-1]
    print('\nTOP 10 SYSTEMATIC MODELS')

    # Print the AIC for the top 10 systematic models
    print('AIC for top 10 models: {}'.format(sorted_aic[:10]))
    # Print all the AIC values
    print('AIC for all systems: {}'.format(sys_evidenceAIC))

    # REFORMAT all arrays with just positive values
    pos = np.where(sys_evidenceAIC > 0)
    if len(pos) == 0:
        pos = -1
    print('Negative AIC at  positions = {}'.format(pos))

    # Issue #37
    count_AIC = sys_evidenceAIC[pos]
    count_depth = sys_depth[pos]
    count_depth_err = sys_depth_err[pos]
    count_epoch = sys_epoch[pos]
    count_epoch_err = sys_epoch_err[pos]
    count_residuals = sys_residuals[pos]
    count_date = sys_date[pos]                # not reused - maybe useful for plotting though?
    count_flux = sys_flux[pos]
    count_flux_err = sys_flux_err[pos]
    count_phase = sys_phase[pos]
    count_model_y = sys_model[pos]
    count_model_x = sys_model_phase[pos]

    beta = np.min(count_AIC)
    w_q = (np.exp(count_AIC - beta)) / np.sum(np.exp(count_AIC - beta))  # weights

    #  This is just for runtime outputs
    n01 = np.where(w_q >= 0.05)   # Issue #38
    print('\n{} models have a weight over 0.05. -> Models: {} with weigths: {}'.format(n01[0].shape, n01, w_q[n01]))
    print('Most likely model is number {} at w_q={}'.format(np.argmax(w_q), np.max(w_q)))

    # best_sys_weight is the best system from our evidence, as opposed to best system puerly by scatter on residuals
    best_sys_weight = np.argmax(w_q)
    print('SDNR best model from evidence = {}, for model {}'.format(
          np.std(count_residuals[best_sys_weight, :]) / np.sqrt(2) * 1e6, best_sys_weight))

    # best_sys_sdnr identifies best system based purely on std of residuals, ignoring a penalization by  model
    # complexity. This shows us how picking the "best" model differs between std alone and weigthed result.
    rl_sdnr = np.zeros(len(w_q))
    for i in range(len(w_q)):
        rl_sdnr[i] = (np.std(count_residuals[i]) / np.sqrt(2)) * 1e6   # make sure these system indices work on initial indexing, before taking out "bad" values (where we make variable 'pos')
    best_sys_sdnr = np.argmin(rl_sdnr)

    print('SDNR best = {} for model {}'.format(np.min(rl_sdnr), best_sys_sdnr))

    # Marginalization plots
    """ Runtime plots limited to fits, this chunk will be restructured for a pretty output PDF, see issue #42.
    plt.figure(2)
    plt.suptitle('Marginalization results')
    plt.subplot(3, 1, 1)
    plt.plot(w_q)
    plt.ylabel('Weight')
    plt.subplot(3, 1, 2)
    plt.plot(rl_sdnr)
    plt.ylabel('Standard deviation of residuals')
    plt.subplot(3, 1, 3)
    plt.errorbar(np.arange(1, len(count_depth)+1), count_depth, yerr=count_depth_err, fmt='.')
    plt.ylabel('$R_P/R_*$')
    plt.xlabel('Systematic model number')
    plt.savefig(os.path.join(outDir, 'weights-stdr-rl_'+run_name+'.pdf'))
    if plotting:
        plt.show()

    plt.figure(3)
    plt.suptitle('First vs. best model')
    plt.subplot(3, 1, 1)
    plt.scatter(sys_phase[0,:], sys_flux[0,:])
    plt.ylim(np.min(sys_flux[0,:]) - 0.001, np.max(sys_flux[0,:]) + 0.001)
    plt.ylabel('Fitted norm. flux of first sys model')

    plt.subplot(3, 1, 2)
    plt.scatter(count_phase[best_sys_weight,:], count_flux[best_sys_weight,:], label='Fit of best model')
    plt.plot(count_model_x[best_sys_weight,:], count_model_y[best_sys_weight,:], label='Smooth best model')
    plt.ylim(np.min(count_flux[0,:]) - 0.001, np.max(count_flux[0,:]) + 0.001)
    plt.ylabel('Best model norm. flux')

    plt.subplot(3, 1, 3)
    plt.errorbar(count_phase[best_sys_weight,:], count_residuals[best_sys_weight,:], yerr=count_flux_err[best_sys_weight,:], fmt='.')
    plt.ylim(-1000, 1000)
    plt.xlabel('Planet phase')
    plt.ylabel('Best model residuals')
    plt.hlines(0.0, xmin=np.min(count_phase[best_sys_weight,:]), xmax=np.max(count_phase[best_sys_weight,:]), colors='r', linestyles='dashed')
    plt.hlines(0.0 - (rl_sdnr[best_sys_weight]), xmin=np.min(count_phase[best_sys_weight,:]), xmax=np.max(count_phase[best_sys_weight,:]), colors='r', linestyles='dotted')
    plt.hlines(0.0 + (rl_sdnr[best_sys_weight]), xmin=np.min(count_phase[best_sys_weight,:]), xmax=np.max(count_phase[best_sys_weight,:]), colors='r', linestyles='dotted')
    plt.savefig(os.path.join(outDir, 'residuals_best-model_'+run_name+'.pdf'))
    if plotting:
        plt.show()
    """

    ### Radius ratio - this one always gets calculated
    marg_rl, marg_rl_err = marg.marginalization(count_depth, count_depth_err, w_q)
    print('Rp/R* = {} +/- {}'.format(marg_rl, marg_rl_err))

    ### Center of transit time (epoch)
    marg_epoch = None
    marg_epoch_err = None
    if not tmodel.epoch.frozen:
        marg_epoch, marg_epoch_err = marg.marginalization(count_epoch, count_epoch_err, w_q)
        print('Epoch = {} +/- {}'.format(marg_epoch, marg_epoch_err))

    ### Inclination
    marg_inclin_rad = None
    marg_inclin_rad_err = None
    marg_inclin_deg = None
    marg_inclin_deg_err = None

    if not tmodel.inclin.frozen:
        # Inclication in radians
        marg_inclin_rad, marg_inclin_rad_err = marg.marginalization(sys_params[:, 3], sys_params_err[:, 3], w_q)
        print('inc (rads) = {} +/- {}'.format(marg_inclin_rad, marg_inclin_rad_err))

        # Inclination in degrees
        conv1 = sys_params[:, 3] / (2 * np.pi / 360)
        conv2 = sys_params_err[:, 3] / (2 * np.pi / 360)
        marg_inclin_deg, marg_inclin_deg_err = marg.marginalization(conv1, conv2, w_q)
        print('inc (deg) = {} +/- {}'.format(marg_inclin_deg, marg_inclin_deg_err))

    ### MsMpR
    marg_msmpr = None
    marg_msmpr_err = None
    marg_aors = None
    marg_aors_err = None

    if not tmodel.msmpr.frozen:
        marg_msmpr, marg_msmpr_err = marg.marginalization(sys_params[:, 4], sys_params_err[:, 4], w_q)
        print('MsMpR = {} +/- {}'.format(marg_msmpr, marg_msmpr_err))

        # Recalculate a/R* (actually the constant for it) based on the new MsMpR value which may have been fit in the routine.
        marg_aors = constant1 * (marg_msmpr ** (1./3.))
        marg_aors_err = constant1 * (marg_msmpr_err ** (1./3.)) / marg_aors
        print('a/R* = {} +/- {}'.format(marg_aors, marg_aors_err))

    ### Save to file
    # For details on how to deal with this kind of file, see the notebook "NumpyData.ipynb"
    np.savez(os.path.join(outDir, 'marginalization_results_'+run_name), w_q=w_q, best_sys=best_sys_weight,
             marg_rl=marg_rl, marg_rl_err=marg_rl_err, marg_epoch=marg_epoch, marg_epoch_err=marg_epoch_err,
             marg_inclin_rad=marg_inclin_rad, marg_inclin_rad_err=marg_inclin_rad_err, marg_inclin_deg=marg_inclin_deg,
             marg_inclin_deg_err=marg_inclin_deg_err, marg_msmpr=marg_msmpr, marg_msmpr_err=marg_msmpr_err,
             marg_aors=marg_aors, marg_aors_err=marg_aors_err, rl_sdnr=rl_sdnr, pos=pos)

    ### Create PDF report
    template_vars = {'data_file': CONFIG_INI.get(exoplanet, 'lightcurve_file'),
                     'run_name': CONFIG_INI.get('data_paths', 'run_name'),
                     'rl_in': CONFIG_INI.getfloat(exoplanet, 'rl'),
                     'epoch_in': CONFIG_INI.getfloat(exoplanet, 'epoch'),
                     'incl_deg_in': CONFIG_INI.getfloat(exoplanet, 'inclin'),
                     'ecc_in': CONFIG_INI.getfloat(exoplanet, 'ecc'),
                     'omega_in': CONFIG_INI.getfloat(exoplanet, 'omega'),
                     'period_in': CONFIG_INI.getfloat(exoplanet, 'Per'),
                     'aor_in': CONFIG_INI.getfloat(exoplanet, 'aor'),
                     'metallicity': CONFIG_INI.getfloat('limb_darkening', 'metallicity'),
                     'teff_in': CONFIG_INI.getfloat('limb_darkening', 'Teff'),
                     'logg_in': CONFIG_INI.getfloat('limb_darkening', 'logg'),
                     'c1': c1,
                     'c2': c2,
                     'c3': c3,
                     'c4': c4,
                     'top_five_numbers': 'test',
                     'top_five_weights': 'test',
                     'top_five_sndr': 'test',
                     'white_noise': 'test',
                     'red_noise': 'test',
                     'photon_noise': 'test',
                     'rl_marg': marg_rl,
                     'rl_marg_err': marg_rl_err,
                     'epoch_marg': marg_epoch,
                     'epoch_marg_err': marg_epoch_err,
                     'inclin_rad_marg': marg_inclin_rad,
                     'inclin_rad_marg_err': marg_inclin_rad_err,
                     'inclin_deg_marg': marg_inclin_deg,
                     'inclin_deg_marg_err': marg_inclin_deg_err,
                     'msmpr_marg': marg_msmpr,
                     'msmpr_marg_err': marg_msmpr_err,
                     'aor_marg': marg_aors,
                     'aor_marg_err': marg_aors_err,
                     'lightcurve_figure': 'test',
                     'systematics_figure': 'test'}

    marg.create_pdf_report(template_vars, os.path.join(outDir, 'report_'+run_name+'.pdf'))


if __name__ == '__main__':

    # Figure out how much time it takes to run this code.
    start_time = time.time()

    # What data are we using?
    exoplanet = CONFIG_INI.get('data_paths', 'current_model')
    print('\nWORKING ON EXOPLANET {}\n'.format(exoplanet))

    # Set up the data paths
    localDir = CONFIG_INI.get('data_paths', 'local_path')
    outDir = CONFIG_INI.get('data_paths', 'output_path')
    dataDir = os.path.join(localDir, os.path.join(localDir, CONFIG_INI.get('data_paths', 'data_path')), exoplanet)

    # Read in the txt file for the lightcurve data
    get_timeseries = CONFIG_INI.get(exoplanet, 'lightcurve_file')
    get_wvln = CONFIG_INI.get(exoplanet, 'wvln_file')
    x, y, err, sh = np.loadtxt(os.path.join(dataDir, get_timeseries), skiprows=7, unpack=True)
    wavelength = np.loadtxt(os.path.join(dataDir, get_wvln), skiprows=3)

    # What to call the run and whether to turn plotting on
    run_name = CONFIG_INI.get('data_paths', 'run_name')
    plotting = CONFIG_INI.getboolean('technical_parameters', 'plotting')

    # Run the main function
    total_marg(exoplanet, x, y, err, sh, wavelength, outDir, run_name, plotting)

    end_time = time.time()
    print('\nTime it took to run the code:', (end_time-start_time)/60, 'min')

    print("\n--- ALL IS DONE, LET'S GO HOME AND HAVE A DRINK! ---\n")
