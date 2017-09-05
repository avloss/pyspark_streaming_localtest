FROM debian:stable
MAINTAINER Anton Loss @avloss

USER root

RUN apt-get update && apt-get install -y wget bzip2 git unzip

RUN wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    && bash Miniconda3-latest-Linux-x86_64.sh -b -p /miniconda3 \
    && rm Miniconda3-latest-Linux-x86_64.sh


RUN /miniconda3/bin/conda install jupyter scipy matplotlib


WORKDIR /
RUN wget http://apache.mirror.anlx.net/spark/spark-2.2.0/spark-2.2.0-bin-hadoop2.7.tgz
RUN tar -xvf spark-2.2.0-bin-hadoop2.7.tgz
RUN ln -s /spark-2.2.0-bin-hadoop2.7 /spark


RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y  software-properties-common && \
    add-apt-repository ppa:webupd8team/java -y && \
    apt-get update && \
    echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
    apt-get install -y --allow-unauthenticated oracle-java8-installer && \
    apt-get clean

RUN mkdir /notebook

VOLUME /notebook
WORKDIR /notebook

EXPOSE 8888

COPY Testin_PySpark_Streaming.ipynb /notebook

COPY startup.sh /startup.sh
CMD bash /startup.sh