
build:
	docker build --tag discordbot .
deploy:
	aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin $(AWS_ACCOUNT).dkr.ecr.${REGION}.amazonaws.com && \
	docker tag discordbot:latest $(AWS_ACCOUNT).dkr.ecr.${REGION}.amazonaws.com/discordbot:latest && \
	docker push $(AWS_ACCOUNT).dkr.ecr.${REGION}.amazonaws.com/discordbot:latest

bounce:
	aws ecs stop-task --cluster arn:aws:ecs:${REGION}:${AWS_ACCOUNT}:cluster/${CLUSTER_NAME} \
	--task $$(aws ecs list-tasks --cluster arn:aws:ecs:$(REGION):$(AWS_ACCOUNT):cluster/$(CLUSTER_NAME) --query 'taskArns[0]' --output text)