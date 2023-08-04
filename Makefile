.PHONY: run-playbook run-script run-conf

all: run-playbook run-script run-conf

run-playbook:
	@echo "Executing playbook to deploy topology"
	@ansible-playbook ./playbooks/deploy-clab-topology.yml
	@echo "Waiting 10 seconds before running script"
	@sleep 10

run-script:
	@echo "Executing script to enable ssh/rsa auth on the nodes"
	@expect ./scripts/expect.exp
	@echo "Waiting 3 seconds before deploying config"
	@sleep 3 

run-conf:
	@echo "Running playbook to configure nodes"
	@ansible-playbook ./playbooks/conf-files.yml -i ./inventory/inventory.yml
