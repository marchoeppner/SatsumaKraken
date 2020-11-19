FROM ubuntu:18.04
LABEL authors="Marc Hoeppner" \
      description="Docker image containing Satsuma2 and KrakenTranslate"

    ENV SATSUMA2_PATH /opt/satsuma2/bin
    ENV PATH=/opt/satsuma2/bin:/opt/kraken/bin:$PATH

    RUN apt-get -y update
    RUN apt-get -y install wget make build-essential sed cmake git

    RUN cd /opt \
	&& git https://github.com/bioinfologics/satsuma2.git satsuma2 \
	&& cd satsuma2 \
	&& cmake CMakeLists.txt \
	&& make

    RUN cd /opt \
	&& git clone https://github.com/GrabherrGroup/kraken.git  kraken \
	&& cd kraken \
	&& ./configure \
	&& make -C build 

