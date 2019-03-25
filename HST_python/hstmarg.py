import numpy as np
from config import CONFIG_INI

Gr = CONFIG_INI.getfloat('constants', 'big_G')


def residuals():
    """
    Not entirely sure what this function is (supposed to be) doing.
    :return:
    """
    model = transit_circle(p, x, sh)
    print('Rp/R* = {}'.format(p[0]))
    resids = (y - model) / p[1]

    print('Scatter = {}'.format(np.std(resids)))
    print('-----------------------------------')
    print(' ')

    return [0, (y - model) / err]


def transit_circle(p, fjac=None, x=None, y=None, err=None, sh=None):
    """
    Documentation missing.
    :param p:
    :param fjac:
    :param x:
    :param y:
    :param err:
    :param sh:
    :return:
    """

    # These are constants that are used in almost all of the routines and I am sure there is a way to make them common parameters rather than having to redefine them in each place - as you can some are redundantly redfined again below and some are just re-typed anyway.
    # constant = [GAIN,READNOISE,Gr,JD,DAY_TO_SEC,Rjup,Rsun,MJup,Msun,HST_SECOND,HST_PERIOD]
    # constant = [2.5, 20.2, 6.67259e-11, 2400000.5, 86400, 7.15e7, 6.96e8, 1.9e27, 1.99e30, 5781.6, 0.06691666]
    Gr = CONFIG_INI.getfloat('constants', 'big_G')
    HSTper = CONFIG_INI.getfloat('constants', 'HST_period')

    # Define each of the parameters that are read into the fitting routine
    rl = p[0]
    epoch = p[2]
    inclin = p[3]
    MsMpR = p[4]
    Per = p[7]
    T0 = p[8]
    c1 = p[9]
    c2 = p[10]
    c3 = p[11]
    c4 = p[12]

    # Turn off the print statements if you want this function to be silent - these are here for sanity checks
    print(epoch)
    phase = (x - epoch) / (Per / 86400)  # convert to days 
    phase2 = np.floor(phase)
    phase = phase - phase2
    a = np.where(phase > 0.5)[0]
    if a.size > 0:
        phase[a] = phase[a] - 1.0

    print('phase[0] = {}'.format(phase[0]))
    HSTphase = (x - T0) / HSTper  # convert to days
    phase2 = np.floor(HSTphase)
    HSTphase = HSTphase - phase2
    k = np.where(HSTphase > 0.5)[0]
    if k.size > 0:
        HSTphase[k] = HSTphase[k] - 1.0

    # Calculate the impact parameter as a function of the planetary phase across the star.
    b0 = (Gr * Per * Per / (4 * np.pi * np.pi)) ** (1 / 3.) * (MsMpR ** (1 / 3.)) * np.sqrt(
        (np.sin(phase * 2 * np.pi)) ** 2 + (np.cos(inclin) * np.cos(phase * 2 * np.pi)) ** 2)
    print(b0)

    # Occultnl would be replaced with BATMAN if possible. The main result we need is the rl - radius ratio
    # The c1-c4 are the non-linear limb-darkening parameters
    # b0 is the impact parameter function and I am not sure how this is handled in BATMAN - I will also look into this.
    mulimb0, mulimbf = occultnl(rl, c1, c2, c3, c4, b0)
    systematic_model = sys_model(phase, HSTphase, sh, p[13], p[14], p[15], p[16], p[17], p[18], p[19], p[20], p[21])

    # model fit to data = transit model * baseline flux (flux0) * systematic model
    model = mulimb0 * p[1] * systematic_model
    # this would be the break point to get the model values
    # return model
    print('Rp/R* = {}'.format(p[0]))
    resids = (y - model) / p[1]

    print('Scatter = {}'.format(np.std(resids)))
    print('-----------------------------------')
    print(' ')

    return (y - model) / err   #[0, (y - model) / err]


def occultnl(rl, c1, c2, c3, c4, b0):
    """
    MANDEL & AGOL (2002) transit model.
    :param rl: transit depth (Rp/R*)
    :param c1: limb darkening parameter 1
    :param c2: limb darkening parameter 2
    :param c3: limb darkening parameter 3
    :param c4: limb darkening parameter 4
    :param b0: impact parameter
    :return:mulimb0?, mulimbf?
    """
    mulimb0 = occultuniform(b0, rl)
    bt0 = b0
    fac = np.max(abs(mulimb0 - 1))
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
        dmumax = np.max(abs(np.atleast_1d(mulimb)[ix1] - np.atleast_1d(mulimbp)[ix1]) / (
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

    :param b0: array; impact parameter in units of rs
    :param w: array; occulting star size in units of rs
    :return: muo1: float; fraction of flux at each b0 for a uniform source
    """

    if abs(w - 0.5) < 1.0e-3:
        w = 0.5

    nb = len(np.atleast_1d(b0))
    muo1 = np.zeros(nb)

    for i in range(nb):
        # substitute z=b0(i) to shorten expressions
        z = np.atleast_1d(b0)[i]
        if z >= 1+w:
            muo1[i] = 1.0
            continue

        if w >= 1 and z <= w-1:
            muo1[i] = 0.0
            continue

        if z >= abs(1-w) and z <= 1+w:
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


def marginalization(array, error, weight):
    """
    Marginalization of the parameter array.
    :param array:  parameter array
    :param error:  error array
    :param weight: weighting
    :return: marginalization parameter, error on marginalization parameter
    """

    mean_param = np.sum(weight * array)
    variance_param = np.sqrt(np.sum(weight * ((array - mean_param) ** 2 + error ** 2)))

    return mean_param, variance_param


def impact_param(per, msmpr, phase, incl):
    """
    Calculate impact parameter
    :param per: period
    :param msmpr: MsMpR
    :param phase: phase
    :param incl: inclination
    :return:
    """

    b0 = (Gr * per * per / (4 * np.pi * np.pi)) ** (1 / 3.) * (msmpr ** (1 / 3.)) * np.sqrt(
        (np.sin(phase * 2 * np.pi)) ** 2 + (np.cos(incl) * np.cos(phase * 2 * np.pi)) ** 2)

    return b0


def sys_model(phase, hst_phase, sh, m_fac, hstp1, hstp2, hstp3, hstp4, xshift1, xshift2, xshift3, xshift4):
    """
    Systematic model for WFC3 data
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
