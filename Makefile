
install:
	@mkdir -p database
	@docker run \
		-itd \
		--name dbt-db2 \
		--restart unless-stopped \
		-v ${PWD}/database:/database \
		-e DBNAME=testdb \
		-e DB2INST1_PASSWORD=ibm123 \
		-e LICENSE=accept \
		-p 50000:50000 \
		--privileged=true \
		ibmcom/db2:11.5.7.0
	@poetry install

test:
	@poetry run tox
