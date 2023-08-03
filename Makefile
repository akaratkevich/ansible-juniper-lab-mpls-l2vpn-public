.PHONY: run-playbook run-script

all: run-playbook run-script

run-playbook:
	@echo "Executing playbook to deploy topology"
	@ansible-playbook ./playbooks/deploy-clab-topology.yml
	@echo "Waiting 10 seconds before running script"
	@sleep 10

run-script:
	@echo "Executing script to enable ssh/rsa auth on the nodes"
	@expect ./scripts/expect.exp

