.ONESHELL:

# Service
NAMESPACE = kube-system
RELEASE_NAME = cluster-defaults
# ENV ?= ### Specify the env to use
ENV = turingpi
pod := $$(kubectl get pods -n ${NAMESPACE} |  grep -m1 ${RELEASE_NAME} | cut -d' ' -f1)

# Current dir
CURRENT_DIR = $(shell pwd)
HELM_CHART_DIR = ${CURRENT_DIR}/helm

# HELM
HELM_BIN ?= helm
FORCE ?=
ifeq ($(strip ${FORCE}),true)
SET_FORCE := --force
else
SET_FORCE :=
endif

help:
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<command> <option>\033[0m\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@printf "\033[1mVariables\033[0m\n"
	@grep -E '^[a-zA-Z0-9_-]+.*?### .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?### "}; {printf "  \033[36m%-21s\033[0m %s\n", $$1, $$2}'
	@# Use ##@ <section> to define a section
	@# Use ## <comment> aside of the target to get it shown in the helper
	@# Use ### <comment> to comment a variable

##@ Installation part
warning: ## A warning to make you warned
	@echo -e "$$(cat ARGOCD-OWNED)\n"
	@exit 1
template: ## Helm template
	@${HELM_BIN} template --dependency-update ${RELEASE_NAME} ${HELM_CHART_DIR} --namespace ${NAMESPACE} -f ${HELM_CHART_DIR}/values.${ENV}.yaml
dry-run: template warning ## Template plus dry-run of the helm chart
	@${HELM_BIN} upgrade --dry-run ${SET_FORCE} --install --namespace ${NAMESPACE} -f ${HELM_CHART_DIR}/values.${ENV}.yaml ${RELEASE_NAME} ${HELM_CHART_DIR}
install: warning ## Helm installation
	@${HELM_BIN} upgrade ${SET_FORCE} --install --namespace ${NAMESPACE} --create-namespace -f ${HELM_CHART_DIR}/values.${ENV}.yaml ${RELEASE_NAME} ${HELM_CHART_DIR}
logs: ## Get pod logs
	@kubectl logs --since=1h -f -n ${NAMESPACE} $(pod)

##@ Validation and Testing
lint: ## Lint the helm chart
	@${HELM_BIN} lint ${HELM_CHART_DIR}
validate: lint ## Validate the helm chart
	@echo "📋 Validating Helm chart..."
	@${HELM_BIN} template ${RELEASE_NAME} ${HELM_CHART_DIR} --dry-run > /dev/null
	@echo "✅ Template validation passed!"
	@${HELM_BIN} template ${RELEASE_NAME} ${HELM_CHART_DIR} -f ${HELM_CHART_DIR}/values.${ENV}.yaml --dry-run > /dev/null
	@echo "✅ Values validation passed!"
	@echo "🎉 Chart validation completed successfully"

##@ Priority Classes Management
list-priority-classes: ## List all priority classes in the cluster
	@kubectl get priorityclasses --sort-by=.value -o wide
describe-priority-classes: ## Describe all priority classes managed by this chart
	@kubectl get priorityclasses -l app.kubernetes.io/managed-by=Helm,app.kubernetes.io/name=cluster-defaults -o name | xargs kubectl describe
check-default-priority: ## Show which priority class is set as default
	@kubectl get priorityclasses --sort-by=.value -o custom-columns=NAME:.metadata.name,VALUE:.value,GLOBAL-DEFAULT:.globalDefault | grep true || echo "No global default set"

##@ Utilities
show-values: ## Show values for specified environment
	@echo "Values for environment: ${ENV}"
	@cat ${HELM_CHART_DIR}/values.${ENV}.yaml
test-priority: ## Test priority class assignment (requires POD_NAME)
	@if [ -z "$(POD_NAME)" ]; then echo "Usage: make test-priority POD_NAME=<pod-name>"; exit 1; fi
	@kubectl get pod $(POD_NAME) -o jsonpath='{.spec.priorityClassName}' || echo "No priority class assigned"
	@echo ""
	@kubectl get pod $(POD_NAME) -o jsonpath='{.spec.priority}' || echo "No priority value"
