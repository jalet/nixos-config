{ config, lib, ... }:
let
  vlans = [
    { id = 10; network = "10.10.10"; hosts = [ ]; }
    { id = 20; network = "10.10.20"; hosts = [ 200 ]; }
    { id = 30; network = "10.10.30"; hosts = [ ]; }
    { id = 99; network = "10.10.99"; hosts = [ 200 ]; }
  ];

  makeInterface = v: {
    name = "vlan${toString v.id}";
    value = {
      useDHCP = false;
      ipv4.addresses = (map
        (h: {
          address = "${v.network}.${toString h}";
          prefixLength = 24;
        })
        v.hosts)
      ++ [
        { address = "${v.network}.254"; prefixLength = 24; } # Used for DNS server in each VLAN
      ];
    };
  };
in
{
  networking = {
    useDHCP = lib.mkDefault true;
    enableIPv6 = lib.mkDefault false;

    hostName = "s76";


    defaultGateway = "10.10.20.1";
    nameservers = [ "1.1.1.1" "1.0.0.1" ];

    bridges = {
      br0 = {
        interfaces = [ "enp86s0" ];
      };
    };

    vlans = {
      vlan10 = {
        id = 10;
        interface = "br0";
      };
      vlan20 = {
        id = 20;
        interface = "br0";
      };
      vlan30 = {
        id = 30;
        interface = "br0";
      };
      vlan99 = {
        id = 99;
        interface = "br0";
      };
    };

    interfaces = {
      enp86s0.useDHCP = false;
      br0.useDHCP = false;
    } // builtins.listToAttrs (
      map makeInterface vlans
    );

    networkmanager = {
      enable = false;
    };

    firewall = {
      enable = false;

      allowPing = true;

      allowedTCPPorts = [
        22 # SSH
        53 # DNS
        80 # HTTP (Ingress)
        443 # HTTPS (Ingress)
        6443 # Kubernetes API Server
        2379 # etcd (if running HA k3s)
        2380 # etcd peer communication (HA setup)
        10250 # Kubelet API
      ];

      allowedUDPPorts = [
        53 # DNS
        514 # Syslog
      ];

      # Traffic coming in from these interfaces will be accepted
      # unconditionally. Traffic from the loopback (lo) interface will always
      # be accepted.
      trustedInterfaces = [
        "enp86s0"
        "br0"
        "vlan10"
        "vlan20"
        "vlan30"
        "vlan99"
        "cilium_host"
      ];
    };
  };
}
