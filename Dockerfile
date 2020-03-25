FROM ubuntu:14.04

ARG userid
ARG groupid
ARG username
ENV TERM=screen-256color

# apt switch to TW mirror and installing required packages.
RUN sed --in-place --regexp-extended "s/(\/\/)(archive\.ubuntu)/\1tw.\2/" /etc/apt/sources.list \
  && apt-get -qq update && apt-get -qqy install bc git-core gnupg flex bison gperf build-essential \
  zip curl zlib1g-dev gcc-multilib g++-multilib libc6-dev-i386 lib32ncurses5-dev x11proto-core-dev \
  libx11-dev lib32z-dev ccache libgl1-mesa-dev libxml2-utils xsltproc unzip python openjdk-7-jdk \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN curl -o jdk8.tgz https://android.googlesource.com/platform/prebuilts/jdk/jdk8/+archive/master.tar.gz \
  && tar -zxf jdk8.tgz linux-x86 \
  && mv linux-x86 /usr/lib/jvm/java-8-openjdk-amd64 \
  && rm -rf jdk8.tgz

RUN curl -o /usr/local/bin/repo https://storage.googleapis.com/git-repo-downloads/repo \
  && chmod a+x /usr/local/bin/repo

RUN ln -s ../proc/self/mounts /etc/mtab

RUN groupadd -g $groupid $username \
  && useradd -m -u $userid -g $groupid $username \
  && echo "export USER="$username >>/home/$username/.gitconfig

COPY gitconfig /home/$username/.gitconfig
RUN chown $userid:$groupid /home/$username/.gitconfig

COPY mk.sh /script/mk.sh
RUN chown $userid:$groupid /script/mk.sh

ENV HOME=/home/$username
ENV USER=$username
ENTRYPOINT /bin/bash -i
