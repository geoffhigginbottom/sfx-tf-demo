#! /bin/bash
# Version 2.0
: '
Script to create the certs for Splunk Enterprise
Generates Self Signed Certs
Populate the variables section with your settings then execute using:

sudo ./certs.sh

Typical output after running should look like this:

Generating RSA private key, 2048 bit long modulus
........................................+++++
.....+++++
e is 65537 (0x10001)
Signature ok
subject=/C=GB/ST=London/L=London/O=ACME/CN=eip1.geoffh.co.uk
Getting Private key
Generating RSA private key, 2048 bit long modulus
..................................+++++
.......+++++
e is 65537 (0x10001)
writing RSA key
Signature ok
subject=/C=GB/ST=London/L=London/O=ACME/CN=eip1.geoffh.co.uk
Getting CA Private Key


Following files should be generated (10 in total)

myCACertificate.csr
myCACertificate.pem
myCACertificate.srl
myCAPrivateKey.key
myFinalCert.pem
mySplunkWebCert.csr
mySplunkWebCert.pem
mySplunkWebCertificate.pem
mySplunkWebPrivateKey.key
ssl-extensions-x509.cnf
'

## Variables ##
PATH=/opt/splunk/etc/auth/sloccerts
PASSPHRASE=qwertyuiop
FQDN=eip1.geoffh.co.uk
COUNTRY=GB
STATE=London
LOCATION=London
ORG=ACME

## Create folder for scripts ##
echo "Creating folder $PATH"
/usr/bin/mkdir $PATH

## Generate a new root certificate to be your Certificate Authority ##
echo "Generating root cert for CA"
/opt/splunk/bin/splunk cmd openssl genrsa -aes256 -passout pass:$PASSPHRASE -out $PATH/myCAPrivateKey.key 2048

## Generate a certificate signing request using the root certificate private key myCAPrivateKey.key ##
echo "Gemerating CSR"
/opt/splunk/bin/splunk cmd openssl req -new \
  -key $PATH/myCAPrivateKey.key \
  -out $PATH/myCACertificate.csr \
  -passin pass:$PASSPHRASE \
  -passout pass:$PASSPHRASE \
  -subj "/C=$COUNTRY/ST=$STATE/L=$LOCATION/O=$ORG/CN=$FQDN"


## Use the CSR file to generate a new root certificate and sign it with myCAPrivateKey.key ##
echo "Generate new signed root cert"
echo -e "# ssl-extensions-x509.cnf\n[v3_ca]\nbasicConstraints = CA:FALSE\nkeyUsage = digitalSignature, keyEncipherment\nsubjectAltName = DNS:$FQDN" > $PATH/ssl-extensions-x509.cnf

/opt/splunk/bin/splunk cmd openssl x509 -req \
  -in $PATH/myCACertificate.csr \
  -signkey $PATH/myCAPrivateKey.key \
  -passin pass:$PASSPHRASE \
  -extensions v3_ca \
  -extfile $PATH/ssl-extensions-x509.cnf \
  -out $PATH/myCACertificate.pem \
  -days 3650


## Create a new private key ##
echo "Creating new private key"
/opt/splunk/bin/splunk cmd openssl genrsa \
  -aes256 \
  -passout pass:$PASSPHRASE \
  -out $PATH/mySplunkWebPrivateKey.key 2048 \


## Remove Password from mySplunkWebPrivateKey.key ##
echo "Removing password from private key"
/opt/splunk/bin/splunk cmd openssl rsa \
  -in $PATH/mySplunkWebPrivateKey.key \
  -passin pass:$PASSPHRASE \
  -out $PATH/mySplunkWebPrivateKey.key


## Create a new certificate signature request using mySplunkWebPrivateKey.key ##
echo "Creating new csr using private key"
/opt/splunk/bin/splunk cmd openssl req -new \
  -key $PATH/mySplunkWebPrivateKey.key \
  -passin pass:$PASSPHRASE \
  -out $PATH/mySplunkWebCert.csr \
  -subj "/C=$COUNTRY/ST=$STATE/L=$LOCATION/O=$ORG/CN=$FQDN"


## Sign the CSR with the root certificate private key myCAPrivateKey.key ##
echo "Signing cst with root cert private key"
/opt/splunk/bin/splunk cmd openssl x509 -req \
  -in $PATH/mySplunkWebCert.csr \
  -passin pass:$PASSPHRASE \
  -CA $PATH/myCACertificate.pem \
  -extensions v3_ca \
  -extfile $PATH/ssl-extensions-x509.cnf \
  -CAkey $PATH/myCAPrivateKey.key \
  -CAcreateserial \
  -out $PATH/mySplunkWebCert.pem \
  -days 1095


## Combine the server certificate and public certificates into a single certificate file ##
echo "Combining certs into a single pem file"
/usr/bin/cat $PATH/mySplunkWebCert.pem $PATH/myCACertificate.pem > $PATH/mySplunkWebCertificate.pem
/usr/bin/cat $PATH/mySplunkWebCertificate.pem $PATH/mySplunkWebPrivateKey.key > $PATH/myFinalCert.pem

## Fix permissions ##
echo "Updating permissions"
/usr/bin/chown -R splunk:splunk $PATH

## Update /opt/splunk/etc/system/local/server.conf
echo "Updating Splunk config to use certs"
/usr/bin/sed -i "/^sslPassword.*/a serverCert = $PATH/myFinalCert.pem" /opt/splunk/etc/system/local/server.conf
/usr/bin/sed -i "/^serverCert.*/a requireClientCert = false" /opt/splunk/etc/system/local/server.conf
/usr/bin/sed -i "/^pass4SymmKey.*/a serverName = $FQDN" /opt/splunk/etc/system/local/server.conf

# Restart Splunk
echo "restarting Splunk"
/opt/splunk/bin/splunk restart splunkd