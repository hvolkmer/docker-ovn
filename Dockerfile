FROM ubuntu:latest
MAINTAINER Hendrik Volkmer <hvolkmer@gmail.com>
ENV OVS_VERSION 2.3.90
ENV SUPERVISOR_STDOUT_VERSION 0.1.1
# Configure supervisord
RUN mkdir -p /var/log/supervisor/

RUN apt-get update
RUN apt-get install -y build-essential fakeroot debhelper \
                    autoconf automake bzip2 libssl-dev \
                    openssl graphviz python-all procps \
                    python-qt4 python-zopeinterface wget \
                    python-twisted-conch libtool git dh-autoreconf

RUN apt-get install -y python-setuptools supervisor
RUN apt-get install -y unzip
# Install OVS dependencies
RUN apt-get install -y uuid-runtime python-twisted-web dkms module-assistant racoon ipsec-tools

# Install supervisor_stdout
WORKDIR /opt
RUN mkdir -p /var/log/supervisor/
RUN mkdir -p /etc/openvswitch
RUN wget https://pypi.python.org/packages/source/s/supervisor-stdout/supervisor-stdout-$SUPERVISOR_STDOUT_VERSION.tar.gz --no-check-certificate && \
     tar -xzvf supervisor-stdout-0.1.1.tar.gz && \
     mv supervisor-stdout-$SUPERVISOR_STDOUT_VERSION supervisor-stdout && \
     rm supervisor-stdout-0.1.1.tar.gz && \
     cd supervisor-stdout && \
     python setup.py install -q

# Get Open vSwitch
WORKDIR /

RUN wget --no-check-certificate https://github.com/openvswitch/ovs/archive/ovn.zip && \
  unzip ovn.zip

# TODO: The packages could/should be build outside of the container
RUN cd ovs-ovn && \
./boot.sh && \
./configure --prefix=/usr --localstatedir=/var  --sysconfdir=/etc --enable-ssl && \
make -j3

RUN cd /ovs-ovn && \ 
make install && \ 
cp debian/openvswitch-switch.init /etc/init.d/openvswitch-switch

WORKDIR /

RUN mkdir -p /usr/local/share/openvswitch/
ADD configure-ovs.sh /usr/local/share/openvswitch/
# Create the database
RUN ovsdb-tool create /etc/openvswitch/conf.db /usr/share/openvswitch/vswitch.ovsschema
RUN mkdir -p /var/run/openvswitch/

# install OVN-docker tools
RUN wget https://github.com/shettyg/ovn-docker/archive/master.zip && \
unzip master.zip && \ 
cd ovn-docker-master && \ 
cp ovn-* /usr/bin/

# install ovn dependencies
# Pulling in the world to make it run...
RUN apt-get install -y python-pip python-dev
RUN pip install oslo.utils
# Install via PIP to get the latest version (Ubunutu is way too old)
RUN pip install python-neutronclient

ADD configure-ovn.sh /usr/local/share/openvswitch/

# Supervisord config
ADD run-supervisord.sh /run-supervisord.sh
ADD supervisord.conf /etc/

CMD ["/run-supervisord.sh"]
