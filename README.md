lxadm 0.1.4
============
Manage illumos LX zones.

[![Build Status](https://travis-ci.org/hadfl/lxadm.svg?branch=master)](https://travis-ci.org/hadfl/lxadm)

`lxadm` takes care of setting up LX zones on illumos derived operating systems.

Setup
-----

`lxadm` comes as a prebuilt pure perl package, so it should install out of
the box on any machine with a current perl installation.

```sh
wget https://github.com/hadfl/lxadm/releases/download/v0.1.4/lxadm-0.1.4.tar.gz
tar zxvf lxadm-0.1.4.tar.gz
cd lxadm-0.1.4
./configure --prefix=/opt/lxadm-0.1.4 
```

Now you can run

```sh
gmake
gmake install
```

Check the [man page](doc/lxadm.pod) for information about how to use lxadm.

Support and Contributions
-------------------------
If you find a problem with `lxadm`, please open an Issue on GitHub.

And if you have a contribution, please send a pull request.

Enjoy!

Dominik Hassler & Tobi Oetiker
2017-08-19
