#!/usr/bin/python3
import os

import yaml

TEMPLATE = """\
FROM {fromdistro}

LABEL org.opencontainers.image.base.name="{fromdistro}"
LABEL org.opencontainers.image.authors="Christian Heimes"
LABEL org.opencontainers.image.url="https://github.com/tiran/cpython_builddep/"
LABEL org.opencontainers.image.title="CPython build dependencies for {fromdistro}"
LABEL org.opencontainers.image.description="Container with CPython build dependencies"
LABEL org.opencontainers.image.usage="podman run --rm -ti -v .:/cpython:Z quay.io/tiran/cpythonbuild:{distrotag}"

ENV PYBUILDDEP_FROMDISTRO="{fromdistro}"
ENV PYBUILDDEP_DISTROTAG="{distrotag}"
VOLUME ["/cpython"]

COPY tests/entry.sh tests/activate /
CMD ["/entry.sh"]

COPY builddep.sh /
RUN ["/builddep.sh", "--update", "--extras", "--cleanup"]
"""

here = os.path.abspath(os.path.dirname(__file__))
ci_yml = os.path.join(here, os.pardir, ".github", "workflows", "ci.yml")

with open(ci_yml) as f:
    ci = yaml.load(f, Loader=yaml.SafeLoader)

includes = ci["jobs"]["distros"]["strategy"]["matrix"]["include"]

for include in includes:
    distrotag = include["distro"]
    fromdistro = distrotag.replace("--", "/").replace("-", ":")
    with open(os.path.join(here, f"Dockerfile.{distrotag}"), "w") as f:
        f.write(TEMPLATE.format(fromdistro=fromdistro, distrotag=distrotag))
    print(f"* quay.io/tiran/cpythonbuild:{distrotag} ({include['platforms'].replace(',', ', ')})")
