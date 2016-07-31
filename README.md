# mosh-server-upnp

[![travis-badge][]][travis] [![release-badge][]][cargo] [![license-badge][]][license]

`mosh-server-upnp` provides a way to use mosh over a NAT.


## Usage

Assuming that `mosh-server-upnp` is installed in the `PATH` of the user on the
target system, you can simply log in with one extra parameter to `mosh`:

    $ mosh --server=mosh-server-upnp hostname


[travis-badge]: https://img.shields.io/travis/arcnmx/mosh-server-upnp/master.svg?style=flat-square
[travis]: https://travis-ci.org/arcnmx/mosh-server-upnp
[release-badge]: https://img.shields.io/crates/v/mosh-server-upnp.svg?style=flat-square
[cargo]: https://crates.io/crates/mosh-server-upnp
[license-badge]: https://img.shields.io/badge/license-MIT-ff69b4.svg?style=flat-square
[license]: https://github.com/arcnmx/mosh-server-upnp/blob/master/COPYING
