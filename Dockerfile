ARG ALPINE_VERSION="3.19"

FROM alpine:${ALPINE_VERSION}

ARG PYTHON_VERSION="3.9.19"
ARG PYTHON_PIP_VERSION="23.0.1"
ARG PYTHON_SETUPTOOLS_VERSION="58.0.1"
ARG PYTHON_GET_PIP_SHA256="45a2bb8bf2bb5eff16fdd00faef6f29731831c7c59bd9fc2bf1f3bed511ff1fe"
ARG PYTHON_GPG_KEY="E3FF2839C048B25C084DEBE9B26995E310250568"
ARG PYTHON_GET_PIP_URL="https://github.com/pypa/get-pip/raw/9af82b715db434abb94a0a6f3569f43e72157346/public/get-pip.py"

ENV GPG_KEY=$PYTHON_GPG_KEY
ENV PY_VERSION=$PYTHON_VERSION
 # if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
ENV PYTHON_PIP_VERSION=$PYTHON_PIP_VERSION
# https://github.com/docker-library/python/issues/365
ENV PYTHON_SETUPTOOLS_VERSION=$PYTHON_SETUPTOOLS_VERSION
# https://github.com/pypa/get-pip
ENV PYTHON_GET_PIP_URL=$PYTHON_GET_PIP_URL
ENV PYTHON_GET_PIP_SHA256=$PYTHON_GET_PIP_SHA256


# # ensure local python is preferred over distribution python
ENV PATH /usr/local/bin:$PATH

# # http://bugs.python.org/issue19846
# # > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV LANG C.UTF-8

# # runtime dependencies
RUN set -eux; \
 	apk add --no-cache \
 		ca-certificates \
 		tzdata \
 	;

RUN set -eux; \
 	\
 	apk add --no-cache --virtual .build-deps \
 		gnupg \
 		tar \
 		xz \
 		\
 		bluez-dev \
 		bzip2-dev \
 		dpkg-dev dpkg \
 		expat-dev \
 		findutils \
 		gcc \
 		gdbm-dev \
 		libc-dev \
 		libffi-dev \
 		libnsl-dev \
 		libtirpc-dev \
 		linux-headers \
 		make \
 		ncurses-dev \
 		openssl-dev \
 		pax-utils \
 		readline-dev \
 		sqlite-dev \
 		tcl-dev \
 		tk \
 		tk-dev \
 		util-linux-dev \
 		xz-dev \
 		zlib-dev \
 	; \
 	\
 	wget -q -O python.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz"; \
 	wget -q -O python.tar.xz.asc "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz.asc"; \
 	GNUPGHOME="$(mktemp -d)"; export GNUPGHOME; \
 	gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$GPG_KEY"; \
 	gpg --batch --verify python.tar.xz.asc python.tar.xz; \
 	gpgconf --kill all; \
 	rm -rf "$GNUPGHOME" python.tar.xz.asc; \
 	mkdir -p /usr/src/python; \
 	tar --extract --directory /usr/src/python --strip-components=1 --file python.tar.xz; \
 	rm python.tar.xz; \
 	\
 	cd /usr/src/python; \
 	gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
 	./configure \ 
 		--build="$gnuArch" \
 		--enable-loadable-sqlite-extensions \
 		--enable-optimizations \
 		--enable-option-checking=fatal \
 		--enable-shared \
 		--with-lto \
 		--with-system-expat \
 		--without-ensurepip \
 	; \
 	nproc="$(nproc)"; \
 # set thread stack size to 1MB so we don't segfault before we hit sys.getrecursionlimit()
 # https://github.com/alpinelinux/aports/commit/2026e1259422d4e0cf92391ca2d3844356c649d0
 	EXTRA_CFLAGS="-DTHREAD_STACK_SIZE=0x100000"; \
 	LDFLAGS="${LDFLAGS:--Wl},--strip-all"; \
 	make -j "$nproc" \
 		"EXTRA_CFLAGS=${EXTRA_CFLAGS:-}" \
 		"LDFLAGS=${LDFLAGS:-}" \
 		"PROFILE_TASK=${PROFILE_TASK:-}" \
 	; \
 # https://github.com/docker-library/python/issues/784
 # prevent accidental usage of a system installed libpython of the same version
 	rm python; \
 	make -j "$nproc" \
 		"EXTRA_CFLAGS=${EXTRA_CFLAGS:-}" \
 		"LDFLAGS=${LDFLAGS:--Wl},-rpath='\$\$ORIGIN/../lib'" \
 		"PROFILE_TASK=${PROFILE_TASK:-}" \
 		python \
 	; \
 	make install; \
 	\
 	cd /; \
 	rm -rf /usr/src/python; \
 	\
 	find /usr/local -depth \
 		\( \
 			\( -type d -a \( -name test -o -name tests -o -name idle_test \) \) \
 			-o \( -type f -a \( -name '*.pyc' -o -name '*.pyo' -o -name 'libpython*.a' \) \) \
 		\) -exec rm -rf '{}' + \
 	; \
 	\
 	find /usr/local -type f -executable -not \( -name '*tkinter*' \) -exec scanelf --needed --nobanner --format '%n#p' '{}' ';' \
 		| tr ',' '\n' \
 		| sort -u \
 		| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
 		| xargs -rt apk add --no-network --virtual .python-rundeps \
 	; \
 	apk del --no-network .build-deps; \
 	\
 	python3 --version

 # make some useful symlinks that are expected to exist ("/usr/local/bin/python" and friends)
RUN set -eux; \
 	for src in idle3 pydoc3 python3 python3-config; do \
 		dst="$(echo "$src" | tr -d 3)"; \
 		[ -s "/usr/local/bin/$src" ]; \
 		[ ! -e "/usr/local/bin/$dst" ]; \
 		ln -svT "$src" "/usr/local/bin/$dst"; \
 	done

RUN set -eux; \
 	\
 	wget -O get-pip.py "$PYTHON_GET_PIP_URL"; \
 	echo "$PYTHON_GET_PIP_SHA256 *get-pip.py" | sha256sum -c -; \
 	\
 	export PYTHONDONTWRITEBYTECODE=1; \
 	\
 	python get-pip.py \
 		--disable-pip-version-check \
 		--no-cache-dir \
 		--no-compile \
 		"pip==$PYTHON_PIP_VERSION" \
 		"setuptools==$PYTHON_SETUPTOOLS_VERSION" \
 	; \
 	rm -f get-pip.py; \
 	\
 	pip --version


RUN apk update && apk upgrade --no-cache && apk add --no-cache gcc musl-dev libffi-dev curl
RUN pip install --no-cache-dir --upgrade pip && pip install --no-cache-dir wheel setuptools

# RUN mkdir -p /etc/ssl/rds/us-west-2 && \
# 	wget -q -O /etc/ssl/rds/us-west-2/rds-combined-ca-bundle.pem https://truststore.pki.rds.amazonaws.com/us-west-2/us-west-2-bundle.pem

# RUN mkdir -p /etc/ssl/us-east-1/ && \
# 	wget -q -O /etc/ssl/us-east-1/rds-combined-ca-bundle.pem https://truststore.pki.rds.amazonaws.com/us-east-1/us-east-1-bundle.pem

# RUN mkdir -p /etc/ssl/rds/us-east-2 && \
# 	wget -q -O /etc/ssl/rds/us-east-2/rds-combined-ca-bundle.pem https://truststore.pki.rds.amazonaws.com/us-east-2/us-east-2-bundle.pem

# RUN mkdir -p /etc/ssl/rds/global/ && \
# 	wget -q -O /etc/ssl/rds/global/global-bundle.pem https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem

# RUN ln -s /etc/ssl/rds/global/global-bundle.pem /etc/ssl/rds-combined-ca-bundle.pem

CMD ["python3"]
