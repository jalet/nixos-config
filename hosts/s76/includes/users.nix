{ ... }:
{
  users.users.jalet = {
    isNormalUser = true;
    description = "Joakim Jarsater";
    extraGroups = [ "networkmanager" "wheel" "audio" ];

    openssh = {
      authorizedKeys = {
        keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINB8cSXjtIYTScYsrqHVQXxcIoEoRgSjycs9iCedKx9L cardno:12_763_134"
          "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBMQSvyIRlRjOcpLVEo2expW39hqZgOsQW9EjRH6APo8KPzeDgP74NQAZaWwaU0qUOVV3pioMGb7X/UoMyw619V4= cardno:12_763_134"
        ];
      };
    };
  };
}
