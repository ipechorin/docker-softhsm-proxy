FROM debian:buster

ADD pkcs11-proxy.diff /pkcs11-proxy.diff

# Build pkcs11-proxy
RUN apt-get -y update \
	&& DEBIAN_FRONTEND=noninteractive \
		apt-get -y install git dpkg-dev cmake cdbs debhelper libssl-dev \
	&& git config --global user.email "ivan.pechorin@gmail.com" && git config --global user.name "Ivan Pechorin" \
	&& git clone https://github.com/SUNET/pkcs11-proxy.git \
	&& cd pkcs11-proxy \
	&& git apply ../pkcs11-proxy.diff \
	&& DEBIAN_FRONTEND=noninteractive dpkg-buildpackage \
	&& cd / \
	&& DEBIAN_FRONTEND=noninteractive dpkg -i pkcs11-daemon_0.4.1.5_amd64.deb pkcs11-proxy1_0.4.1.5_amd64.deb \
	&& DEBIAN_FRONTEND=noninteractive apt-get -y purge git dpkg-dev cmake cdbs debhelper libssl-dev \
	&& DEBIAN_FRONTEND=noninteractive apt-get -y autoremove \
	&& DEBIAN_FRONTEND=noninteractive apt-get -y clean \
	&& rm -fr pkcs11* \
	&& mkdir -p /usr/lib/pkcs11-proxy \
	&& cp -p /usr/lib/libpkcs11-proxy.* /usr/lib/pkcs11-proxy/ \
	&& true

# Install softhsm
RUN apt-get -y update \
	&& DEBIAN_FRONTEND=noninteractive \
		apt-get -y install softhsm

# Initially configure the token
RUN /usr/bin/softhsm2-util --init-token --pin 123456 --so-pin 12345678 --slot 0 --label "SoftHSMToken"

EXPOSE 54435
ENV PKCS11_DAEMON_SOCKET="tcp://0.0.0.0:54435"
VOLUME ["/usr/lib/pkcs11-proxy"]

CMD ["/usr/bin/pkcs11-daemon", "/usr/lib/softhsm/libsofthsm2.so"]

