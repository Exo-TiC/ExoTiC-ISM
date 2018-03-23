"""
This code is based on Hannah Wakeford's IDL code for lightcurve extraction with marginalization over a set of systematic models.
The original IDL scipts used are
G141_lightcurve_circle.pro - the translation of this code is in the G141_lightcurve_circle() function
W17_lightcurve_test.pro - the translation of this code is in the main() function

IDL is weird about double vs. single precision floats.
Everything in Python is double by default, but I believe single in IDL
The mixing results in rounding errors that make it hard to verify code
between the two so there a many instances of explicity declaring float64/float32
in an attempt to be consistent with the original IDL code.

IDL's WHERE function also returns -1 if nothing is found vs python returning an empty array.  There are cases where this
is important and is taken into account in the occulation functions.

Running python G141_lightcurve_circle.py from the command line will execute the main() function.
The code has only been testted significantly up to the first attempt at fitting the transit models, even that may contain
yet to be discovered bugs.  This point is marked in the code.  Everything after that point was a best attempt at 
quick translation from IDL. Running the code end to end does NOT produce consistent results with the IDL code so there are 
definitely bugs somewhere.

The python code uses a python translation of the IDL MPFIT library instead of built LM fitters because for some reason
neither the scipt least_squares method, the Astropy wrapper, or the lmfit package find the same minimum as the IDL code.
The python translation of MPFIT is consistent with the IDL code.  In theory, all of these packages use the same method
so there may be some tuning parameters that need to be adjusted to agree with MPFIT (error tolerance, etc.).
The python translation of mpfit (mpfit.py) comes from https://github.com/scottransom/presto/blob/master/lib/python/mpfit.py

limb_darkening.py contains a python translation of the 3D limb darkening code in the original IDL.  It does use Astropy for
fitting the models.  Again, the two are not exactly consistent but in this case the difference is small (good to about 3 decimals).

Inital translation of Python to IDL was done by Matthew Hill mhill92@gmail.
"""

from mpfit import mpfit
import numpy as np
from limb_darkening import limb_fit_3D_choose
import hstmarg


def G141_lightcurve_circle(x, y, err, sh, data_params, LD3D, wavelength, grid_selection, out_folder, run_name, plotting):
    """ ;+
    NAME:
       G141_LIGHTCURVE_CIRCLE
  
    AUTHOR:
     Hannah R. Wakeford,
     stellarplanet@gmail.com

    CITATIONS:
     This procedure follows the method outlined in Wakeford, et
     al. (2016, ApJ, 819, 1), using marginalisation across a stochastic
     grid of models.
     The program makes use of the analytic transit model in Mandel &
     Agol (2002, ApJ Letters, 580, L171-175)
     and Lavenberg-Markwardt least squares minimisation using the IDL
     routine MPFIT (Markwardt, 2009, Book:Astronomical Data Analysis
     Software and Systems XVIII, 411, 251, Astronomical Society of
     the Pacific Conference Series) 
     Here a 4-parameter limb darkening law is used as outlined in
     Claret, 2010 and Sing et al. 2010. 

    PURPOSE:
     Perform Levenberg-Marquardt least-squares minimization across a
     grid of stochastic systematic models to produce marginalised
     transit parameters given a WFC3 G141 lightcurve for a specified
     wavelength range. 
     
    MAJOR PROGRAMS INCLUDED IN THIS ROUTINE:
     KURUCZ LIMB-DARKENING procedure (kurucz_limb_fit_any.pro or limb_fit_3D_choose.pro)
                           This requires the
                           G141.WFC3.sensitivity.sav file,
                           template.sav, kuruczlist.sav, and the
                           kurucz folder with all models
     MANDEL & AGOL (2002) transit model (occultnl.pro)
     GRID OF SYSTEMATIC MODELS for WFC3 to test against the data
                       (wfc3_systematic_model_grid_selection.pro)
     IMPACT PARAMETER caluclated if given an eccentricity (tap_transite2.pro)

    CALLING SEQUENCE:
                   G141_lightcurve_circle, x, y, err, sh, data_params, LD3D, wavelength, grid_selection, out_folder, run_name, plotting

    INPUTS:
     X - array of times

     Y - array of normalised flux values equal to the length of the x array.

     ERR - array of error values corresponding to the flux values in
           y

     SH - array corresponding to the shift in wavelength position on
          the detector throughout the visit. (same length as x, y,
          and err)


     DATA_PARAMS - priors for each parameter used in the fit passed in
                an array in the form
                data_params = [rl,epoch,inclin,MsMpR,ecc,omega,Per,FeH,Teff,logg]

                rl - transit depth  (Rp/R*)
                epoch - center of transit time (in MJD)
                inclin - inclination of the planetary orbit
                MsMpR - density of the system where MsMpR =
                        (Ms+Mp)/(R*^3D0) this can also be calculated
                        from the a/R* following
                        constant1 = (G*Per*Per/(4*!pi*!pi))^(1D0/3D0) 
                        MsMpR = (a_Rs/constant1)^3D0
                ecc - eccentricity of the system
                omega - omega of the system (degrees)
                Per - Period of the planet in days
                FeH - Stellar metallicity index
                      M_H=[-5.0(14),-4.5(13),-4.0(12),-3.5(11),-3.0(10),
                       -2.5(9),-2.0(8),-1.5(7),-1.0(5),-0.5(3),-0.3(2),
                       -0.2(1),-0.1(0),0.0(17),0.1(20),0.2(21),0.3(22),
                       0.5(23),1.0(24)]
                Teff - Stellar Temperature index
                    FOR stellar log(g) = 4.0
                       Teff=[3500(8),3750(19),4000(30),4250(41),4500(52),
                       4750(63),5000(74),5250(85),5500(96),5750(107),6000(118),
                       6250(129),6500(139)]
                    FOR stellar log(g) = 4.5
                       Teff=[3500(9),3750(20),4000(31),4250(42),4500(53),
                       4750(64),5000(75),5250(86),5500(97),5750(108),6000(119),
                       6250(129),6500(139)]
                    FOR stellar log(g) = 5.0
                       Teff=[3500(10),3750(21),4000(32),4250(43),4500(54),
                       4750(65),5000(76),5250(87),5500(98),5750(109),6000(120),
                       6250(130),6500(140)]
    
     WAVELENGTH: array of wavelengths covered to compute y

     GRID_SELECTION: 'fix_time', 'fit_time', 'fit_inclin',
                                'fit_msmpr', 'fit_ecc'

     OUT_FOLDER: string of folder path to save the data too. 
                 e.g. '/Volumes/DATA1/user/HST/Planet/sav_file/'

     RUN_NAME - string of the individual run name
                 e.g. 'whitelight', or 'bin1', or '115-120micron'

    """
    print('Welcome to the Wakeford WFC3 analysis pipeline. All data will now be marginalised according to quality and usefulness.')
    print('If results are not as expected - a new observation stratgy is reccomended, or you can bloody well wait for '
          'JWST to make your lives better. PRESS control+C now if this was an unintended action.')

    # SET THE CONSTANTS 
    #constant = [GAIN, READNOISE, G, JD, DAY_TO_SEC, Rjup, Rsun, MJup, Msun, HST_SECOND, HST_PERIOD]
    constant = [2.5,20.2, np.float64(6.67259e-11), 2400000.5, 86400, np.float64(7.15e7), np.float64(6.96e8), np.float64(1.9e27),
    np.float64(1.99e30), 5781.6, 0.06691666]
    JD = np.float64(2400000.5)              
    Gr = np.float64(6.67259e-11)
    HSTper = np.float64(96.36) / (np.float64(24)*np.float64(60))

    # TOTAL NUMBER OF EXPOSURES IN THE OBSERVATION
    nexposure = len(x)

    # SET THE PLANET STARTING PARAMETERS
    # data_params = [rl,epoch,inclin,MsMpR,ecc,omega,Per,FeH,Teff]
    rl = data_params[0]
    epoch = data_params[1]
    inclin = data_params[2] * ((2*np.pi)/360)
    MsMpR = data_params[3]
    ecc = data_params[4]
    omega = data_params[5] * ((2*np.pi)/360)
    Per = data_params[6] * constant[4]
    constant1 = ((constant[2]*Per*Per)/(4*np.pi*np.pi))**(1/3)
    aval = constant1*(MsMpR)**(1/3)

    FeH = data_params[7]
    Teff = data_params[8]

    flux0 = y[0]
    T0 = x[0]

    img_date = x

    # SET THE STARTING PARAMETERS FOR THE SYSTEMATICS & LD
    m = 0.0         # Linear Slope
    HSTP1 = 0.0     # Correct HST orbital phase
    HSTP2 = 0.0     # Correct HST orbital phase^2
    HSTP3 = 0.0     # Correct HST orbital phase^3
    HSTP4 = 0.0     # Correct HST orbital phase^4
    xshift1 = 0.0   # X-shift in wavelength
    xshift2 = 0.0   # X-shift in wavelength^2
    xshift3 = 0.0   # X-shift in wavelength^3
    xshift4 = 0.0   # X-shift in wavelength^4

    print('As you have clearly decided to proceed, we will now determine the stellar limb-darkening parameters given the'
          ' input stellar metallicity and effective temperature which was selected dependent on the stellar log(g).')

    #......................................
    #     LIMB DARKENING     ;
    if (LD3D == 'no'):
        kdir = '' 
        grating = 'G141'
        wsdata = wavelength
        widek = np.arange(len(wavelength))
        k_metal = data_params[6]
        k_temp = data_params[7]

        uLD, c1, c2, c3, c4, cp1, cp2, cp3, cp4, aLD, bLD = limb_fit_kurucz_any(kdir, grating, widek, wsdata, k_metal, k_temp)

    if (LD3D == 'yes'):
        # Change these to your specific
        # dirsen  = raw_input("Directory for limb darkening sensitivity files: ")
        # direc = raw_input("Directory for limb darkening stellar models files: ")
        dirsen='/Users/ilaginja/Documents/Git/HST_Marginalization/Limb-darkening/'
        direc='/Users/ilaginja/Documents/Git/HST_Marginalization/Limb-darkening/3DGrid/'
        grating = 'G141'
        wsdata = wavelength
        widek = np.arange(len(wavelength))
        M_H = data_params[6]
        Teff = data_params[7]
        logg = data_params[8]

        uLD, c1, c2, c3, c4, cp1, cp2, cp3, cp4, aLD, bLD = limb_fit_3D_choose(grating, widek, wsdata, M_H, Teff, logg, dirsen, direc)

    print('Thank you for your patience. Next up is the lightcurve fitting with MPFIT using L-M minimization.')
    #....................................
    #PLACE ALL THE PRIORS IN AN ARRAY
    p0 = [rl, flux0, epoch, inclin, MsMpR, ecc, omega, Per, T0, c1, c2, c3, c4, m, HSTP1, HSTP2, HSTP3, HSTP4, xshift1, xshift2, xshift3, xshift4]

    # SELECT THE SYSTEMATIC GRID OF MODELS TO USE ;
    grid = hstmarg.wfc3_systematic_model_grid_selection(grid_selection)
    nsys, nparams = grid.shape

    #  SET UP THE ARRAYS  ;
    # sav arrays for the first step throught to get the err inflation
    w_scatter = np.zeros(nsys)
    w_params = np.zeros((nsys, nparams))
    # final sav arrays for each systematic model
    # stats
    sys_stats = np.zeros((nsys, 5)) 
    # img_date
    sys_date = np.zeros((nsys, nexposure))
    # phase
    sys_phase = np.zeros((nsys, nexposure))
    # raw lightcurve flux
    sys_rawflux = np.zeros((nsys, nexposure))
    sys_rawflux_err = np.zeros((nsys, nexposure))
    # corrected lightcurve flux
    sys_flux = np.zeros((nsys, nexposure))
    sys_flux_err = np.zeros((nsys, nexposure))
    # residuals
    sys_residuals = np.zeros((nsys, nexposure))
    # smooth model
    sys_model = np.zeros((nsys, 4000))
    # smooth phase
    sys_model_phase = np.zeros((nsys, 4000))
    # systematic model
    sys_systematic_model = np.zeros((nsys, nexposure))
    # parameters
    sys_params = np.zeros((nsys, nparams))
    # parameter errors
    sys_params_err = np.zeros((nsys, nparams))
    # depth
    sys_depth = np.zeros((nsys))
    # depth error
    sys_depth_err = np.zeros((nsys))
    # transit time
    sys_epoch = np.zeros((nsys))
    # transit time error
    sys_epoch_err = np.zeros((nsys))
    # evidence AIC
    sys_evidenceAIC = np.zeros((nsys))
    # evidence BIC
    sys_evidenceBIC = np.zeros((nsys))

    #'----------      ------------     ------------'
    #'          1ST FIT         '
    #'----------      ------------     ------------'
    print('..........................................')
    print('The first run through of the data for each of the WFC3 stochastic models outlined in Table 2 of Wakeford et al. (2016a) is now being preformed. Using this fit we will scale the uncertainties you input to incorporate the inherent scatter in the data for each model.')
    for s in range(0, nsys):
        print('................................')
        print(' SYSTEMATIC MODEL {}'.format(s))
        systematics = grid[s,:]
        print(systematics)
        print('  ')

        HSTphase = np.zeros(nexposure)
        HSTphase = (img_date - T0) / constant[10]                       
        phase2 = np.floor(HSTphase)
        HSTphase = HSTphase - phase2
        k = np.where(HSTphase > 0.5)[0]
        HSTphase[k] -= 1.0
        # This is equivalent to the two lines below
        # if len(k) > 0:
        #     HSTphase[k] = HSTphase[k] - 1.0

        phase = (img_date - epoch) / (Per / constant[4])

        phase2 = np.floor(phase)
        phase = phase - phase2
        a = np.where(phase > 0.5)[0]
        phase[a] -= 1.0
        # same as above
        # if (a[0] != -1):
        #     phase[a] = phase[a] - 1.0

        #      MPFIT - ONE       
        p0 = [rl,flux0,epoch,inclin,MsMpR,ecc,omega,Per,T0,c1,c2,c3,c4,m,HSTP1,HSTP2,HSTP3,HSTP4,xshift1,xshift2,xshift3,xshift4]
        parinfo = []
        for i, value in enumerate(p0):
            info = {'value':0., 'fixed':0, 'limited':[0,0], 'limits' :[0.,0.]} 
            info['value'] = np.float32(value)
            info['fixed'] = systematics[i]
            parinfo.append(info)
    
        fa = {'x':x, 'y':y, 'err':err, 'sh':sh}
        mpfit_result = mpfit(hstmarg.transit_circle, functkw=fa, parinfo=parinfo)
        nfree = sum([not p['fixed'] for p in parinfo])

        # The python mpfit does not populate the covariance matrix correctly so mpfit_result.perror is not correct
        # the mpfit_result.covar is filled sequentiall by row with the values of only free parameters, this works if all parameters are free
        # but not if some are kept fixed.  The code below should work to get the proper error values i.e. what should be the diagonals
        # of the covariance

        pcerror = mpfit_result.perror # this is how it should be done if it was right
        pcerror = np.zeros_like(mpfit_result.perror)
        pcerror[:nfree] = np.sqrt(np.diag(mpfit_result.covar.flatten()[:nfree**2].reshape(nfree, nfree))) # this might work...

        bestnorm = mpfit_result.fnorm # chi squared of resulting fit
        BIC = bestnorm + nfree * np.log(len(x))
        AIC = bestnorm + nfree
        DOF = len(x) - sum([p['fixed'] != 1 for p in parinfo]) # nfree
        CHI = bestnorm

        # Redefine all of the parameters given the MPFIT output
        w_params[s, :] = mpfit_result.params

        rl = mpfit_result.params[0]
        rl_err = pcerror[0]
        flux0 = mpfit_result.params[1]
        flux0_err = pcerror[1]
        epoch = mpfit_result.params[2]
        epoch_err = pcerror[2]
        inclin = mpfit_result.params[3]
        inclin_err = pcerror[3]
        msmpr = mpfit_result.params[4]
        msmpr_err = pcerror[4]
        ecc = mpfit_result.params[5]
        ecc_err = pcerror[5]
        omega = mpfit_result.params[6]
        omega_err = pcerror[6]
        per = mpfit_result.params[7]
        per_err = pcerror[7]
        T0 = mpfit_result.params[8]
        T0_err = pcerror[8]
        c1 = mpfit_result.params[9]
        c1_err = pcerror[9]
        c2 = mpfit_result.params[10]
        c2_err = pcerror[10]
        c3 = mpfit_result.params[11]
        c3_err = pcerror[11]
        c4 = mpfit_result.params[12]
        c4_err = pcerror[12]
        m = mpfit_result.params[13]
        m_err = pcerror[13]
        hst1 = mpfit_result.params[14]
        hst1_err = pcerror[14]
        hst2 = mpfit_result.params[15]
        hst2_err = pcerror[15]
        hst3 = mpfit_result.params[16]
        hst3_err = pcerror[16]
        hst4 = mpfit_result.params[17]
        hst4_err = pcerror[17]
        sh1 = mpfit_result.params[18]
        sh1_err = pcerror[18]
        sh2 = mpfit_result.params[19]
        sh2_err = pcerror[19]
        sh3 = mpfit_result.params[20]
        sh3_err = pcerror[20]
        sh4 = mpfit_result.params[21]
        sh4_err = pcerror[21]

        # Recalculate a/R*
        constant1 = (constant[2]*Per*Per/(4*np.pi*np.pi))**(1/3.)
        aval = constant1*(MsMpR)**(1/3.)

        print('Transit depth = {} +/- {}     centered at  {}'.format(rl, rl_err, epoch))

        # OUTPUTS
        # Re-Calculate each of the arrays dependent on the output parameters
        phase = (x - epoch) / (Per / 86400)
        phase2 = np.floor(phase)
        phase = phase - phase2
        a = np.where(phase > 0.5)[0]
        if len(a) > 0: 
            phase[a] = phase[a] - 1.0

        HSTphase = (x - T0) / constant[10]                        
        phase2 = np.floor(HSTphase)
        HSTphase = HSTphase - phase2
        k = np.where(HSTphase > 0.5)[0]
        if len(k) > 0:
            HSTphase[k] = HSTphase[k] - 1.0

        #...........................................
        # TRANSIT MODEL fit to the data
        # Calculate the impact parameter based on the eccentricity function
        b0 = (Gr * Per * Per / (4 * np.pi * np.pi))**(1/3.) * (MsMpR**(1/3.)) * np.sqrt((np.sin(phase*2*np.pi))**2 + (np.cos(inclin)*np.cos(phase*2*np.pi))**2)
        mulimb01, mulimbf1 = hstmarg.occultnl(rl, c1, c2,c3, c4, b0)
        b01 = np.copy(b0)
        systematic_model = (phase*m + 1.0) * (HSTphase*hst1 + HSTphase**2. * hst2 + HSTphase**3.*hst3 + HSTphase**4.*hst4 + 1.0) * (sh*sh1 + sh**2.*sh2 + sh**3.*sh3 + sh**4.*sh4 + 1.0)

        w_model = mulimb01 * flux0 * systematic_model

        w_residuals = (y - w_model)/flux0

        corrected_data = y / (flux0 * systematic_model)

        w_scatter[s] = (np.std(w_residuals))
        print('Scatter on the residuals = {}'.format(w_scatter[s]))

        #..........................................
        #..........................................
        # CHOPPING OUT THE BAD PARTS
        #..........................................

        cut_down = 2.57 # Play around with this value if you want. 
        # This currently just takes the data that is not good and replaces it with a null value while inflating the uncertainty using the standard deviation, although this is only a very timy inflation of the uncertainty and I need to find a more statistically riggrous way to do this. 
        # Ultimately, I would like it to remove the point completely and reformat the x, y, err and sh arrays to account for the new shape of the array.

        # if plotting:
        #     window,0, title=s
        #     plot, phase, w_residuals, psym=4, ystyle=3, xstyle=3, yrange=[-0.01,0.01]
        #     hline, 0.0+STDDEV(w_residuals)*cut_down, color=cgcolor('RED') 
        #     hline, 0.0
        #     hline, 0.0-STDDEV(w_residuals)*cut_down, color=cgcolor('RED') 

        # remove
        bad_up = np.where(w_residuals > (0.0 + np.std(w_residuals) * 3))
        bad_down = np.where(w_residuals < (0.0 - np.std(w_residuals) * 3))

        print('up {}'.format(bad_up))
        print('down {}'.format(bad_down))

        y[bad_up] = y[bad_up] - np.std(w_residuals) * cut_down
        err[bad_up] = err[bad_up] * (1+np.std(w_residuals))

        y[bad_down] = y[bad_down] + np.std(w_residuals) * cut_down
        err[bad_down] = err[bad_down] * (1 + np.std(w_residuals))

        # remove
        bad_up = np.where(w_residuals > (0.0 + np.std(w_residuals) * cut_down))
        bad_down = np.where(w_residuals < (0.0 - np.std(w_residuals) * cut_down))

        print('up {}'.format(bad_up))
        print('down {}'.format(bad_down))

        y[bad_up] = y[bad_up] - np.std(w_residuals) * cut_down
        err[bad_up] = err[bad_up] * (1+np.std(w_residuals))

        y[bad_down] = y[bad_down] + np.std(w_residuals) * cut_down
        err[bad_down] = err[bad_down] * (1 + np.std(w_residuals))

        # if plotting:
        #     window,2, title=s
        #     plot, phase, corrected_data, ystyle=3, xstyle=3, psym=4
        #     oplot, phase, y, psym=1
        #     oploterror, phase, corrected_data, err, psym=4, color=321321
        #     oplot, phase, systematic_model, color=5005005, psym=2

    #########################################################################################################################
    #########################################################################################################################
    #        NOT SURE OF THE VALIDITY OF THE CODE AFTER THIS POINT.  IT'S JUST A QUICK TRANSLATION OF IDL. NOT TESTED.      #
    #########################################################################################################################
    #########################################################################################################################

    #..........................................
    #..........................................
    # SECOND RUN THROUGH with MPFIT
    #..........................................
    print('..........................................')
    print('As we seem to have found how shit each of the systematic models are at fitting the data compared to a Mandel&Agol transit model we can now use the scatter on their residuals to inflate the uncertainties for the data. We will then go ahead and refit for each systematic model if that is okay with you. If not control+c is still a valid option.')
    for s in range(0, nsys):
        print('................................')
        print(' SYSTEMATIC MODEL {}'.format(s))
        systematics = grid[s,:]
        print(systematics)
        print('  ')

        err *= (1.0 - w_scatter[s])

        p0 = w_params[s,:]
        T0 = p0[8]
        epoch = p0[2]
        Per = p0[7]


        HSTphase = np.zeros(nexposure)
        HSTphase = (x - T0) / constant[10]                       
        phase2 = np.floor(HSTphase)
        HSTphase = HSTphase - phase2
        k = np.where(HSTphase > 0.5)[0]
        if (k[0] != -1):
            HSTphase[k] = HSTphase[k] - 1.0

        phase = np.zeros(nexposure) 
        for j in range(nexposure):
            phase[j] = (x[j] - epoch) / (Per / constant[4])

        phase2 = np.floor(phase)
        phase = phase - phase2
        a = np.where(phase > 0.5)[0]
        if (a[0] != -1):
            phase[a] = phase[a] - 1.0

        #      MPFIT - ONE       
        parinfo = []
        print(p0.shape[0])
        for i, value in enumerate(p0):
            info = {'value':0., 'fixed':0, 'limited':[0,0], 'limits' :[0.,0.]} 
            info['value'] = value
            info['fixed'] = systematics[i]
            parinfo.append(info)
    
        fa = {'x':x, 'y':y, 'err':err, 'sh':sh}
        mpfit_result = mpfit(hstmarg.transit_circle, functkw=fa, parinfo=parinfo)
        nfree = sum([not p['fixed'] for p in parinfo])
        # The python mpfit does not populate the covariance matrix correctly so m.perror is not correct
        pcerror = mpfit_result.perror # this is how it should be done if it was right
        pcerror = np.zeros_like(mpfit_result.perror)
        pcerror[:nfree] = np.sqrt(np.diag(mpfit_result.covar.flatten()[:nfree**2].reshape(nfree, nfree))) # this might work...

        bestnorm = mpfit_result.fnorm # chi squared of resulting fit
        BIC = bestnorm + nfree * np.log(len(x))
        AIC = bestnorm + nfree
        DOF = len(x) - sum([p['fixed'] != 1 for p in parinfo]) # nfree
        CHI = bestnorm

        # EVIDENCE BASED on the AIC and BIC
        Mpoint = nfree
        Npoint = len(x)
        sigma_points = np.median(err)

        evidence_BIC = - Npoint * np.log(sigma_points) - 0.5 * Npoint * np.log(2*np.pi) - 0.5 * BIC
        evidence_AIC = - Npoint * np.log(sigma_points) - 0.5 * Npoint * np.log(2*np.pi) - 0.5 * AIC

        # Redefine all of the parameters given the MPFIT output

        rl = mpfit_result.params[0]
        rl_err = pcerror[0]
        flux0 = mpfit_result.params[1]
        flux0_err = pcerror[2]
        epoch = mpfit_result.params[2]
        epoch_err = pcerror[2]
        inclin = mpfit_result.params[3]
        inclin_err = pcerror[3]
        msmpr = mpfit_result.params[4]
        msmpr_err = pcerror[4]
        ecc = mpfit_result.params[5]
        ecc_err = pcerror[5]
        omega = mpfit_result.params[6]
        omega_err = pcerror[6]
        per = mpfit_result.params[7]
        per_err = pcerror[7]
        T0 = mpfit_result.params[8]
        T0_err = pcerror[8]
        c1 = mpfit_result.params[9]
        c1_err = pcerror[9]
        c2 = mpfit_result.params[10]
        c2_err = pcerror[10]
        c3 = mpfit_result.params[11]
        c3_err = pcerror[11]
        c4 = mpfit_result.params[12]
        c4_err = pcerror[12]
        m = mpfit_result.params[13]
        m_err = pcerror[13]
        HSTP1 = mpfit_result.params[14]
        HSTP1_err = pcerror[14]
        HSTP2 = mpfit_result.params[15]
        HSTP2_err = pcerror[15]
        HSTP3 = mpfit_result.params[16]
        HSTP3_err = pcerror[16]
        HSTP4 = mpfit_result.params[17]
        HSTP4_err = pcerror[17]
        xshift1 = mpfit_result.params[18]
        xshift1_err = pcerror[18]
        xshift2 = mpfit_result.params[19]
        xshift2_err = pcerror[19]
        xshift3 = mpfit_result.params[20]
        xshift3_err = pcerror[20]
        xshift4 = mpfit_result.params[21]
        xshift4_err = pcerror[21]

        # Recalculate a/R*
        constant1 = (constant[2]*Per*Per/(4*np.pi*np.pi))**(1/3.)
        aval = constant1*(MsMpR)**(1/3.)

        print('Transit depth = {} +/- {}     centered at  {}'.format(rl, rl_err, epoch))

        # OUTPUTS
        # Re-Calculate each of the arrays dependent on the output parameters
        phase = (x - epoch)/ (Per / 86400) 
        phase2 = np.floor(phase)
        phase = phase - phase2
        a = np.where(phase > 0.5)[0]
        if (len(a) > 0): 
            phase[a] = phase[a] - 1.0

        HSTphase = (x - T0) / constant[10]                        
        phase2 = np.floor(HSTphase)
        HSTphase = HSTphase - phase2
        k = np.where(HSTphase > 0.5)[0]
        if (len(k) > 0):
            HSTphase[k] = HSTphase[k] - 1.0

        #...........................................
        # TRANSIT MODEL fit to the data
        # Calculate the impact parameter based on the eccentricity function
        b0 = (Gr * Per * Per / (4 * np.pi * np.pi))**(1/3.) * (MsMpR**(1/3.)) * np.sqrt((np.sin(phase*2*np.pi))**2 + (np.cos(inclin)*np.cos(phase*2*np.pi))**2)
        mulimb01, mulimbf1 = hstmarg.occultnl(rl, c1, c2, c3, c4, b0)
        b01 = np.copy(b0)

        #...........................................
        # SMOOTH TRANSIT MODEL across all phase
        #Calculate the impact parameter based on the eccentricity function
        x2 = np.arange(4000)*0.0001-0.2
        b0 = (Gr * Per * Per / (4 * np.pi * np.pi))**(1/3.) * (MsMpR**(1/3.)) * np.sqrt((np.sin(x2*2*np.pi))**2 + (np.cos(inclin)*np.cos(x2*2*np.pi))**2)
        mulimb02, mulimbf2 = hstmarg.occultnl(rl, c1, c2,c3, c4, b0)

        systematic_model = (phase*m + 1.0) * (HSTphase*hst1 + HSTphase**2. * hst2 + HSTphase**3.*hst3 + HSTphase**4.*hst4 + 1.0) * (sh*sh1 + sh**2.*sh2 + sh**3.*sh3 + sh**4.*sh4 + 1.0)

        fit_model = mulimb01 * flux0 * systematic_model

        residuals = (y - fit_model)/flux0

        resid_scatter = np.std(w_residuals)

        fit_data = y / (flux0 * systematic_model)

        fit_err = np.copy(err) # * (1.0 + resid_scatter)

        # IF (plotting EQ 'on') THEN BEGIN
        # window,2, title=s
        # plot, phase, y, ystyle=3, xstyle=3, psym=1
        # oplot, x2, mulimb02, color=5005005
        # oploterror, phase, fit_data, err, psym=4, color=100100100
        # ENDIF

        #.............................
        # Arrays to save to file

        # stats
        sys_stats[s,:] = [AIC, BIC, DOF, CHI, resid_scatter] 
        # img_date
        sys_date[s,:] = x
        # phase
        sys_phase[s,:] = phase
        # raw lightcurve flux
        #sys_rawflux(s,*) = y
        #sys_rawflux_err(s,*) = err
        # corrected lightcurve flux
        sys_flux[s,:] = fit_data
        sys_flux_err[s,:] = fit_err
        # residuals
        sys_residuals[s,:] = residuals
        # smooth model
        sys_model[s,:] = mulimb02
        # smooth phase
        sys_model_phase[s,:] = x2
        # systematic model
        sys_systematic_model[s,:] = systematic_model
        # parameters
        sys_params[s,:] = mpfit_result.params
        # parameter errors
        sys_params_err[s,:] = pcerror
        # depth
        sys_depth[s] = rl
        # depth error
        sys_depth_err[s] = rl_err
        # transit time
        sys_epoch[s] = epoch
        # transit time error
        sys_epoch_err[s] = epoch_err
        # evidence AIC
        sys_evidenceAIC[s] = evidence_AIC
        # evidence BIC
        sys_evidenceBIC[s] = evidence_BIC

    # SAVE, filename=out_folder+'analysis_circle_G141_'+run_name+'.sav', sys_stats, sys_date, sys_phase, sys_rawflux, sys_rawflux_err, sys_flux, sys_flux_err, sys_residuals, sys_model, sys_model_phase, sys_systematic_model, sys_params, sys_params_err, sys_depth, sys_depth_err, sys_epoch, sys_epoch_err, sys_evidenceAIC, sys_evidenceBIC
    #.......................................
    # MARGINALISATION
    a = (np.sort(sys_evidenceAIC))[::-1]
    print('TOP 10 SYSTEMATIC MODELS')
    print(a[:10])

    print(sys_evidenceAIC)
    # REFORMAT all arrays with just positive values
    pos = np.where(sys_evidenceAIC > -500)
    if len(pos) == 0:
        pos = -1
    npos = len(pos[0])
    print('POS positions = {}'.format(pos))

    count_AIC = sys_evidenceAIC[pos]

    count_depth = sys_depth[pos]
    count_depth_err = sys_depth_err[pos]

    count_epoch = sys_epoch[pos]
    count_epoch_err = sys_epoch_err[pos]

    count_residuals = sys_residuals[pos,:]
    count_date = sys_date[pos,:]
    count_flux = sys_flux[pos,:]
    count_flux_err = sys_flux_err[pos,:]
    count_phase = sys_phase[pos,:]
    count_model_y = sys_model[pos,:]
    count_model_x = sys_model_phase[pos,:]

    beta = np.min(count_AIC)
    w_q = (np.exp(count_AIC - beta))/np.sum(np.exp(count_AIC - beta))

    n01 = np.where(w_q >= 0.05)
    print('{} models have a weight over 0.1. Models:'.format(len(n01), n01, w_q[n01]))
    print('Most likely model is number {} at w_q={}'.format(np.argmax(w_q), np.max(w_q)))

    best_sys = np.max(w_q)

    rl_sdnr = np.zeros(len(w_q))
    for i in range(len(w_q)):
        rl_sdnr[i] = (np.std(count_residuals[:,i]) / np.sqrt(2)) * 1e6
    best_sys =  np.argmin(rl_sdnr)

    # Radius ratio
    rl_array = count_depth
    rl_err_array = count_depth_err

    mean_rl = np.sum(w_q*rl_array)
    bestfit_theta_rlq = rl_array
    variance_theta_rlq = rl_err_array
    variance_theta_rl = np.sqrt(np.sum(w_q * ((bestfit_theta_rlq - mean_rl)**2 + (variance_theta_rlq)**2)))
    print('Rp/R* = {} +/- {}'.format(mean_rl, variance_theta_rl))

    marg_rl = mean_rl
    marg_rl_err = variance_theta_rl

    print(marg_rl, marg_rl_err)
    print('SDNR best model = {}'.format(np.std(count_residuals[:,best_sys])/np.sqrt(2)*1e6))

    print('SDNR best = {} for model {}'.format(np.min(rl_sdnr), np.argmin(rl_sdnr)))


    # ;IF (plotting EQ 'on') THEN BEGIN
    #    window,4
    # !p.multi=[0,1,3]
    #    plot, w_q
    #    plot, rl_sdnr
    #    ploterror, rl_array, rl_err_array
    # !p.multi=[0,1,1]   

    # window,6
    # !p.multi=[0,1,3]
    # plot, sys_phase(0,*), sys_flux(0,*), psym=4, ystyle=3, yrange=[min(sys_flux(0,*))-0.001,max(sys_flux(0,*))+0.001], background=cgcolor('white'), color=cgcolor('black')

    # plot, count_phase(best_sys,*), count_flux(best_sys,*), psym=4, ystyle=3, yrange=[min(count_flux(0,*))-0.001,max(count_flux(0,*))+0.001], background=cgcolor('white'), color=cgcolor('black')
    # oplot, count_model_x(best_sys,*), count_model_y(best_sys,*), color=cgcolor('red')

    # ploterror, count_phase(best_sys,*), count_residuals(best_sys,*)*1d6, count_flux_err(best_sys,*)*1d6, psym=4, ystyle=3, yrange=[-1000,1000], background=cgcolor('white'), color=cgcolor('black')
    # hline, 0.0, linestyle=2, color=cgcolor('red')
    # hline, 0.0-(rl_sdnr(best_sys)*2.57), linestyle=1, color=cgcolor('red')
    # hline, 0.0+(rl_sdnr(best_sys)*2.57), linestyle=1, color=cgcolor('red')
    # !p.multi=[0,1,1]   

    # print(MEDIAN(count_flux_err(best_sys,*)*1d6))
    # ;ENDIF

    # Center of transit time
    epoch_array = count_epoch
    epoch_err_array = count_epoch_err

    mean_epoch = np.sum(w_q*epoch_array)
    bestfit_theta_epoch = epoch_array
    variance_theta_epochq = epoch_err_array
    variance_theta_epoch = np.sqrt(np.sum(w_q * ((bestfit_theta_epoch - mean_epoch)**2 + variance_theta_epochq**2)))
    print('Epoch = {} +/- {}'.format(mean_epoch, variance_theta_epoch))

    marg_epoch = mean_epoch
    marg_epoch_err = variance_theta_epoch
    print(marg_epoch, marg_epoch_err)

    # Inclination
    inclin_array = sys_params[:,3]
    inclin_err_array = sys_params_err[:,3]

    mean_inc = np.sum(w_q * inclin_array)
    bestfit_theta_inc = inclin_array
    variance_theta_incq = inclin_err_array
    variance_theta_inc = np.sum(w_q * ((bestfit_theta_inc - mean_inc)**2 + variance_theta_incq))
    print('inc (rads) = {} +/- {}'.format(mean_inc, variance_theta_inc))

    marg_inclin_rad = mean_inc
    marg_inclin_rad_err = variance_theta_inc
    print(marg_inclin_rad, marg_inclin_rad_err)

    inclin_arrayd = sys_params[:,3]/(2*np.pi/360)
    inclin_err_arrayd = sys_params_err[:,3]/(2*np.pi/360)

    mean_incd = np.sum(w_q * inclin_arrayd)
    bestfit_theta_incd = inclin_arrayd
    variance_theta_incdq = inclin_err_arrayd
    variance_theta_incd = np.sum(w_q * ((bestfit_theta_incd - mean_incd)**2 + variance_theta_incdq))
    print('inc (deg) = {} +/- {}'.format(mean_incd, variance_theta_incd))

    marg_inclin_deg = mean_incd
    marg_inclin_deg_err = variance_theta_incd
    print(marg_inclin_deg, marg_inclin_rad_err)

    # MsMpR
    msmpr_array = sys_params[:,4]
    msmpr_err_array = sys_params_err[:,4]

    mean_msmpr = np.sum(w_q*msmpr_array)
    bestfit_theta_msmpr = msmpr_array
    variance_theta_msmprq = msmpr_err_array
    variance_theta_msmpr = np.sum(w_q * ((bestfit_theta_msmpr - mean_msmpr)**2.0 + variance_theta_msmprq))
    print('MsMpR = {} +/- {}'.format(mean_msmpr, variance_theta_msmpr))
    mean_aor = constant1*((mean_msmpr)**0.333)
    variance_theta_aor = constant1*(variance_theta_msmpr**0.3333)/mean_aor
    print('a/R* = {} +/- {}'.format(mean_aor, variance_theta_aor))

    marg_msmpr = mean_msmpr
    marg_msmpr_err = variance_theta_msmpr
    print(marg_msmpr, marg_msmpr_err)

    marg_aors = mean_aor
    marg_aors_err = variance_theta_aor
    print(marg_aors, marg_aors_err)

    # SAVE, filename=out_folder+'analysis_circle_G141_marginalised_'+run_name+'.sav', w_q, best_sys, marg_rl, marg_rl_err, marg_epoch, marg_epoch_err, marg_inclin_rad, marg_inclin_rad_err, marg_inclin_deg, marg_inclin_deg_err, marg_msmpr, marg_msmpr_err, marg_aors, marg_aors_err, rl_sdnr, pos 


if __name__ == '__main__':
    """
    This is a translation of the W17_lightcurve_test.pro
    """
    # SET THE CONSTANTS
    dtosec = 86400
    big_G = np.float64(6.67259e-11)
    Rjup = np.float64(7.15e7)
    Rsun = np.float64(6.96e8)
    Mjup = np.float64(1.9e27)
    Msun = np.float64(1.99e30)
    HST_second = 5781.6
    HST_period = 0.06691666

    # READ in the txt file for the lightcurve data
    x, y, err, sh = np.loadtxt('../data/W17_white_lightcurve_test_data.txt', skiprows=7, unpack=True)
    wavelength = np.loadtxt('../data/W17_wavelength_test_data.txt', skiprows=3)

    # SET-UP the parameters for the subroutine
    # ---------------------
    # ;PLANET PARAMETERS
    rl = np.float64(0.12169232) # Rp/R* estimate
    epoch = np.float64(57957.970153390) # in MJD
    inclin = np.float64(87.34635) #this is converted into radians in the subroutine
    ecc = 0.0 # set to zero and not used when circular
    omega = 0.0 # set to zero and not used when circular
    Per = np.float64(3.73548535) # in days, converted to seconds in subroutine

    persec = Per * dtosec
    aor = np.float64(7.0780354) # a/r* converted to system density for the subroutine
    constant1 = (big_G*persec*persec/np.float32(4*3.1415927*3.1415927))**(1/3.)
    MsMpR = (aor/(constant1))**3

    LD3D = 'yes'
    if LD3D == 'yes':
        # These numbers represent specific points in the grid for now. This will be updated to automatic grid selection soon.
        FeH = 2 #Fe/H = -0.25
        Teff = 139 # logg = 4.2, Teff = 6550 K - logg is incorporated into the temperature selection for now.
        logg = 4.2

    elif LD3D == 'no':
        FeH = -0.25
        Teff = 6550
        logg = 4.2

    data_params = [rl, epoch, inclin, MsMpR, ecc, omega, Per, FeH, Teff, logg]
    grid_selection = 'fit_time'
    out_folder = '../outputs/Projects/lcextract/test_files/' # Need to redefine this
    run_name = 'wl_time_wm3d'
    plotting='on'

    G141_lightcurve_circle(x, y, err, sh, data_params, LD3D, wavelength, grid_selection, out_folder, run_name, plotting)
