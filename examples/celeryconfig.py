"""This module loads the Celery configuration from a YAML file, and injects it
into the module."""


def __main__():
    """Main initialization function for Celery configuration.

    Keep imports in this function, so module is as clean as possible.
    Celery (in tools such as `celery inspect conf`) will list all
    globals on this module as configuration items.
    """
    import os
    from ruamel.yaml import YAML

    FILE = os.getenv("CELERY_CONFIG")

    yaml = YAML()
    with open(FILE) as fp:
        content = yaml.load(fp)
        globals().update(content)


__main__()
