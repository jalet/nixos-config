{ config, lib, ... }:
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

      vlan10 = {
        useDHCP = false;
        ipv4 = {
          addresses = [
            { address = "10.10.10.200"; prefixLength = 24; }
            { address = "10.10.10.254"; prefixLength = 24; }
          ];
        };
      };

      vlan20 = {
        useDHCP = false;
        ipv4 = {
          addresses = [
            { address = "10.10.20.200"; prefixLength = 24; }
            { address = "10.10.20.254"; prefixLength = 24; }
          ];
        };
      };

      vlan30 = {
        useDHCP = false;
        ipv4 = {
          addresses = [
            { address = "10.10.30.200"; prefixLength = 24; }
            { address = "10.10.30.254"; prefixLength = 24; }
          ];
        };
      };

      vlan99 = {
        useDHCP = false;
        ipv4 = {
          addresses = [
            { address = "10.10.99.200"; prefixLength = 24; }
            { address = "10.10.99.254"; prefixLength = 24; }
          ];
        };
      };
    };

    networkmanager = {
      enable = true;

      wifi = {
        powersave = false;
      };
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
        53 #DNS
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
