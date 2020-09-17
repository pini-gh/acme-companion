## DNS mode challenge configuration

To use DNS mode challenge, define `LETSENCRYPT_DNS_MODE` and `LETSENCRYPT_DNS_MODE_SETTINGS` environment variables in the client container:

	  environment:
	  - LETSENCRYPT_DNS_MODE=<dns_provider_script_name>
	  - LETSENCRYPT_DNS_MODE_SETTINGS=export <provider_setting>=<value> ...

You find the `<dns_provider_script_name>` by browsing the `acme.sh` `dnsapi` folder [1]. the variable must hold the script name without the `.sh` extension.

[1] https://github.com/acmesh-official/acme.sh/tree/master/dnsapi

Examples:

* To use Gandi LiveDNS:

		- LETSENCRYPT_DNS_MODE=dns_gandi_livedns
* To use DuckDNS:

		- LETSENCRYPT_DNS_MODE=dns_duckdns

To find about a provider's settings, read the comments provided at the begining of the related script.

Example:

* `dnsapi/dns_gandi_livedns.sh` has this comment:

		# Requires GANDI API KEY set in GANDI_LIVEDNS_KEY set as environment variable
   Then the settings would be:
  
		- LETSENCRYPT_DNS_MODE_SETTINGS=export GANDI_LIVEDNS_KEY=<your_gandi_api_key>	
* `dnsapi/dns_duckdns.sh` has this comment:

		# export DuckDNS_Token="aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
   Then the settings would be:

		- LETSENCRYPT_DNS_MODE_SETTINGS=export DuckDNS_Token=<your_duckdns_token>
