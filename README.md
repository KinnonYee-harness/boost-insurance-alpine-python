# alpine-python
SecOps Docker version of Alpine Linux with Python Versions

This repo has a set of Dockerfile tempaltes:
- Dockerfile (Base Alpine image with Python + PIP only)
- Dockerfile.onbuild (Builds off Base Image adds onbuild args of our applications)
- Dockerfiel.onbuild-poetry (Builds off Base Image adds onbuild args of our applications + Poerty installation)

Theres a a set of HCL files that control the python versions:
- 3.9.hcl (Python Version 3.9.x settings)
- 3.10.hcl (Python Version 3.10.x settings)
- 3.11.hcl (Python Version 3.11.x settings)
- 3.12.hcl (Python Version 3.12.x settings)
- 3.13.hcl (Python Version 3.13.x settings)

Theres files are constructed as follows:
```
PYTHON_VERSION="3.9.18"
PYTHON_GPG_KEY="E3FF2839C048B25C084DEBE9B26995E310250568"
PYTHON_PIP_VERSION="23.0.1"
PYTHON_SETUPTOOLS_VERSION="58.1.0"
PYTHON_GET_PIP_URL="https://github.com/pypa/get-pip/raw/9af82b715db434abb94a0a6f3569f43e72157346/public/get-pip.py"
PYTHON_GET_PIP_SHA256="45a2bb8bf2bb5eff16fdd00faef6f29731831c7c59bd9fc2bf1f3bed511ff1fe"
ONBUILD_BASE_TAG="3.9"
```
## How up make or update a version

These are required for overriding the defaults. By default the docker-bake.hcl file will build 3.9 python.  How to add a new version of Python, update the given version of update python you just
values in the 3.x.hcl that needs to be changed. If you wish to add a new major version, copy one of the 3.x.hcl to a new file. ie. 3.14.hcl. Then you need to update the PYTHON_VERSION (Must match version on pythons website),
PYTHON_GPG_KEY needs to match the OpenPGP Public Key for the maintainer for that version [PYTHON_PUBLIC_GPG_KEYS_LIST](https://www.python.org/downloads/) then you update the ONBUILD_BASE_TAG to be the short version of the python
version ie. 3.14 instead of 3.14.0.

## Build a version locally
If you want to build locally its done by like this: 
```
docker buildx bake <target> -f docker-bake.hcl -f 3.9.hcl
```
We support the following local images targets:
- onbuild-local
- onbuild-poetry-local
- image-local
- default is building all three images

These will build you local images to your machine for testing. it will compile them for local machines Architecture. 


## Cosign
We have in this cosign.pub for validating the signed images. Dont delete this files or you can't check the files. 


## Github Actions
Github actions will automatically build images for any platform that is defined in the platform section of the docker-bake.hcl 