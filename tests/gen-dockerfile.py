#!/usr/bin/python3
import os

import yaml

TEMPLATE = """\
FROM {fromdistro}

VOLUME ["/cpython"]

COPY tests/entry.sh /
ENTRYPOINT ["/entry.sh"]

COPY builddep.sh /
RUN ["/builddep.sh", "--update", "--extras", "--cleanup"]
"""

here = os.path.abspath(os.path.dirname(__file__))
ci_yml = os.path.join(here, os.pardir, ".github", "workflows", "ci.yml")

with open(ci_yml) as f:
    ci = yaml.load(f, Loader=yaml.SafeLoader)

distros = ci["jobs"]["distros"]["strategy"]["matrix"]["distro"]

for distro in distros:
    fromdistro = distro.replace("--", "/").replace("-", ":")
    with open(os.path.join(here, f"Dockerfile.{distro}"), "w") as f:
        f.write(TEMPLATE.format(fromdistro=fromdistro))
