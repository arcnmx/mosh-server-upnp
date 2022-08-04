extern crate igd;
extern crate get_if_addrs;

use std::process::{Command, Stdio, exit};
use std::io::{self, Write};
use std::error::Error;
use std::{env, net};
use igd::SearchOptions;

fn addr_ip(addr: net::Ipv4Addr) -> u32 {
    let octets = addr.octets();
    ((octets[0] as u32) << 24) |
        ((octets[1] as u32) << 16) |
        ((octets[2] as u32) << 8) |
        octets[3] as u32
}

fn if_for_addr(remote_addr: net::Ipv4Addr) -> io::Result<get_if_addrs::Ifv4Addr> {
    let remote_addr = addr_ip(remote_addr);

    for addr in try!(get_if_addrs::get_if_addrs()) {
        match addr.addr {
            get_if_addrs::IfAddr::V4(addr) => {
                let ip = addr_ip(addr.ip);
                let netmask = addr_ip(addr.netmask);

                if (remote_addr & netmask) == (ip & netmask) {
                    return Ok(addr)
                }
            },
            _ => (),
        }
    }

    Err(io::Error::new(io::ErrorKind::Other, "address not found"))
}

fn try_main() -> io::Result<i32> {
    let mosh_server = env::var_os("MOSH_SERVER");
    let mosh_server = mosh_server.as_ref().map(|s| s.as_os_str()).unwrap_or("mosh-server".as_ref());
    let mut command = Command::new(mosh_server);
    command.stderr(Stdio::inherit())
        .stdin(Stdio::inherit());

    for arg in env::args_os().skip(1) {
        command.arg(arg);
    }

    let output = try!(command.output());

    if !output.status.success() {
        return output.status.code()
            .ok_or_else(|| io::Error::new(io::ErrorKind::Other, "child exited by signal"))
    }

    let data = try!(String::from_utf8(output.stdout).map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e)));

    let data = try!(data.lines()
        .find(|line| line.starts_with("MOSH CONNECT "))
        .ok_or_else(|| io::Error::new(io::ErrorKind::InvalidData, "expected connection data"))
    );

    let mut data = data.splitn(4, ' ').skip(2);
    let data = data.next().and_then(|port| data.next().map(|secret| (port, secret)));
    let (port, secret) = try!(data.ok_or_else(|| io::Error::new(io::ErrorKind::InvalidData, "malformated connection data")));

    let port = try!(port.parse().map_err(|_| io::Error::new(io::ErrorKind::InvalidData, "connection port must be numeric")));

    let gateway = try!(igd::search_gateway(SearchOptions::default())
        .map_err(|e| io::Error::new(io::ErrorKind::Other, e))
    );

    let address = try!(if_for_addr(*gateway.addr.ip()));
    let address = net::SocketAddrV4::new(address.ip, port);
    let external_port = try!(gateway.add_any_port(igd::PortMappingProtocol::UDP, address, 0, "mosh-server")
        .map_err(|e| io::Error::new(io::ErrorKind::Other, e))
    );

    try!(writeln!(io::stdout(), "\nMOSH CONNECT {} {}", external_port, secret));

    Ok(0)
}

fn main() {
    match try_main() {
        Err(err) => {
            let _ = writeln!(io::stderr(), "mosh-server-upnp error: {}", err.description());
            exit(1)
        },
        Ok(status) => exit(status),
    }
}
