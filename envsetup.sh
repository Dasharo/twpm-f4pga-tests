export FPGA_FAM=eos-s3

if [ ! -e .f4pga ]; then
    (
    mkdir -p .f4pga
    INSTALL_DIR="$(pwd)/.f4pga"
    cd external/f4pga-arch-defs
    export F4PGA_SHARE_DIR="${INSTALL_DIR}"/share/f4pga
    export CMAKE_FLAGS="-GNinja -DINSTALL_FAMILIES=qlf_k4n8,pp3 -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}"
    make env
    source env/conda/etc/profile.d/conda.sh
    conda activate f4pga_arch_def_base
    cd build
    ninja install
    cd "$INSTALL_DIR"
    mkdir eos-s3
    mv share eos-s3
    unset F4PGA_SHARE_DIR
    )
fi

export F4PGA_INSTALL_DIR="$(readlink -f .f4pga)"

if ! (conda env list | awk '{print $1}' | grep -Eq '^eos-s3$'); then
    conda env create -f environment.yml
fi

conda activate eos-s3
