lxadm 0.1.1
============
Manage Illumos LX zones.

[![Build Status](https://travis-ci.org/hadfl/lxadm.svg?branch=master)](https://travis-ci.org/hadfl/lxadm)
[![Gitter](https://badges.gitter.im/hadfl/lxadm.svg)](https://gitter.im/lxadm/main?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=body_badge)

LXadm takes care of setting up LX zones on Illumos derived operating systems.

Setup
-----

LXadm comes as a prebuilt pure perl package, so it should install out of the box on any machine with a current perl installation.

```sh
wget https://github.com/hadfl/lxadm/releases/download/v0.1.1/lxadm-0.1.1.tar.gz
tar zxvf lxadm-0.1.1.tar.gz
cd lxadm-0.1.1
./configure --prefix=/opt/lxadm-0.1.1 
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
2016-12-15
