from exoticism.config import CONFIG_INI


def test_main_sections():
    """ Check that all main sections exist. """

    for section in ['setup', 'data_paths', 'smooth_model']:
        exists = section in CONFIG_INI
        assert exists


def test_data_paths():
    """ Check that all required data paths exist. """

    data_keys = ['local_path', 'data_path', 'output_path', 'run_name']
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
        assert CONFIG_INI.has_option('smooth_model', key)
