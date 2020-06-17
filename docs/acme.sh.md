### Design decisions:

1. Use one acme.sh configuration directory (`--config-home`) per account email address
1. Each acme.sh configuration directory can hold several accounts on different ACME service providers. But only one per servie provider.
1. The `defaut`configuration directory holds the configuration for empty account email address
1. When in testing mode (`LETSENCRYPT_TEST=true`):
   1. The directory URL is forced to The Let's Encrypt v2 staging one (`ACME_CA_URI`is ignored)
   1. The account email address is forced empty (`DEFAULT_EMAIL`and `LETSENCRYPT_EMAIL` are ignored)
