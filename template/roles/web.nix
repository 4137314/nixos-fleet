# Reverse proxy with automatic TLS. Replace the virtual host with your application.
{ ... }:
{
  fleet.hardening.allowedTCPPorts = [
    80
    443
  ];
  security.acme = {
    acceptTerms = true;
    defaults.email = "ops@example.com";
  };
  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedProxySettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    virtualHosts."app.example.com" = {
      enableACME = true;
      forceSSL = true;
      locations."/".proxyPass = "http://127.0.0.1:8080";
    };
  };
}
