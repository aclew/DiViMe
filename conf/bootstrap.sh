echo "Start bootstraping DiViMe"
apt-get update -y
apt-get upgrade -y

if grep --quiet vagrant /etc/passwd
then
    user="vagrant"
else
    user="ubuntu"
fi

sudo apt-get install -y git make automake libtool autoconf patch subversion fuse \
    libatlas-base-dev libatlas-dev liblapack-dev sox libav-tools g++ \
    zlib1g-dev libsox-fmt-all sshfs gcc-multilib libncurses5-dev unzip bc \
    openjdk-6-jre icedtea-netx-common icedtea-netx libxt-dev libx11-xcb1 \
    libc6-dev-i386 festival espeak python-setuptools gawk \
    libboost-all-dev

# Kaldi and others want bash - otherwise the build process fails
[ $(readlink /bin/sh) == "dash" ] && ln -s -f bash /bin/sh

# Install Anaconda and Theano
echo "Downloading Anaconda-2.3.0..."
cd /home/${user}
wget -q https://3230d63b5fc54e62148e-c95ac804525aac4b6dba79b00b39d1d3.ssl.cf1.rackcdn.com/Anaconda-2.3.0-Linux-x86_64.sh
echo "Installing Anaconda-2.3.0..."
sudo -S -u vagrant -i /bin/bash -l -c "bash /home/${user}/Anaconda-2.3.0-Linux-x86_64.sh -b"

# check if anaconda is installed correctly
if ! [ -x "$(command -v /home/${user}/anaconda/bin/conda)" ]; then
    echo "*******************************"
    echo "  conda installation failed"
    echo "*******************************"
    exit 1
fi

if ! grep -q -i anaconda .bashrc; then
    echo "export PATH=/home/${user}/launcher:/home/${user}/utils:/home/${user}/anaconda/bin:\$PATH" >> /home/${user}/.bashrc 
fi
su ${user} -c "/home/${user}/anaconda/bin/conda install numpy scipy mkl dill tabulate joblib sphinx"
# clean up big installer in home folder
rm -f Anaconda-2.3.0-Linux-x86_64.sh

# To use miniconda (~40MB) instead of anaconda (~350MB), uncomment below block
# echo "Downloading Miniconda-4.5.11..."
# wget -q https://repo.continuum.io/miniconda/Miniconda2-4.5.11-Linux-x86_64.sh
# echo "Install miniconda (as Anaconda)"
# sudo -S -u vagrant -i /bin/bash -l -c "bash /home/${user}/Miniconda2-4.5.11-Linux-x86_64.sh -b -p /home/${user}/anaconda"
# # check if anaconda is installed correctly
# if ! [ -x "$(command -v /home/${user}/anaconda/bin/conda)" ]; then
#     echo "*******************************"
#     echo "  conda installation failed"
#     echo "*******************************"
#     exit 1
# fi

# if ! grep -q -i anaconda .bashrc; then
#     echo "export PATH=/home/${user}/launcher:/home/${user}/utils:/home/${user}/anaconda/bin:\$PATH" >> /home/${user}/.bashrc
# fi
# su ${user} -c "/home/${user}/anaconda/bin/conda install numpy scipy mkl dill tabulate joblib cython=0.22.1 sphinx"

# # clean up big installer in home folder
# rm -f Miniconda2-4.5.11-Linux-x86_64.sh

# python3 env
echo "Create python3 env"
cd /home/$user
cp /vagrant/conf/environment.yml /home/${user}/
su ${user} -c "/home/${user}/anaconda/bin/conda env create -f environment.yml"
if [ $? -ne 0 ]; then PYTHON3_INSTALLED=false; fi

# install Matlab runtime environment
echo "Download matlab installer"
cd /tmp
wget -q http://ssd.mathworks.com/supportfiles/downloads/R2017b/deployment_files/R2017b/installers/glnxa64/MCR_R2017b_glnxa64_installer.zip
echo "Install matlab"
unzip -q MCR_R2017b_glnxa64_installer.zip
./install -mode silent -agreeToLicense yes

# check if matlab is installed correctly
if [ $? -ne 0 ]; then 
    echo "*******************************"
    echo "  matlab installation failed"
    echo "*******************************"
    exit 1
fi

# add Matlab stuff to path
echo 'LD_LIBRARY_PATH="/usr/local/MATLAB/MATLAB_Runtime/v93/runtime/glnxa64:/usr/local/MATLAB/MATLAB_Runtime/v93/bin/glnxa64:/usr/local/MATLAB/MATLAB_Runtime/v93/sys/os/glnxa64:$LD_LIBRARY_PATH"' >> /home/${user}/.bashrc
rm /tmp/MCR_R2017b_glnxa64_installer.zip

# Install OpenSMILE
echo "Installing OpenSMILE"
su ${user} -c "mkdir -p /home/${user}/repos/"
cd /home/${user}/repos/
wget -q --no-check-certificate https://www.audeering.com/download/opensmile-2-3-0-tar-gz/?wpdmdl=4782 -O OpenSMILE-2.3.tar.gz
tar zxvf OpenSMILE-2.3.tar.gz
chmod +x opensmile-2.3.0/bin/linux_x64_standalone_static/SMILExtract
cp opensmile-2.3.0/bin/linux_x64_standalone_static/SMILExtract /usr/local/bin
rm OpenSMILE-2.3.tar.gz

# check if opensmile if installed
if ! [ -x "$(command -v SMILExtract)" ]; then
    echo "*******************************"
    echo "  OPENSMILE installation failed"
    echo "*******************************"
    OPENSMILE_INSTALLED=false;
fi


# optionally Install HTK (without it, some other tools will not work)
# the idea is to make users independently download HTK installer since
# we cannot redistribute
cd /home/${user}
if [ -f /vagrant/HTK-3.4.1.tar.gz ]; then
    if [[ ! -d repos/htk ]]; then
        cd /home/${user}/repos/
        sudo tar zxf /vagrant/HTK-3.4.1.tar.gz
        cd htk
        sudo ./configure --without-x --disable-hslab
        sudo sed -i "s/        /\t/g" HLMTools/Makefile # fix bad Makefile
        sudo make all
        sudo make install
    else
        echo "Visibly htk has been already installed..."
    fi
else
    echo "Can't find HTK-3.4.1.tar.gz. Check that you installed the right version."
fi


# POPOULATE THE REPOSITORY SECTION
cd /home/${user}/repos/

    # Get OpenSAT=noisemes and dependencies
# git clone http://github.com/srvk/OpenSAT --branch yunified # --branch v1.0 # need Dev

su ${user} -c "/home/${user}/anaconda/bin/pip install -v ipdb"

cp /vagrant/conf/.theanorc /home/${user}/
su ${user} -c "/home/${user}/anaconda/bin/conda install -y theano=0.8.2"

# Install Yunitator and dependencies
git clone https://github.com/srvk/Yunitator
(cd Yunitator && git checkout develop/yunified)


su ${user} -c "/home/${user}/anaconda/bin/conda install cudatoolkit"
su ${user} -c "/home/${user}/anaconda/bin/conda install pytorch-cpu -c pytorch"

# Install VCM 
git clone https://github.com/MilesICL/vcm
(cd vcm && git checkout 93991b0)

#Install to-combo sad and dependencies (matlab runtime environnement)
git clone https://github.com/srvk/To-Combo-SAD
(cd To-Combo-SAD && git checkout 2ce2998)

# Install DiarTK
git clone http://github.com/srvk/ib_diarization_toolkit
(cd ib_diarization_toolkit && git checkout b3e4deb)

# Install eval
git clone http://github.com/srvk/dscore 
# zip to revision for release 1.1 14 Dec 2018
(cd dscore && git checkout 31d7eca)

# Install WCE and dependencies
git clone https://github.com/aclew/WCE_VM
su ${user} -c "/home/${user}/anaconda/bin/pip install keras"
su ${user} -c "/home/${user}/anaconda/bin/pip install -U tensorflow"

# Phonemizer installation
git clone https://github.com/bootphon/phonemizer
cd phonemizer
git checkout 332b8dd

python setup.py build
python setup.py install

#install launcher and utils
#    cd /home/${user}/
#    git clone https://github.com/aclew/launcher.git
#    chmod +x launcher/*
#    git clone https://github.com/aclew/utils.git
#    chmod +x utils/*

# install pympi (for eaf -> rttm conversion) and tgt (for textgrid -> rttm conversion)
# and intervaltree (needed for rttm2scp.py)
# and recommonmark (needed to make html in docs/)
su ${user} -c "/home/${user}/anaconda/bin/pip install pympi-ling tgt intervaltree recommonmark"

# Link /vagrant/launcher and /vagrant/utils to home folder where scripts expect them
ln -s /vagrant/launcher /home/${user}/
ln -s /vagrant/utils /home/${user}/

# Some cleanup
apt-get autoremove -y

# Silence error message from missing file
touch /home/${user}/.Xauthority

# Provisioning runs as root; we want files to belong to '${user}'
chown -R ${user}:${user} /home/${user}

# Installation status 
if ! $PYTHON3_INSTALLED; then
    echo "*********************************************"
    echo "Warning: python3 environment is not installed"
    echo "*********************************************"
fi
if ! $OPENSMILE_INSTALLED; then
    echo "***********************************"
    echo "Warning: OpenSMILE is not installed"
    echo "***********************************"
fi
if ! $HTK_INSTALLED; then 
    echo "*****************************"
    echo "Warning: HTK is not installed"
    echo "*****************************"
fi

# Build the docs
cd /vagrant/docs
make SPHINXBUILD=/home/${user}/anaconda/bin/sphinx-build html
