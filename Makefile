
docker-build:
	docker buildx build --platform=linux/amd64 --tag discordbot .
docker-deploy:
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(AWS_ACCOUNT).dkr.ecr.$(AWS_REGION).amazonaws.com && \
	docker tag discordbot:latest $(AWS_ACCOUNT).dkr.ecr.$(AWS_REGION).amazonaws.com/discordbot:latest && \
	docker push $(AWS_ACCOUNT).dkr.ecr.$(AWS_REGION).amazonaws.com/discordbot:latest

bounce:
	aws ecs stop-task --cluster arn:aws:ecs:$(AWS_REGION):${AWS_ACCOUNT}:cluster/${CLUSTER_NAME} \
	--task $$(aws ecs list-tasks --cluster arn:aws:ecs:$(AWS_REGION):$(AWS_ACCOUNT):cluster/$(CLUSTER_NAME) --query 'taskArns[0]' --output text)

validate:
	@echo "validate all the things..."
	@cfn-lint cloudformation/api.yaml

clean: ##=> Clean all the things
	$(info [+] Cleaning dist packages...)
	@rm -f api.out.yaml
	@rm -rf handler.zip

build: clean
	$(info [+] Build service zip)
	@cd api && zip -X -q -r9 $(abspath ./handler.zip) ./ -x \*__pycache__\* -x \*.git\*

sam-local: build
	sam local invoke \
		--template-file cloudformation/management_api.yaml \
		--event test/test.json

deploy-api:
	$(AWSCLI) sam deploy --region $(AWS_REGION) --no-fail-on-empty-changeset \
		--stack-name $(SERVICE_NAME)-api \
		--template-file cloudformation/api.yaml \
		--s3-bucket metalisticpain-artifacts \
		--capabilities CAPABILITY_NAMED_IAM \
		--parameter-overrides \
			ClusterName=$(CLUSTER_NAME) \
			ServiceName=$(SERVICE_NAME) \
			Domain="$(DOMAIN)" \
			CertArn=$(shell aws acm list-certificates --query "CertificateSummaryList[?DomainName=='api.$(DOMAIN)'].CertificateArn" --output text) \
			HostedZoneId=$(shell aws route53 list-hosted-zones --query "HostedZones[?Name=='$(DOMAIN).'].Id" --output text | cut -d / -f3) \
		--tags \
			service=$(SERVICE_NAME)
