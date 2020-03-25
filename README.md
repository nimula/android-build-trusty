# android-build-trusty
Set up an Ubuntu Trust image ready to build Android open source project (AOSP).
Base on https://android.googlesource.com/platform/build/+/master/tools/docker add some missing packages, remove repo checksum check and add run.sh to help create image an run container.

First, build the image:
```
# Copy your host gitconfig, or create a stripped down version
$ cp ~/.gitconfig gitconfig
$ docker build --build-arg userid=$(id -u) --build-arg groupid=$(id -g) --build-arg username=$(id -un) -t android-build-trusty .
```
OR
```
$ ./run.sh create
```

Then you can start up new instances with:
```
$ docker run -it --rm -v $ANDROID_BUILD_TOP:/src android-build-trusty
> cd /src; source build/envsetup.sh
> lunch aosp_arm-eng
> m -j50
```
OR
```
$ ./run.sh -s $ANDROID_BUILD_TOP run
> source build/envsetup.sh
> lunch aosp_arm-eng
> m -j50
```
