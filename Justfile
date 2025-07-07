default:
    git submodule init
    git submodule update
    autoreconf -i
    mkdir -p {{ justfile_directory() }}/freesasa_build
    cd {{ justfile_directory() }}/freesasa_build \
    && {{ justfile_directory() }}/configure \
            --prefix={{ justfile_directory() }}/freesasa_install \
            --enable-check \
        && make \
        && make install
