
install:
	@mkdir -p db2/database
	@mkdir -p db2/keystore
	@docker run \
		-itd \
		--name dbt-db2 \
		--restart unless-stopped \
		-v ${PWD}/db2/database:/database \
		-v ${PWD}/db2/keystore:/keystore \
		-v ${PWD}/db2/setup_ssl.sh:/resources/setup_ssl.sh \
		-e DBNAME=testdb \
		-e DB2INST1_PASSWORD=ibm123 \
		-e LICENSE=accept \
		-p 50000:50000 \
		-p 50002:50002 \
		--privileged=true \
		ibmcom/db2:11.5.7.0
	@sleep 300
	@docker exec \
		-d \
		--user db2inst1 \
		dbt-db2 \
		/bin/bash -c 'cd && source .bashrc && sh /resources/setup_ssl.sh'
	@poetry install

uninstall:
	@docker rm dbt-db2 --force
	@rm -rf db2/database/*
	@rm -rf db2/keystore/*
	@rm -rf .tox .venv .pytest_cache logs

test:
	@rm -rf .tox .pytest_cache logs
	@poetry run tox
