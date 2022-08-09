FROM quay.io/pypa/manylinux2010_ARCH:latest
RUN LINUX32 yum install -y PyYAML xz-devel
RUN LINUX32 /opt/python/cp36-cp36m/bin/python -m venv /opt/wheelenv
RUN LINUX32 /opt/wheelenv/bin/pip install STARFORGE[lzma]
ENTRYPOINT
