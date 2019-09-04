SHELL := bash
K8S_CLUSTER_NAME := storj

.PHONY: help
help:
	@awk 'BEGIN { \
		FS = ":.*##"; \
		printf "\nUsage:\n  make \033[36m<target>\033[0m\n"\
	} \
	/^[a-zA-Z_-]+:.*?##/ { \
		printf "  \033[36m%-17s\033[0m %s\n", $$1, $$2 \
	} \
	/^##@/ { \
		printf "\n\033[1m%s\033[0m\n", substr($$0, 5) \
	} ' ${MAKEFILE_LIST}


##@ K8s environment

.PHONY: create-cluster
create-cluster: ## Create K8s cluster with dashboard
	@kind create cluster --name ${K8S_CLUSTER_NAME}

.PHONY: delete-cluster
delete-cluster: ## Delete K8s cluster
	@kind delete cluster --name ${K8S_CLUSTER_NAME}

.PHONY: show-kubeconfig
show-kubeconfig: ## Show the env var needed to use the cluster with kubectl (tip: export $(make show-kubeconfig))
	@echo KUBECONFIG="$(shell kind get kubeconfig-path --name=\"${K8S_CLUSTER_NAME}\")"

.PHONY: run-proxy
run-proxy: .kubectl-env ## Run kubectl proxy (NOTE: this command block while running the server)
	@kubectl proxy

.PHONY: deploy-dashboard
deploy-dashboard: .kubectl-env  ## Deploy K8s web dashboard in the cluster
	@if [[ -z $$(kubectl -n kube-system get secret | grep admin-user) ]]; then \
		kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta1/aio/deploy/recommended.yaml; \
		kubectl apply -f k8s/dashboard-adminuser.yaml; \
	 fi

.PHONY: show-dashboard-access
show-dashboard-access: deploy-dashboard ## Show the user token and the URL for accessing the dashboard
	@kubectl -n kube-system describe secret $(shell kubectl -n kube-system get secret | grep admin-user | awk '{print $$1}') | grep "token:"
	@echo
	@echo "visit:  http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"

.PHONY: .kubectl-env
.kubectl-env: ## Requirements for running kubectl commands in other targets
	@export KUBECONFIG="$(shell kind get kubeconfig-path --name=\"${K8S_CLUSTER_NAME}\")"
