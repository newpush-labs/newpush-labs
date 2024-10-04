
# Request certificates from Google PKI to avoid rate limiting

Use your own EAB key ID and HMAC from Google to avoid TLS provisioning issues with Traefik:

Follow this instructions to get the keys:

https://cloud.google.com/certificate-manager/docs/public-ca-tutorial#request-key-hmac

And change the hmac and keyid in /opt/student-lab/traefik/trafik.yml

```


# To deploy the images do

terraform plan

terraform apply

It will take several minutes for the fresh system to update, install the necessery packages and spawn all containers. You can monitor the progess by ssh ing in to the server and running pstree and docker ps to understand what's going on. 

docker ps --format="table {{.Names}}\t{{.Ports}}\t{{.Status}}"

# To SSH into the image use the following command:
 
 ssh -i ".ssh/admin.pem" admin@`terraform output -raw public_ip`       
 
 
 # Web UI will be on the following URL:

IP=`terraform output -raw public_ip` && echo https://www.$IP.traefik.me
