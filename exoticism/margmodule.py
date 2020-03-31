"""
Helper module for transit marginalisation.
"""

import os
from os import listdir
from os.path import join, isdir, dirname, basename
import time
import datetime
import numpy as np
from astropy.constants import G
import astropy.units as u

from sherpa.models import model

from exoticism.config import CONFIG_INI

# Read planet parameters from configfile
exoplanet = CONFIG_INI.get('setup', 'data_set')
RL = CONFIG_INI.getfloat(exoplanet, 'rl')
EPOCH = CONFIG_INI.getfloat(exoplanet, 'epoch')
INCLIN = CONFIG_INI.getfloat(exoplanet, 'inclin')
ECC = CONFIG_INI.getfloat(exoplanet, 'ecc')
OMEGA = CONFIG_INI.getfloat(exoplanet, 'omega')
PERIOD = CONFIG_INI.getfloat(exoplanet, 'Per')


def _transit_model(pars, x, sh, x_in_phase=False):
    """
    Transit model by Mandel & Agol (2002). If x_in_phase=True, the data input is already in units of phase as opposed to
    MJD or other.
    --------
    Params:
    rl: transit depth in Rp/R_star, unitless
    flux:
    epoch: center of transit in days (MJD) or phase if x_in_phase=True
    inclin: inclination of system in radians
    MsMpR: density of the system where MsMpR = (Ms+Mp)/(R*^3D0) this can also be calculated from the a/R* following
           constant1 = (G*Per*Per/(4*!pi*!pi))^(1/3) -> MsMpR = (a_Rs/constant1)^3
    ecc: eccentricity of the system
    omega: that other weird angle in a planetary system
    per: period of planet transit in days
    tzero: first x-array data entry in days (MJD)
    c1, c2, c3, c4: limb darkening parameters (quadratic)
    m_fac: global slope factor in the systematic model
    hstp1, hstp2, hstp3, hstp4: HST period systematic parameters (units?)
    xshift1, xshift2, xshift3, xshift4: shift systematic parameters (units?)

    x: array; input time grid
    sh: array, input shifts
    """

    HSTper = CONFIG_INI.getfloat('constants', 'HST_period') * u.d

    # Define each of the parameters that are read into the fitting routine
    (rl, flux0, epoch, inclin, MsMpR, ecc, omega, per, tzero, c1, c2, c3, c4,
     m_fac, hstp1, hstp2, hstp3, hstp4, xshift1, xshift2, xshift3, xshift4) = pars

    # Attaching some units
    x *= u.d
    epoch *= u.d
    inclin *= u.rad
    per *= u.d
    tzero *= u.d

    if sh is None:
        temp = x.shape[0]
        sh = np.zeros(temp)

    if not x_in_phase:
        phase = phase_calc(x, epoch, per)  # Per in days here
        HSTphase = phase_calc(x, tzero, HSTper)
    else:
        phase = x.value
        HSTphase = x.value

    # Calculate the impact parameter as a function of the planetary phase across the star.
    b0 = impact_param(per.to(u.second), MsMpR, phase, inclin)  # period in sec here, incl in radians, b0 in stellar radii

    # Occultnl would be replaced with BATMAN if possible. The main result we need is the rl - radius ratio
    # The c1-c4 are the non-linear limb-darkening parameters
    # b0 is the impact parameter function and I am not sure how this is handled in BATMAN - need to look into this.
    mulimb0, mulimbf = occultnl(rl, c1, c2, c3, c4, b0)
    systematic_model = sys_model(phase, HSTphase, sh, m_fac, hstp1, hstp2, hstp3, hstp4,
                                 xshift1, xshift2, xshift3, xshift4)

    # model fit to data = transit model * baseline flux (flux0) * systematic model
    model = mulimb0 * flux0 * systematic_model

    return model


class Transit(model.RegriddableModel1D):
    """Transit model

    Params below as inputs, all other params read from configfile:
    rl, epoch, inclin, ecc, omega, per, m_fac, hstp1, hstp2, hstp3, hstp4, xshift1, xshift2, xshift3, xshift4.
    The x-data array is read from disk as specified in the configfile.
    --------
    Params:
    tzero: first x-array data entry in days (MJD)
    msmpr: density of the system where MsMpR = (Ms+Mp)/(R*^3D0) this can also be calculated from the a/R* following
           constant1 = (G*Per*Per/(4*!pi*!pi))^(1/3) -> MsMpR = (a_Rs/constant1)^3
    c1, c2, c3, c4: limb darkening parameters (quadratic)
    flux0: flux at tzero
    sh: array, input shifts"""

    def __init__(self, tzero, msmpr, c1, c2, c3, c4, flux0=1., x_in_phase=False, name='transit', sh=None):
        self.rl = model.Parameter(name, 'rl', RL)
        self.flux0 = model.Parameter(name, 'flux0', flux0)
        self.epoch = model.Parameter(name, 'epoch', EPOCH, units='days [MJD]')
        self.inclin = model.Parameter(name, 'inclin', np.deg2rad(INCLIN), units='radians')
        self.msmpr = model.Parameter(name, 'msmpr', msmpr)
        self.ecc = model.Parameter(name, 'ecc', ECC, units='degrees')
        self.omega = model.Parameter(name, 'omega', np.deg2rad(OMEGA), units='degrees', alwaysfrozen=True)
        self.period = model.Parameter(name, 'period', PERIOD, units='days', alwaysfrozen=True)
        self.tzero = model.Parameter(name, 'tzero', tzero, units='days [MJD]', alwaysfrozen=True)
        self.c1 = model.Parameter(name, 'c1', c1, alwaysfrozen=True)
        self.c2 = model.Parameter(name, 'c2', c2, alwaysfrozen=True)
        self.c3 = model.Parameter(name, 'c3', c3, alwaysfrozen=True)
        self.c4 = model.Parameter(name, 'c4', c4, alwaysfrozen=True)
        self.m_fac = model.Parameter(name, 'm_fac', 0)
        self.hstp1 = model.Parameter(name, 'hstp1', 0)
        self.hstp2 = model.Parameter(name, 'hstp2', 0)
        self.hstp3 = model.Parameter(name, 'hstp3', 0)
        self.hstp4 = model.Parameter(name, 'hstp4', 0)
        self.xshift1 = model.Parameter(name, 'xshift1', 0)
        self.xshift2 = model.Parameter(name, 'xshift2', 0)
        self.xshift3 = model.Parameter(name, 'xshift3', 0)
        self.xshift4 = model.Parameter(name, 'xshift4', 0)

        self.x_in_phase = x_in_phase
        self.sh_array = sh   # This is not a model parameter but an extra input to the model, like x is

        model.RegriddableModel1D.__init__(self, name,
                                          (self.rl, self.flux0, self.epoch,
                                           self.inclin, self.msmpr, self.ecc,
                                           self.omega, self.period, self.tzero,
                                           self.c1, self.c2, self.c3, self.c4,
                                           self.m_fac, self.hstp1, self.hstp2,
                                           self.hstp3, self.hstp4, self.xshift1,
                                           self.xshift2, self.xshift3, self.xshift4))

    def calc(self, pars, x, *args, **kwargs):
        """Evaluate the model"""
        return _transit_model(pars, x, self.sh_array, x_in_phase=self.x_in_phase)


def occultnl(rl, c1, c2, c3, c4, b0):
    """
    MANDEL & AGOL (2002) transit model.
    :param rl: float, transit depth (Rp/R*)
    :param c1: float, limb darkening parameter 1
    :param c2: float, limb darkening parameter 2
    :param c3: float, limb darkening parameter 3
    :param c4: float, limb darkening parameter 4
    :param b0: impact parameter in stellar radii
    :return: mulimb0: limb-darkened transit model, mulimbf: lightcurves for each component that you put in the model
    """
    mulimb0 = occultuniform(b0, rl)
    bt0 = b0
    fac = np.max(np.abs(mulimb0 - 1))
    if fac == 0:
        fac = 1e-6  # DKS edit

    omega = 4 * ((1 - c1 - c2 - c3 - c4) / 4 + c1 / 5 + c2 / 6 + c3 / 7 + c4 / 8)
    nb = len(b0)
    indx = np.where(mulimb0 != 1.0)[0]
    if len(indx) == 0:
        indx = -1
    mulimb = mulimb0[indx]
    mulimbf = np.zeros((5, nb))
    mulimbf[0, :] = mulimbf[0, :] + 1.
    mulimbf[1, :] = mulimbf[1, :] + 0.8
    mulimbf[2, :] = mulimbf[2, :] + 2 / 3
    mulimbf[3, :] = mulimbf[3, :] + 4 / 7
    mulimbf[4, :] = mulimbf[4, :] + 0.5
    nr = np.int64(2)
    dmumax = 1.0

    while (dmumax > fac * 1.e-3) and (nr <= 131072):
        #print(nr)
        mulimbp = mulimb
        nr = nr * 2
        dt = 0.5 * np.pi / nr
        t = dt * np.arange(nr + 1)
        th = t + 0.5 * dt
        r = np.sin(t)
        sig = np.sqrt(np.cos(th[nr - 1]))
        mulimbhalf = sig ** 3 * mulimb0[indx] / (1 - r[nr - 1])
        mulimb1 = sig ** 4 * mulimb0[indx] / (1 - r[nr - 1])
        mulimb3half = sig ** 5 * mulimb0[indx] / (1 - r[nr - 1])
        mulimb2 = sig ** 6 * mulimb0[indx] / (1 - r[nr - 1])
        for i in range(1, nr):
            mu = occultuniform(b0[indx] / r[i], rl / r[i])
            sig1 = np.sqrt(np.cos(th[i - 1]))
            sig2 = np.sqrt(np.cos(th[i]))
            mulimbhalf = mulimbhalf + r[i] ** 2 * mu * (sig1 ** 3 / (r[i] - r[i - 1]) - sig2 ** 3 / (r[i + 1] - r[i]))
            mulimb1 = mulimb1 + r[i] ** 2 * mu * (sig1 ** 4 / (r[i] - r[i - 1]) - sig2 ** 4 / (r[i + 1] - r[i]))
            mulimb3half = mulimb3half + r[i] ** 2 * mu * (sig1 ** 5 / (r[i] - r[i - 1]) - sig2 ** 5 / (r[i + 1] - r[i]))
            mulimb2 = mulimb2 + r[i] ** 2 * mu * (sig1 ** 6 / (r[i] - r[i - 1]) - sig2 ** 6 / (r[i + 1] - r[i]))

        mulimb = ((1 - c1 - c2 - c3 - c4) * mulimb0[
            indx] + c1 * mulimbhalf * dt + c2 * mulimb1 * dt + c3 * mulimb3half * dt + c4 * mulimb2 * dt) / omega
        ix1 = np.where(mulimb + mulimbp != 0.)[0]
        if len(ix1) == 0:
            ix1 = -1

        #print(ix1)
        # python cannot index on single values so you need to use atlest_1d for the below to work when mulimb is a single value
        dmumax = np.max(np.abs(np.atleast_1d(mulimb)[ix1] - np.atleast_1d(mulimbp)[ix1]) / (
                np.atleast_1d(mulimb)[ix1] + np.atleast_1d(mulimbp)[ix1]))

    mulimbf[0, indx] = np.atleast_1d(mulimb0)[indx]
    mulimbf[1, indx] = mulimbhalf * dt
    mulimbf[2, indx] = mulimb1 * dt
    mulimbf[3, indx] = mulimb3half * dt
    mulimbf[4, indx] = mulimb2 * dt
    np.atleast_1d(mulimb0)[indx] = mulimb
    b0 = bt0

    return mulimb0, mulimbf


def occultuniform(b0, w):
    """
    Compute the lightcurve for occultation of a uniform source without microlensing (Mandel & Agol 2002).

    :param b0: array; impact parameter in units of stellar radii
    :param w: array; occulting star size in units of stellar radius
    :return: muo1: float; fraction of flux at each b0 for a uniform source
    """

    if np.abs(w - 0.5) < 1.0e-3:
        w = 0.5

    nb = len(np.atleast_1d(b0))
    muo1 = np.zeros(nb)


    for i in range(nb):
        # substitute z=b0(i) to shorten expressions
        z = np.atleast_1d(b0)[i]
        z = z.value    # stripping it of astropy units
        if z >= 1+w:
            muo1[i] = 1.0
            continue

        if w >= 1 and z <= w-1:
            muo1[i] = 0.0
            continue

        if z >= np.abs(1-w) and z <= 1+w:
            kap1 = np.arccos(np.min(np.append((1 - w ** 2 + z ** 2) / 2 / z, 1.)))
            kap0 = np.arccos(np.min(np.append((w ** 2 + z ** 2 - 1) / 2 / w / z, 1.)))
            lambdae = w ** 2 * kap0 + kap1
            lambdae = (lambdae - 0.5 * np.sqrt(np.max(np.append(4. * z ** 2 - (1 + z ** 2 - w ** 2) ** 2, 0.)))) / np.pi
            muo1[i] = 1 - lambdae

        if z <= 1-w:
            muo1[i] = 1 - w ** 2
            continue

    return muo1


def wfc3_systematic_model_grid_selection(selection):
    """
    Model grid up to the 4th order for HST (HSTP1-HSTP4) and delta_lambda (xshit1-xshift4), with linear T.

    1 in the grid means the parameter is fixed, 0 means it is free. Why some parameters are free and some are fixed
    is explained in Wakeford et al. 2016, Section 2.
    p0 =          [0,    1,     2,      3,     4,    5,    6,    7,  8,  9,  10, 11, 12,  13,    14,    15,    16,    17,     18,      19,      20,      21   ]
    p0 = np.array([rl, flux0, epoch, inclin, MsMpR, ecc, omega, Per, T0, c1, c2, c3, c4, m_fac, HSTP1, HSTP2, HSTP3, HSTP4, xshift1, xshift2, xshift3, xshift4])

    :param selection: string; which model grid to use, must be 'fix_time', 'fit_time', 'fit_inclin', 'fit_msmpr', 'fit_ecc' or 'fit_all'
    :return: wfc3_grid: array; grid containing which systematics to model
    """

    #-# Fixed arrays:
    # Parametrized Systematic Models - m_fac, HSTP1, HSTP2, HSTP3, HSTP4, xshift1, xshift2, xshift3, xshift4
    # Described in Wakeford et al. 2016, Sec. 2 and Table 2.
    systematic_models = np.array([[1, 1, 1, 1, 1, 1, 1, 1, 1],
                                  [1, 1, 1, 1, 1, 0, 1, 1, 1],
                                  [1, 1, 1, 1, 1, 0, 0, 1, 1],
                                  [1, 1, 1, 1, 1, 0, 0, 0, 1],
                                  [1, 1, 1, 1, 1, 0, 0, 0, 0],
                                  [1, 0, 1, 1, 1, 1, 1, 1, 1],
                                  [1, 0, 1, 1, 1, 0, 1, 1, 1],
                                  [1, 0, 1, 1, 1, 0, 0, 1, 1],
                                  [1, 0, 1, 1, 1, 0, 0, 0, 1],
                                  [1, 0, 1, 1, 1, 0, 0, 0, 0],
                                  [1, 0, 0, 1, 1, 1, 1, 1, 1],
                                  [1, 0, 0, 1, 1, 0, 1, 1, 1],
                                  [1, 0, 0, 1, 1, 0, 0, 1, 1],
                                  [1, 0, 0, 1, 1, 0, 0, 0, 1],
                                  [1, 0, 0, 1, 1, 0, 0, 0, 0],
                                  [1, 0, 0, 0, 1, 1, 1, 1, 1],
                                  [1, 0, 0, 0, 1, 0, 1, 1, 1],
                                  [1, 0, 0, 0, 1, 0, 0, 1, 1],
                                  [1, 0, 0, 0, 1, 0, 0, 0, 1],
                                  [1, 0, 0, 0, 1, 0, 0, 0, 0],
                                  [1, 0, 0, 0, 0, 1, 1, 1, 1],
                                  [1, 0, 0, 0, 0, 0, 1, 1, 1],
                                  [1, 0, 0, 0, 0, 0, 0, 1, 1],
                                  [1, 0, 0, 0, 0, 0, 0, 0, 1],
                                  [1, 0, 0, 0, 0, 0, 0, 0, 0],
                                  [0, 1, 1, 1, 1, 1, 1, 1, 1],
                                  [0, 1, 1, 1, 1, 0, 1, 1, 1],
                                  [0, 1, 1, 1, 1, 0, 0, 1, 1],
                                  [0, 1, 1, 1, 1, 0, 0, 0, 1],
                                  [0, 1, 1, 1, 1, 0, 0, 0, 0],
                                  [0, 0, 1, 1, 1, 1, 1, 1, 1],
                                  [0, 0, 1, 1, 1, 0, 1, 1, 1],
                                  [0, 0, 1, 1, 1, 0, 0, 1, 1],
                                  [0, 0, 1, 1, 1, 0, 0, 0, 1],
                                  [0, 0, 1, 1, 1, 0, 0, 0, 0],
                                  [0, 0, 0, 1, 1, 1, 1, 1, 1],
                                  [0, 0, 0, 1, 1, 0, 1, 1, 1],
                                  [0, 0, 0, 1, 1, 0, 0, 1, 1],
                                  [0, 0, 0, 1, 1, 0, 0, 0, 1],
                                  [0, 0, 0, 1, 1, 0, 0, 0, 0],
                                  [0, 0, 0, 0, 1, 1, 1, 1, 1],
                                  [0, 0, 0, 0, 1, 0, 1, 1, 1],
                                  [0, 0, 0, 0, 1, 0, 0, 1, 1],
                                  [0, 0, 0, 0, 1, 0, 0, 0, 1],
                                  [0, 0, 0, 0, 1, 0, 0, 0, 0],
                                  [0, 0, 0, 0, 0, 1, 1, 1, 1],
                                  [0, 0, 0, 0, 0, 0, 1, 1, 1],
                                  [0, 0, 0, 0, 0, 0, 0, 1, 1],
                                  [0, 0, 0, 0, 0, 0, 0, 0, 1],
                                  [0, 0, 0, 0, 0, 0, 0, 0, 0]], dtype=int)

    # Input constants - omega, Per, T0, c1, c2, c3, c4
    input_constants = np.ones([systematic_models.shape[0], 7], dtype=int)

    # Permanent free parameters - rl, flux0
    perm_free = np.zeros([systematic_models.shape[0], 2], dtype=int)

    #-# Variable parameters - epoch, inclin, MsMpR, ecc:
    variable_parameters = None   # Initialize the variable parameters

    # Fix time
    if selection == 'fix_time':
        variable_parameters = np.array([1, 1, 1, 1], dtype=int)

    # Fit for time
    if selection == 'fit_time':
        variable_parameters = np.array([0, 1, 1, 1], dtype=int)

    # Fit for inclination
    if selection == 'fit_inclin':
        variable_parameters = np.array([1, 0, 1, 1], dtype=int)

    # Fit for MsMpR
    if selection == 'fit_msmpr':
        variable_parameters = np.array([1, 1, 0, 1], dtype=int)

    # Fit for eccentricity
    if selection == 'fit_ecc':
        variable_parameters = np.array([1, 1, 1, 0], dtype=int)

    # Fit for all except for eccentricity
    if selection == 'fit_all':
        variable_parameters = np.array([0, 0, 0, 1], dtype=int)

    # Extend the single row array to fit the number of systems that we have
    var_param = np.tile(variable_parameters, (systematic_models.shape[0], 1))

    # Stick them all together in a big grid
    wfc3_grid = np.hstack((perm_free, var_param, input_constants, systematic_models))

    return wfc3_grid


def marginalisation(array, error, weight):
    """
    Marginalisation of the parameter array.
    :param array:  parameter array
    :param error:  error array
    :param weight: weighting
    :return: marginalisation parameter, error on marginalisation parameter
    """

    mean_param = np.sum(weight * array)
    variance_param = np.sqrt(np.sum(weight * ((array - mean_param) ** 2 + error ** 2)))

    return mean_param, variance_param


@u.quantity_input(per=u.s, incl=u.rad)
def impact_param(per, msmpr, phase, incl):
    """
    Calculate impact parameter.
    :param per: float, period in seconds
    :param msmpr: float, MsMpR
    :param phase: array, phase
    :param incl: float, inclination in radians
    """

    b0 = (G * per * per / (4 * np.pi * np.pi)) ** (1 / 3.) * (msmpr ** (1 / 3.)) * np.sqrt(
         (np.sin(phase * 2 * np.pi * u.rad)) ** 2 + (np.cos(incl) * np.cos(phase * 2 * np.pi * u.rad)) ** 2)

    return b0


def sys_model(phase, hst_phase, sh, m_fac, hstp1, hstp2, hstp3, hstp4, xshift1, xshift2, xshift3, xshift4):
    """
    Systematic model for WFC3 data.
    :param phase:
    :param hst_phase:
    :param sh: array corresponding to the shift in wavelength position on the detector throughout the visit
    :param m_fac:
    :param hstp1:
    :param hstp2:
    :param hstp3:
    :param hstp4:
    :param xshift1:
    :param xshift2:
    :param xshift3:
    :param xshift4:
    :return:
    """

    sys_m = (phase * m_fac + 1.0) * (
            hst_phase * hstp1 + hst_phase ** 2. * hstp2 + hst_phase ** 3. * hstp3 + hst_phase ** 4. * hstp4 + 1.0) * (
                    sh * xshift1 + sh ** 2. * xshift2 + sh ** 3. * xshift3 + sh ** 4. * xshift4 + 1.0)

    return sys_m


@u.quantity_input(period=u.d)
def phase_calc(data, epoch, period):
    """
    Convert time array data in terms of phase, with a period, centered on epoch.
    :param data: time array in days (MJD)
    :param epoch: center of period, same unit like data array
    :param period: phase period in days
    :return: phase: array
    """

    phase1 = (data - epoch) / period     # the data point at time "epoch" will be the zero-point; convert int phase by division through period
    phase2 = np.floor(phase1)            # identify integer intervals of phase (where phase is between 0-1, between 1-2, between 2-3 and over 3)
    phase = phase1 - phase2              # make phase be in interval from 0 to 1
    toobig = np.where(phase > 0.5)[0]    # figure out where phase is bigger than 0.5
    if toobig.size > 0:
        phase[toobig] -= 1.0                 # and where it is bigger than 0.5 indeed, subtract one to get to interval [-0.5, 0.5]

    return phase


def create_pdf_report(template_vars, outfile):

    # Create Jinja environment and get template
    from jinja2 import Environment, FileSystemLoader
    env = Environment(loader=FileSystemLoader(CONFIG_INI.get('data_paths', 'local_path')))
    template = env.get_template('report_template.html')

    # Render HTML with input variables
    html_out = template.render(template_vars)

    # Generate PDF
    from weasyprint import HTML
    HTML(string=html_out, base_url='.').write_pdf(outfile)


def calc_sdnr(residuals):

    sdnr = (np.std(residuals) / np.sqrt(2.)) * 1e6
    return sdnr


def noise_calculator(data, maxnbins=None, binstep=1):
    """
    Calculate the noise parameters of the data by using the residuals of the fit
    :param data: array, residuals of (2nd) fit
    :param maxnbins: int, maximum number of bins (default is len(data)/10)
    :param binstep: bin step size
    :return:
        red_noise: float, correlated noise in the data
        white_noise: float, statistical noise in the data
        beta: float, scaling factor to account for correlated noise
    """

    # bin data into multiple bin sizes
    npts = len(data)
    if maxnbins is None:
        maxnbins = npts/10.

    # create an array of the bin steps to use
    binz = np.arange(1, maxnbins+binstep, step=binstep, dtype=int)

    # Find the bin 2/3rd of the way down the bin steps
    midbin = int((binz[-1]*2)/3)

    nbins = np.zeros(len(binz), dtype=int)
    standard_dev = np.zeros(len(binz))
    root_mean_square = np.zeros(len(binz))
    root_mean_square_err = np.zeros(len(binz))
    
    for i in range(len(binz)):
        nbins[i] = int(np.floor(data.size/binz[i]))
        bindata = np.zeros(nbins[i], dtype=float)
        
        # bin data - contains the different arrays of the residuals binned down by binz
        for j in range(nbins[i]):
            bindata[j] = np.mean(data[j*binz[i] : (j+1)*binz[i]])

        # get root_mean_square statistic
        root_mean_square[i] = np.sqrt(np.mean(bindata**2))
        root_mean_square_err[i] = root_mean_square[i] / np.sqrt(2.*nbins[i])
      
    expected_noise = (np.std(data)/np.sqrt(binz)) * np.sqrt(nbins/(nbins - 1.))
 
    final_noise = np.mean(root_mean_square[midbin:])
    base_noise = np.sqrt(final_noise**2 - root_mean_square[0]**2 / nbins[midbin])

    # Calculate the random noise level of the data
    white_noise = np.sqrt(root_mean_square[0]**2 - base_noise**2)
    # Determine if there is correlated noise in the data
    red_noise = np.sqrt(final_noise**2 - white_noise**2 / nbins[midbin])
    # Calculate the beta scaling factor
    beta = np.sqrt(root_mean_square[0]**2 + nbins[midbin] * red_noise**2) / root_mean_square[0]

    # If White, Red, or Beta return NaN's replace with 0, 0, 1
    white_noise = np.nan_to_num(white_noise, copy=True)
    red_noise = np.nan_to_num(red_noise, copy=True)
    beta = 1 if np.isnan(beta) else beta
    
    # Plot up the bin statistic against the expected statistic
    # This can be used later when we are setting up unit testing.
    # plt.figure()
    # plt.errorbar(binz, root_mean_square, yerr=root_mean_square_err, color='k', lw=1.5, label='RMS')
    # plt.plot(binz, expected_noise, color='r', ls='-', lw=2, label='expected noise')
    #
    # plt.title('Expected vs. measured noise binning statistic')
    # plt.xlabel('Number of bins')
    # plt.ylabel('RMS')
    # plt.xscale('log')
    # plt.yscale('log')
    # plt.legend()
    # plt.tight_layout()
    # plt.show()

    return white_noise, red_noise, beta


def create_data_path(initial_path, star_system, suffix=""):
    """
    Will create a timestamp and join it to the output_path found in the INI.
    :param initial_path: output directory as defined in te configfile
    :param exoplanet: the star system the code is running the analysis on
    :param suffix: appends this to the end of the timestamp (ex: 2017-06-15T121212_suffix), also read from config
    :return: A path with the final folder containing a timestamp of the current datetime.
    """

    # Create a string representation of the current timestamp.
    time_stamp = time.time()
    date_time_string = datetime.datetime.fromtimestamp(time_stamp).strftime("%Y-%m-%dT%H-%M-%S")

    if suffix != "":
        suffix = "_" + suffix

    star_system = "_" + star_system

    # Return the full path.
    print(initial_path)
    print(star_system)
    print(suffix)
    full_path = os.path.join(initial_path, date_time_string + star_system + suffix)
    return full_path


def find_data_parent(searchfor):
    """
    Find absolute path of a directory or file.

    Taken from:
    https://stackoverflow.com/a/49034944/10112569
    :param searchfor, string: name of directory or file to find the path for
    :return: filepath, string: absolute path to desired directory or file
    """
    filepath = None
    # get parent of the .py running
    par_dir = dirname(__file__)
    while True:
        # get basenames of all the directories in that parent
        dirs = [basename(join(par_dir, d)) for d in listdir(par_dir) if isdir(join(par_dir, d))]
        # the parent contains desired directory
        if searchfor in dirs:
            filepath = par_dir
            break
        # back it out another parent otherwise
        par_dir = dirname(par_dir)

    return filepath