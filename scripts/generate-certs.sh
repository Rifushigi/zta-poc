#!/bin/bash
# scripts/generate-certs.sh

set -e

CERT_DIR="certs"
mkdir -p $CERT_DIR

echo "Generating CA certificate and key..."
openssl genrsa -out $CERT_DIR/ca.key 4096
openssl req -new -x509 -days 365 -key $CERT_DIR/ca.key -out $CERT_DIR/ca.crt \
  -subj "/C=NG/ST=Lagos/L=Lagos/O=Zero Trust PoC/CN=Zero Trust CA"

echo "Generating server certificate and key..."
openssl genrsa -out $CERT_DIR/server.key 2048
openssl req -new -key $CERT_DIR/server.key -out $CERT_DIR/server.csr \
  -subj "/C=NG/ST=Lagos/L=Lagos/O=Zero Trust PoC/CN=api-gateway"
openssl x509 -req -days 365 -in $CERT_DIR/server.csr -CA $CERT_DIR/ca.crt \
  -CAkey $CERT_DIR/ca.key -CAcreateserial -out $CERT_DIR/server.crt

echo "Generating client certificate and key..."
openssl genrsa -out $CERT_DIR/client.key 2048
openssl req -new -key $CERT_DIR/client.key -out $CERT_DIR/client.csr \
  -subj "/C=NG/ST=Lagos/L=Lagos/O=Zero Trust PoC/CN=client"
openssl x509 -req -days 365 -in $CERT_DIR/client.csr -CA $CERT_DIR/ca.crt \
  -CAkey $CERT_DIR/ca.key -CAcreateserial -out $CERT_DIR/client.crt

echo "Generating OPA certificate and key..."
openssl genrsa -out $CERT_DIR/opa.key 2048
openssl req -new -key $CERT_DIR/opa.key -out $CERT_DIR/opa.csr \
  -subj "/C=NG/ST=Lagos/L=Lagos/O=Zero Trust PoC/CN=opa"
openssl x509 -req -days 365 -in $CERT_DIR/opa.csr -CA $CERT_DIR/ca.crt \
  -CAkey $CERT_DIR/ca.key -CAcreateserial -out $CERT_DIR/opa.crt

echo "Cleaning up CSR files..."
rm $CERT_DIR/*.csr

echo "✅ Certificate generation complete"
echo "Files created in $CERT_DIR/:"
ls -la $CERT_DIR/
