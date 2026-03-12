function wz -d "Install/update Warzone2100 from source"
    cd "$HOME/src"
    set -l wz_source "$HOME/src/warzone2100"
    
    if test -d $wz_source
        cd $wz_source
        git remote update -p
        git merge --ff-only '@{u}'
        git submodule update --init --recursive
    else
        git clone --recurse-submodules --depth 1 \
            https://github.com/Warzone2100/warzone2100 $wz_source
        cd $wz_source
    end

    sudo ./get-dependencies_linux.sh ubuntu build-all
    mkdir -p build
    cd build
    cmake \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DCMAKE_INSTALL_PREFIX:PATH=/opt/warzone2100-latest \
        -GNinja ..
    
    sudo cmake --build . --target install
    cd
end
