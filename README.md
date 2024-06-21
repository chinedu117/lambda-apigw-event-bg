## Dataspan.ai


### How to deploy

 1. Run `cd infra && terraform init`
 2. Run `terraform plan` to see the changes to be made.
 3. Run `terraform apply` then type yes.
 4. Copy the api gateway url displayed. 


### Test

```
curl --location 'INSERT_API_GATEWAY_URL/' \
--header 'Content-Type: application/json' \
--data '{
    "delay":42,
    "id": 4
}'

```
