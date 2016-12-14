lxadm 0.1.0
============
Manage Illumos LX zones.

[![Build Status](https://travis-ci.org/hadfl/lxadm.svg?branch=master)](https://travis-ci.org/hadfl/lxadm)

LXadm takes care of setting up LX zones on illumos derived operating systems.

Setup
-----

LXadm comes as a prebuilt pure perl package, so it should install out of the box on any machine with a current perl installation.

```sh
wget https://github.com/hadfl/lxadm/releases/download/v0.1.0/lxadm-0.1.0.tar.gz
tar zxvf lxadm-0.1.0.tar.gz
cd lxadm-0.1.0
./configure --prefix=/opt/lxadm-0.1.0 
```

Now you can run

```sh
make
make install
```

Check the [man page](doc/lxadm.pod) for information about how to use lxadm.

Support and Contributions
-------------------------
If you find a problem with lxadm, please open an Issue on GitHub.

And if you have a contribution, please send a pull request.

Enjoy!

Dominik Hassler & Tobi Oetiker
2016-12-13
