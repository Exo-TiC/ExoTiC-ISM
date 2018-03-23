import numpy as np


def residuals():
    model = transit_circle(p, x, sh)
    print('Rp/R* = {}'.format(p[0]))
    resids = (y - model) / p[1]

    print('Scatter = {}'.format(np.std(resids)))
    print('-----------------------------------')
    print(' ')

    return [0, (y-model)/err]


def transit_circle(p, fjac=None, x=None, y=None, err=None, sh=None):
    constant = [2.5, 20.2, 6.67259e-11, 2400000.5, 86400, 7.15e7, 6.96e8, 1.9e27, 1.99e30, 5781.6, 0.06691666]
    JD = 2400000.5
    Gr = 6.67259e-11
    HSTper = 96.36 / (24 * 60)

    rl = p[0]
    epoch = p[2]
    inclin = p[3]
    ecc = p[5]
    omega = p[6]
    Per = p[7]
    T0 = p[8]
    c1 = p[9]
    c2 = p[10]
    c3 = p[11]
    c4 = p[12]
    pi = np.float32(np.pi)

    MsMpR = p[4]

    constant1 = (constant[2]*Per*Per/(4*pi*pi))**(1/3.)
    aval = constant1 * MsMpR**(1/3.)

    print(epoch)
    phase = (x - epoch) / (Per / 86400) # convert to days
    phase2 = np.floor(phase)
    phase = phase - phase2
    a = np.where(phase > 0.5)[0]
    if a.size > 0:
        phase[a] = phase[a] - 1.0

    print('phase[0] = {}'.format(phase[0]))
    HSTphase = (x - T0) / HSTper # convert to days
    phase2 = np.floor(HSTphase)
    HSTphase = HSTphase - phase2
    k = np.where(HSTphase > 0.5)[0]
    if k.size > 0:
        HSTphase[k] = HSTphase[k] - 1.0

    b0 = (Gr * Per * Per / (4 * pi * pi))**(1/3.) * (MsMpR**(1/3.)) * np.sqrt((np.sin(phase*2*pi))**2 + (np.cos(inclin)*np.cos(phase*2*pi))**2)
    print(b0)
    mulimb0, mulimbf = occultnl(rl, c1, c2, c3, c4, b0)
    systematic_model = (p[13] * phase + 1.0) * (p[14] * HSTphase + p[15] * HSTphase**2 + p[16] * HSTphase**3 + p[17] * HSTphase**4 + 1.0) * (p[18] * sh + p[19] * sh**2 + p[20] * sh**3 + p[21] * sh**4 + 1.0)

    # model fit to data = transit model * baseline flux * systematic model
    model = mulimb0 * p[1] * systematic_model
    # this would be the break point to get the model values
    # return model
    print('Rp/R* = {}'.format(p[0]))
    resids = (y - model) / p[1]

    print('Scatter = {}'.format(np.std(resids)))
    print('-----------------------------------')
    print(' ')

    return [0, (y-model)/err]


def occultnl(rl, c1, c2, c3, c4, b0):
    mulimb0 = occultuniform(b0, rl)
    bt0 = b0
    fac = np.max(abs(mulimb0 - 1))
    if (fac == 0):
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
    dmumax=1.0

    while ((dmumax > fac * 1.e-3) and (nr <= 131072)):
        print(nr)
        mulimbp = mulimb
        nr = nr * 2
        dt = 0.5 * np.pi / nr
        t = dt * np.arange(nr + 1)
        th = t + 0.5 * dt
        r = np.sin(t)
        sig = np.sqrt(np.cos(th[nr-1]))
        mulimbhalf =sig**3 * mulimb0[indx] / (1 - r[nr-1])
        mulimb1 = sig**4 * mulimb0[indx] / (1 - r[nr-1])
        mulimb3half =sig**5 * mulimb0[indx] / (1 - r[nr-1])
        mulimb2 = sig**6 * mulimb0[indx] / (1 - r[nr-1])
        for i in range(1, nr):
            mu = occultuniform(b0[indx] / r[i], rl / r[i])
            sig1 = np.sqrt(np.cos(th[i-1]))
            sig2 = np.sqrt(np.cos(th[i]))
            mulimbhalf = mulimbhalf + r[i]**2 * mu * (sig1**3 / (r[i] - r[i-1]) - sig2**3 / (r[i+1] - r[i]))
            mulimb1 = mulimb1 + r[i]**2 * mu * (sig1**4 / (r[i] - r[i-1]) - sig2**4 / (r[i+1]-r[i]))
            mulimb3half = mulimb3half + r[i]**2 * mu * (sig1**5 / (r[i] - r[i-1]) - sig2**5 / (r[i+1]-r[i]))
            mulimb2 = mulimb2 + r[i]**2 * mu * (sig1**6 / (r[i] - r[i-1]) - sig2**6 / (r[i+1] - r[i]))

        mulimb = ((1 - c1 - c2 - c3 - c4) * mulimb0[indx] + c1 * mulimbhalf * dt + c2 * mulimb1 * dt + c3 * mulimb3half * dt + c4 * mulimb2 * dt) / omega
        ix1 = np.where(mulimb+mulimbp != 0.)[0]
        if len(ix1) == 0:
            ix1 = -1

        print(ix1)
        # python cannot index on single values so you need to use atlest_1d for the below to work when mulimb is a single value
        dmumax = np.max(abs(np.atleast_1d(mulimb)[ix1] - np.atleast_1d(mulimbp)[ix1]) / (np.atleast_1d(mulimb)[ix1] + np.atleast_1d(mulimbp)[ix1]))

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
    This routine computes the lightcurve for occultation
    of a uniform source without microlensing  (Mandel & Agol 2002).

    Parameters
    ----------
    b0: np.array
        impact parameter in units of rs
    w: np.array
        occulting star size in units of rs

    Returns
    -------
    muo1: float
        fraction of flux at each b0 for a uniform source
    """
    if (abs(w - 0.5) < 1.0e-3):
        w = 0.5

    nb = len(np.atleast_1d(b0))
    muo1 = np.zeros(nb)

    for i in range(nb):
        # substitute z=b0(i) to shorten expressions
        z = np.atleast_1d(b0)[i]
        if (z >= 1 + w):
            muo1[i] = 1.0
            continue

        if (w >= 1 and z <= w - 1):
            muo1[i] = 0.0
            continue

        if (z >= abs(1 - w) and z <= 1 + w):
            kap1 = np.arccos(np.min(np.append((1 - w ** 2 + z ** 2) / 2 / z, 1.)))
            kap0 = np.arccos(np.min(np.append((w ** 2 + z ** 2 - 1) / 2 / w / z, 1.)))
            lambdae = w ** 2 * kap0 + kap1
            lambdae = (lambdae - 0.5 * np.sqrt(np.max(np.append(4. * z ** 2 - (1 + z ** 2 - w ** 2) ** 2, 0.)))) / np.pi
            muo1[i] = 1 - lambdae

        if (z <= 1 - w):
            muo1[i] = 1 - w ** 2
            continue

    return muo1


def wfc3_systematic_model_grid_selection(selection):
    """
    Model grid up to the 4th order for HST & delta_lambda, with linear T

    Parameters
    ----------
    selection: str
        which model grid to use must be `'fix_time'`, `'fit_time'` , `'fit_inclin'`,
        `'fit_msmpr'`, or `'fit_ecc'`

    Return
    ------
    wfc3_grid: np.array
        grid containing which systematics to model

    """

    # fix time
    if (selection == 'fix_time'):
        grid_WFC3_fix_time = np.array([[0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,0,1,1,1],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,0,0,1,1],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,0,0,0,1],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,0,0,0,0],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,0,1,1,1],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,0,0,1,1],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,0,0,0,1],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,0,0,0,0],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1,1,1,1],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,0,1,1,1],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,0,0,1,1],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,0,0,0,1],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,0,0,0,0],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,1,1,1,1],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,1,1,1],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,1,1],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,1],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,0,1,1,1],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,0,0,1,1],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,0,0,0,1],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,0,0,0,0],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,1],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,0,1,1,1],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,0,0,1,1],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,0,0,0,1],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,0,0,0,0],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1,1,1,1,1],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1,0,1,1,1],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1,0,0,1,1],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1,0,0,0,1],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1,0,0,0,0],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,1,1,1,1,1],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,1,0,1,1,1],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,1,0,0,1,1],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,1,0,0,0,1],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,1,0,0,0,0],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,1,1,1,1],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,1,1,1],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,1,1],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,1],
                                       [0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0]])
        wfc3_grid = grid_WFC3_fix_time

    # fit for time
    if (selection == 'fit_time'):
        grid_WFC3_fit_time = np.array([[0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,0,1,1,1],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,0,0,1,1],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,0,0,0,1],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,0,0,0,0],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,0,1,1,1],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,0,0,1,1],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,0,0,0,1],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,0,0,0,0],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1,1,1,1],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,0,1,1,1],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,0,0,1,1],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,0,0,0,1],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,0,0,0,0],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,1,1,1,1],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,1,1,1],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,1,1],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,1],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,0,1,1,1],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,0,0,1,1],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,0,0,0,1],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,0,0,0,0],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,1],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,0,1,1,1],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,0,0,1,1],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,0,0,0,1],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,0,0,0,0],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1,1,1,1,1],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1,0,1,1,1],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1,0,0,1,1],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1,0,0,0,1],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1,0,0,0,0],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0,1,1,1,1,1],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0,1,0,1,1,1],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0,1,0,0,1,1],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0,1,0,0,0,1],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0,1,0,0,0,0],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,1,1,1,1],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,1,1,1],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,1,1],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,1],
                                       [0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0]])

        wfc3_grid = grid_WFC3_fit_time

    # fit for inclination
    if (selection == 'fit_inclin'):
        grid_WFC3_fit_inclin = np.array([[0,0,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,1,0,1,1,1,0,1,1,1],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,1,0,1,1,1,0,0,1,1],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,1,0,1,1,1,0,0,0,1],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,1,0,1,1,1,0,0,0,0],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,1,0,0,1,1,0,1,1,1],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,1,0,0,1,1,0,0,1,1],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,1,0,0,1,1,0,0,0,1],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,1,0,0,1,1,0,0,0,0],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1,1,1,1],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,1,0,0,0,1,0,1,1,1],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,1,0,0,0,1,0,0,1,1],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,1,0,0,0,1,0,0,0,1],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,1,0,0,0,1,0,0,0,0],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0,1,1,1,1],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,1,1,1],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,1,1],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,1],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,0,1,1,1,1,0,1,1,1],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,0,1,1,1,1,0,0,1,1],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,0,1,1,1,1,0,0,0,1],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,0,1,1,1,1,0,0,0,0],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,1],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,0,0,1,1,1,0,1,1,1],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,0,0,1,1,1,0,0,1,1],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,0,0,1,1,1,0,0,0,1],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,0,0,1,1,1,0,0,0,0],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,0,0,0,1,1,1,1,1,1],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,0,0,0,1,1,0,1,1,1],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,0,0,0,1,1,0,0,1,1],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,0,0,0,1,1,0,0,0,1],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,0,0,0,1,1,0,0,0,0],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,0,0,0,0,1,1,1,1,1],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,0,0,0,0,1,0,1,1,1],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,0,0,0,0,1,0,0,1,1],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,0,0,0,0,1,0,0,0,1],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,0,0,0,0,1,0,0,0,0],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,1,1,1,1],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,1,1,1],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,1,1],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,1],
                                         [0,0,1,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0]])

        wfc3_grid = grid_WFC3_fit_inclin

    # fit for MsMpR
    if (selection == 'fit_msmpr'):
        grid_WFC3_fit_msmpr = np.array([[0,0,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,1,0,1,1,1,0,1,1,1],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,1,0,1,1,1,0,0,1,1],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,1,0,1,1,1,0,0,0,1],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,1,0,1,1,1,0,0,0,0],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,1,0,0,1,1,0,1,1,1],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,1,0,0,1,1,0,0,1,1],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,1,0,0,1,1,0,0,0,1],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,1,0,0,1,1,0,0,0,0],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,1,0,0,0,1,1,1,1,1],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,1,0,0,0,1,0,1,1,1],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,1,0,0,0,1,0,0,1,1],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,1,0,0,0,1,0,0,0,1],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,1,0,0,0,1,0,0,0,0],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,1,0,0,0,0,1,1,1,1],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,1,1,1],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,1,1],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,1],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,0,1,1,1,1,0,1,1,1],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,0,1,1,1,1,0,0,1,1],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,0,1,1,1,1,0,0,0,1],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,0,1,1,1,1,0,0,0,0],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,1],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,0,0,1,1,1,0,1,1,1],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,0,0,1,1,1,0,0,1,1],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,0,0,1,1,1,0,0,0,1],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,0,0,1,1,1,0,0,0,0],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,0,0,0,1,1,1,1,1,1],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,0,0,0,1,1,0,1,1,1],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,0,0,0,1,1,0,0,1,1],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,0,0,0,1,1,0,0,0,1],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,0,0,0,1,1,0,0,0,0],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,0,0,0,0,1,1,1,1,1],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,0,0,0,0,1,0,1,1,1],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,0,0,0,0,1,0,0,1,1],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,0,0,0,0,1,0,0,0,1],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,0,0,0,0,1,0,0,0,0],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,0,0,0,0,0,1,1,1,1],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0,1,1,1],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,1,1],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,1],
                                        [0,0,1,1,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0]])

        wfc3_grid = grid_WFC3_fit_msmpr

    if (selection == 'fit_all'):
        grid_WFC3_fit_all = np.array([[0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,1,1,1,0,1,1,1],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,1,1,1,0,0,1,1],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,1,1,1,0,0,0,1],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,1,1,1,0,0,0,0],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,1,1,0,1,1,1],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,1,1,0,0,1,1],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,1,1,0,0,0,1],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,1,1,0,0,0,0],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,1,1,1,1,1],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,1,0,1,1,1],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,1,0,0,1,1],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,1,0,0,0,1],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,1,0,0,0,0],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,0,1,1,1,1],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,1,1,1],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,1,1],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,1],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,0,1,1,1,1,0,1,1,1],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,0,1,1,1,1,0,0,1,1],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,0,1,1,1,1,0,0,0,1],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,0,1,1,1,1,0,0,0,0],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,1],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,1,1,1,0,1,1,1],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,1,1,1,0,0,1,1],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,1,1,1,0,0,0,1],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,1,1,1,0,0,0,0],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,1,1,1,1,1,1],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,1,1,0,1,1,1],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,1,1,0,0,1,1],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,1,1,0,0,0,1],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,1,1,0,0,0,0],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0,1,1,1,1,1],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0,1,0,1,1,1],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0,1,0,0,1,1],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0,1,0,0,0,1],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0,1,0,0,0,0],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0,0,1,1,1,1],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0,1,1,1],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,1,1],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,1],
                                      [0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0]])
        wfc3_grid = grid_WFC3_fit_all

    # fit for eccentricity
    if (selection == 'fit_ecc'):
        grid_WFC3_fit_ecc = np.array([[0,0,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,1,0,1,1,1,0,1,1,1],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,1,0,1,1,1,0,0,1,1],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,1,0,1,1,1,0,0,0,1],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,1,0,1,1,1,0,0,0,0],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,1,0,0,1,1,0,1,1,1],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,1,0,0,1,1,0,0,1,1],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,1,0,0,1,1,0,0,0,1],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,1,0,0,1,1,0,0,0,0],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,1,0,0,0,1,1,1,1,1],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,1,0,0,0,1,0,1,1,1],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,1,0,0,0,1,0,0,1,1],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,1,0,0,0,1,0,0,0,1],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,1,0,0,0,1,0,0,0,0],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,1,0,0,0,0,1,1,1,1],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,1,0,0,0,0,0,1,1,1],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0,1,1],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,1],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,0,1,1,1,1,0,1,1,1],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,0,1,1,1,1,0,0,1,1],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,0,1,1,1,1,0,0,0,1],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,0,1,1,1,1,0,0,0,0],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,1],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,0,0,1,1,1,0,1,1,1],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,0,0,1,1,1,0,0,1,1],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,0,0,1,1,1,0,0,0,1],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,0,0,1,1,1,0,0,0,0],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,0,0,0,1,1,1,1,1,1],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,0,0,0,1,1,0,1,1,1],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,0,0,0,1,1,0,0,1,1],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,0,0,0,1,1,0,0,0,1],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,0,0,0,1,1,0,0,0,0],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,0,0,0,0,1,1,1,1,1],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,0,0,0,0,1,0,1,1,1],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,0,0,0,0,1,0,0,1,1],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,0,0,0,0,1,0,0,0,1],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,0,0,0,0,1,0,0,0,0],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,0,0,0,0,0,1,1,1,1],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,0,0,0,0,0,0,1,1,1],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,0,0,0,0,0,0,0,1,1],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,1],
                                      [0,0,1,1,1,0,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0]])

        wfc3_grid = grid_WFC3_fit_ecc

    return wfc3_grid