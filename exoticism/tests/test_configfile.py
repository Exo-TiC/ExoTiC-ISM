from exoticism.config import CONFIG_INI


STANDARD_SECTIONS = ['data_paths', 'setup', 'smooth_model', 'W17', 'simple_transit', 'constants']


def test_main_sections():
    """ Check that all main sections exist. """

    for section in STANDARD_SECTIONS:
        exists = section in CONFIG_INI
        assert exists


def test_data_paths():
    """ Check that all required data paths exist. """

    data_keys = ['local_path', 'input_path', 'output_path', 'run_name']
    for key in data_keys:
        assert CONFIG_INI.has_option('data_paths', key)


def test_setup():
    """ Check that all required setup keys exist. """

    setup_keys = ['data_set', 'instrument', 'grating', 'grid_selection', 'ld_model', 'plotting', 'report']
    for key in setup_keys:
        assert CONFIG_INI.has_option('setup', key)


def test_smooth_model():
    """ Check that all keys for smooth model exist. """

    smooth_keys = ['resolution', 'half_range']
    for key in smooth_keys:
        assert CONFIG_INI.has_option('smooth_model', key)


def test_constants():
    """ Check that all keys for constants exist. """

    constants_keys = ['dtosec', 'HST_period']
    for key in constants_keys:
        assert CONFIG_INI.has_option('constants', key)


def test_planet_parameters():
    """Check that all planetary system sections have all necessary keys.

    If using a local configfile like recommended in the documentation, his test
    will only catch missing planet parameters on custom planet sections if it is
    run locally.
    """

    planet_params = ['lightcurve_file', 'wvln_file', 'rl', 'epoch', 'inclin', 'ecc',
                     'omega', 'Per', 'aor', 'metallicity', 'Teff', 'logg']
    all_sections = CONFIG_INI.sections()

    # First test the planet sections that are included by default
    for sec in ['W17', 'simple_transit']:
        for key in planet_params:
            assert CONFIG_INI.has_option(sec, key)

    # Then test any additional planet sections
    for sec in all_sections:
        if sec in STANDARD_SECTIONS:
            pass
        else:
            for key in planet_params:
                assert CONFIG_INI.has_option(sec, key)
