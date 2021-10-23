
docker-build:
	docker build --tag discordbot .
docker-deploy:
	aws ecr get-login-password --region $(REGION) | docker login --username AWS --password-stdin $(AWS_ACCOUNT).dkr.ecr.$(REGION).amazonaws.com && \
	docker tag discordbot:latest $(AWS_ACCOUNT).dkr.ecr.$(REGION).amazonaws.com/discordbot:latest && \
	docker push $(AWS_ACCOUNT).dkr.ecr.$(REGION).amazonaws.com/discordbot:latest

bounce:
	aws ecs stop-task --cluster arn:aws:ecs:$(REGION):${AWS_ACCOUNT}:cluster/${CLUSTER_NAME} \
	--task $$(aws ecs list-tasks --cluster arn:aws:ecs:$(REGION):$(AWS_ACCOUNT):cluster/$(CLUSTER_NAME) --query 'taskArns[0]' --output text)

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
	$(AWSCLI) sam deploy --no-fail-on-empty-changeset \
		--stack-name $(SERVICE_NAME)-api \
		--template-file cloudformation/api.yaml \
		--s3-bucket dammers-staging \
		--capabilities CAPABILITY_NAMED_IAM \
		--parameter-overrides \
			ClusterName=$(CLUSTER_NAME) \
			ServiceName=$(SERVICE_NAME) \
			CertArn=$(shell aws acm list-certificates --query "CertificateSummaryList[?DomainName=='api.$(DOMAIN)'].CertificateArn" --output text) \
		--tags \
			service=$(SERVICE_NAME)