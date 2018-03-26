import numpy as np
from scipy.io import readsav
from scipy.interpolate import interp1d, splev, splrep
from astropy.modeling.models import custom_model
from astropy.modeling.fitting import LevMarLSQFitter


def limb_fit_3D_choose(grating, widek, wsdata, M_H, Teff, logg, dirsen, direc):
    """
    Calculates stellar limb-darkening coefficents for a given wavelength bin.

    Procedure from Sing et al. (2010, A&A, 510, A21).
    Uses 3D limb darkening from Magic et al. (2015, A&A, 573, 90).
    Uses photon FLUX Sum over (lambda*dlamba).
    :param grating: string; grating to use ('G430L','G750L','WFC3','R500B','R500R')
    :param widek: array; index array of wsdata, indicating bin of pixels to use
    :param wsdata: array; data wavelength solution
    :param M_H: float; stellar metallicity
    :param Teff: float; stellar effective temperature (K)
    :param logg: float; stellar gravity
    :param dirsen:
    :param direc:
    :return: uLD: float; linear limb darkening coefficient
    aLD, bLD: float; quadratic limb darkening coefficients
    cp1, cp2, cp3, cp4: float; three-parameter limb darkening coefficients
    c1, c2, c3, c4: float; non-linear limb-darkening coefficients
    """

    print('Current Directories Entered:')
    print('  ' + dirsen)
    print('  ' + direc)

    # Select Metallicity
    M_H_Grid = np.array([-3.0, -2.0, -1.0, 0.0])  # Grid values points
    M_H_Grid_load = ['30', '20', '10', '00']  # Grid values points
    optM = (abs(M_H - M_H_Grid)).argmin()

    # Select Teff
    Teff_Grid = np.array([4000, 4500, 5000, 5500, 5777, 6000, 6500, 7000])
    optT = (abs(Teff - Teff_Grid)).argmin()

    # Select logg

    if Teff_Grid[optT] == 4000:
        logg_Grid = np.array([1.5, 2.0, 2.5])
        optG = (abs(logg - logg_Grid)).argmin()

    if Teff_Grid[optT] == 4500:
        logg_Grid = np.array([2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0])
        optG = (abs(logg - logg_Grid)).argmin()

    if Teff_Grid[optT] == 5000:
        logg_Grid = np.array([2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0])
        optG = (abs(logg - logg_Grid)).argmin()

    if Teff_Grid[optT] == 5500:
        logg_Grid = np.array([3.0, 3.5, 4.0, 4.5, 5.0])
        optG = (abs(logg - logg_Grid)).argmin()

    if Teff_Grid[optT] == 5777:
        logg_Grid = [4.4]
        optG = 0

    if Teff_Grid[optT] == 6000:
        logg_Grid = np.array([3.5, 4.0, 4.5])
        optG = (abs(logg - logg_Grid)).argmin()

    if Teff_Grid[optT] == 6500:
        logg_Grid = [4.0, 4.5]
        optG = (abs(logg - logg_Grid)).argmin()

    if Teff_Grid[optT] == 7000:
        logg_Grid = [4.5]
        optG = 0

    # ==== Select Teff and Log g
    mtxt = M_H_Grid_load[optM]
    Ttxt = "{:2.0f}".format(Teff_Grid[optT] / 100)
    if (Teff_Grid[optT] == 5777):
        Ttxt = "{:4.0f}".format(Teff_Grid[optT])

    Gtxt = "{:2.0f}".format(logg_Grid[optG] * 10)
    file = 'mmu_t' + Ttxt + 'g' + Gtxt + 'm' + mtxt + 'v05.flx'
    model = file
    header = file
    #  if (header eq 0) then goto,skipthis 
    sav = readsav(direc + file)
    ws = sav['mmd'].lam[0]  # wavelength
    f = sav['mmd'].flx
    Teff_model = Teff_Grid[optT]
    logg_model = logg_Grid[optG]
    MH_model = str(M_H_Grid[optM])
    print('  ' + header)

    f0 = f[0]
    f1 = f[1]
    f2 = f[2]
    f3 = f[3]
    f4 = f[4]
    f5 = f[5]
    f6 = f[6]
    f7 = f[7]
    f8 = f[8]
    f9 = f[9]
    f10 = f[10]

    # Mu from grid
    # 0.00000    0.0100000    0.0500000     0.100000     0.200000     0.300000   0.500000     0.700000     0.800000     0.900000      1.00000
    mu = sav['mmd'].mu

    # =============
    # HST, GTC - load response function and interpolate onto kurucz model grid
    # =============
    if grating == 'G430L':
        sav = readsav(dirsen + 'G430L.sensitivity.sav')  # wssens,sensitivity
        wssens = sav['wssens']
        sensitivity = sav['sensitivity']
        wdel = 3

    if grating == 'G750M':
        sav = readsav(dirsen + 'G750M.sensitivity.sav')  # wssens, sensitivity
        wssens = sav['wssens']
        sensitivity = sav['sensitivity']
        wdel = 0.554

    if grating == 'G750L':
        sav = readsav(dirsen + 'G750L.sensitivity.sav')  # wssens, sensitivity
        wssens = sav['wssens']
        sensitivity = sav['sensitivity']
        wdel = 4.882

    if grating == 'G141':  # http://www.stsci.edu/hst/acs/analysis/reference_files/synphot_tables.html
        sav = readsav(dirsen + 'G141.WFC3.sensitivity.sav')  # wssens, sensitivity
        wssens = sav['wssens']
        sensitivity = sav['sensitivity']
        wdel = 1

    if grating == 'G102':  # http://www.stsci.edu/hst/acs/analysis/reference_files/synphot_tables.html
        sav = readsav(dirsen + 'G141.WFC3.sensitivity.sav')  # wssens, sensitivity
        wssens = sav['wssens']
        sensitivity = sav['sensitivity']
        wdel = 1

    if grating == 'R500B':
        sav = readsav(dirsen + 'R500B.sensitivity.sav')  # wssens, sensitivity
        wssens = sav['wssens']
        sensitivity = sav['sensitivity']
        wdel = 3.78201

    if grating == 'R500R':
        sav = readsav(dirsen + 'R500R.sensitivity.sav')  # wssens, sensitivity
        wssens = sav['wssens']
        sensitivity = sav['sensitivity']
        wdel = 4.88

    wsHST = wssens
    wsHST = np.concatenate((np.array([wsHST[0] - wdel - wdel, wsHST[0] - wdel]),
                            wsHST,
                            np.array([wsHST[len(wsHST) - 1] + wdel,
                                      wsHST[len(wsHST) - 1] + wdel + wdel])))

    respoutHST = sensitivity / np.max(sensitivity)
    respoutHST = np.concatenate((np.zeros(2), respoutHST, np.zeros(2)))

    inter_resp = interp1d(wsHST, respoutHST, bounds_error=False, fill_value=0)
    respout = inter_resp(ws)  # interpolate sensitivity curve onto model wavelength grid

    wsdata = np.concatenate((np.array([wsdata[0] - wdel - wdel, wsdata[0] - wdel]),
                             wsdata,
                             np.array([wsdata[len(wsdata) - 1] + wdel,
                                       wsdata[len(wsdata) - 1] + wdel + wdel])))
    respwavebin = wsdata / wsdata * 0.0
    widek = widek + 2  # need to add two indicies to compensate for padding with 2 zeros
    respwavebin[widek] = 1.0
    data_resp = interp1d(wsdata, respwavebin, bounds_error=False, fill_value=0)
    reswavebinout = data_resp(ws)  # interpolate data onto model wavelength grid
    # Trim elements that are not needed in calculation
    low = np.where(ws >= wsdata[0])[0].min()
    high = np.where(ws <= wsdata[len(wsdata) - 1])[0].max()
    ws2 = ws
    ws3 = ws
    fcalc = np.array([f0, f1, f2, f3, f4, f5, f6, f7, f8, f9, f10])
    phot1 = np.zeros(11)

    for i in range(11):  # do begin & $; loop over spectra at diff angles
        fcal = fcalc[i, :]
        Tot = int_tabulated(ws, ws * respout * reswavebinout)
        phot1[i] = (int_tabulated(ws, ws * respout * reswavebinout * fcal, sort=True)) / Tot

    yall = phot1 / phot1[10]
    Co = np.zeros((6, 4))

    A = [0.0, 0.0, 0.0, 0.0]  # c1, c2, c3, c4
    x = mu[1:]
    y = yall[1:]
    weights = x / x

    # start fitting models
    fitter = LevMarLSQFitter()

    corot_4_param = nonlinear_limb_darkening()
    corot_4_param = fitter(corot_4_param, x, y)
    c1, c2, c3, c4 = corot_4_param.parameters

    corot_3_param = nonlinear_limb_darkening()
    corot_3_param.c0.fixed = True  # 3 param is just 4 param with c0 = 0.0
    corot_3_param = fitter(corot_3_param, x, y)
    cp1, cp2, cp3, cp4 = corot_3_param.parameters

    quadratic = quadratic_limb_darkening()
    quadratic = fitter(quadratic, x, y)
    aLD, bLD = quadratic.parameters

    linear = nonlinear_limb_darkening()
    linear.c0.fixed = True
    linear.c2.fixed = True
    linear.c3.fixed = True
    linear = fitter(linear, x, y)
    uLD = linear.c1.value

    print("4param \t{:0.8f}\t{:0.8f}\t{:0.8f}\t{:0.8f}".format(c1, c2, c3, c4))
    print("3param \t{:0.8f}\t{:0.8f}\t{:0.8f}".format(cp2, cp3, c4))
    print("Quad \t{:0.8f}\t{:0.8f}".format(aLD, bLD))
    print("Linear \t{:0.8f}".format(uLD))

    return uLD, c1, c2, c3, c4, cp1, cp2, cp3, cp4, aLD, bLD


def int_tabulated(X, F, sort=False):
    Xsegments = len(X) - 1

    # Sort vectors into ascending order.
    if not sort:
        ii = np.argsort(X)
        X = X[ii]
        F = F[ii]

    while (Xsegments % 4) != 0:
        Xsegments = Xsegments + 1

    Xmin = np.min(X)
    Xmax = np.max(X)

    # Uniform step size.
    h = (Xmax + 0.0 - Xmin) / Xsegments
    # Compute the interpolates at Xgrid.
    # x values of interpolates >> Xgrid = h * FINDGEN(Xsegments + 1L) + Xmin
    z = splev(h * np.arange(Xsegments + 1) + Xmin, splrep(X, F))

    # Compute the integral using the 5-point Newton-Cotes formula.
    ii = (np.arange((len(z) - 1) / 4, dtype=int) + 1) * 4
    return np.sum(2.0 * h * (7.0 * (z[ii - 4] + z[ii]) + 32.0 * (z[ii - 3] + z[ii - 1]) + 12.0 * z[ii - 2]) / 45.0)


@custom_model
def nonlinear_limb_darkening(x, c0=0.0, c1=0.0, c2=0.0, c3=0.0):
    model = (1. - (c0 * (1. - x ** (1. / 2)) + c1 * (1. - x ** (2. / 2)) + c2 * (1. - x ** (3. / 2)) + c3 * (
            1. - x ** (4. / 2))))
    return model


@custom_model
def quadratic_limb_darkening(x, aLD=0.0, bLD=0.0):
    model = 1. - aLD * (1. - x) - bLD * (1. - x) ** (4. / 2.)
    return model


if __name__ == '__main__':
    dirsen = '/Users/ilaginja/Documents/Git/HST_Marginalization/Limb-darkening/'
    direc = '/Users/ilaginja/Documents/Git/HST_Marginalization/Limb-darkening/3DGrid/'
    wavelength = np.loadtxt('W17_wavelength_test_data.txt', skiprows=3)

    # These numbers represent specific points in the grid for now. This will be updated to automatic grid selection soon.
    FeH = 2  # Fe/H = -0.25
    Teff = 139  # logg = 4.2, Teff = 6550 K - logg is incorporated into the temperature selection for now.
    logg = 4.2
    grating = 'G141'
    wsdata = wavelength
    widek = np.arange(len(wavelength))

    result = limb_fit_3D_choose(grating, widek, wsdata, FeH, Teff, logg, dirsen, direc)
