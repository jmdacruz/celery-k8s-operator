# Kubernetes Operator for Celery

![status:alpha](https://img.shields.io/badge/status-alpha-red)
![build:missing](https://img.shields.io/badge/build-WIP-red)

This project is an attempt to implement a fully functioning Kubernetes Operator for Celery, based on the concepts documented [here](https://github.com/celery/ceps/issues/24). While there is a fully functioning [Operator SDK](https://github.com/operator-framework/operator-sdk) in Go, and given that Celery is natively written in Python, we decided to use [kopf](https://github.com/zalando-incubator/kopf) as the framework for building and running this operator.

## Project status

This is still very much a proof-of-concept, and lacks many of the features you would expect in a production environment. 

## Why?

Operating a Celery cluster in a production environment can be a demanding task. If you are already using Kubernetes to deploy your applications, then Kubernetes operators offer a way to manage complex deployments such as databases and clusters, and Celery can also benefit from them. Using an operator means that you don't have to worry about creating deployments for your cluster, and managing rolling updates whenever there is a new version of your code, or when changing the characteristics of your cluster. All this know-how is baked into the operator's logic.

## What's in scope?

* Operating a Kubernetes deployment for Celery workers, including liveness checks for automating self-healing
* Operating a Kubernetes deployment for Celery flower
* Creating a Kubernetes service for Celery flower
* Managing updates of the application, such as changes on the cluster size, changes on the application code, and others.

This operator includes:
* A `CRD` called `CeleryApplication`
* A set of [deployment](deploy) artifacts for the actual operator deployment, namespace, service account, role, and role binding.
* The actual operator Docker image, built using [kopf](https://github.com/zalando-incubator/kopf)

## What's not in scope?

* Operating the messaging infrastructure: This operator focuses on managing your Celery workers, and leaves the task of operating the messaging infrastructure to the tons of Kubernetes operators (and deployment examples) for Redis, RabbitMQ, and so on.
* Operating Celery under Django: I simply don't have experience with Django, and don't know if this is doable. Not my priority for the time being, but contributions are welcome!

## Approach

We follow an approach inspired by [Lyft's Kubernetes Operator for Apache Flink](https://github.com/lyft/flinkk8soperator), where the CRD expects the provided application image to follow a particular API:
* An environment variable called `CELERY_CONFIG` will be injected by the operator into the Docker image, containing the path to a YAML file with the configuration for the worker. The image is expected to load this configuration upon worker start.
* The `celery` CLI is expected to be available on the Docker image (in the `PATH` environment variable), so that the operator can inject the liveness probes using `celery inspect ping`.

Take a look at the [examples](examples) for details on how to create a worker image according to this API.

## Development

We rely on [pipenv](https://github.com/pypa/pipenv) for environment and package management and [kind](https://github.com/kubernetes-sigs/kind) for bootstrapping local Kubernetes clusters.

## Deployment

You can deploy the operator and related resources by simply doing:

```console
kubectl apply -f deploy/crd.yml
kubectl apply -f deploy/namespace.yml
kubectl apply -f deploy/role_binding.yml
kubectl apply -f deploy/role.yml
kubectl apply -f deploy/service_account.yml
```

You can then launch the operator by running:

```console
kubectl apply -f deploy/operator.yml
```

You can build the operator's image locally by running:

```console
docker build -t celery-operator:latest .
kind load docker-image celery-operator:latest
```

The last command will ensure that the docker image is loaded into your `kind` cluster. Ignore if using `minikube` or something else.


## Debugging

For debugging, do not apply the `operator.yml` file, and simply launch the operator in debug mode by running:

```console
pipenv run kopf run handlers.py
```

Take a look at [kopf](https://github.com/zalando-incubator/kopf) for more details on debugging parameters, or simply run `pipenv run kopf run --help`

This assumes you have a running Kubernetes cluster and `kubectl` is configured to access it. We recommend the use of [kind](https://github.com/kubernetes-sigs/kind) for bootstrapping a local Kubernetes cluster. It's pretty awesome, and lightweight!

Take a look at the [examples](examples) for details on how to create a worker image and `CeleryApplication` resource.

## Contributions

This operator is still in its early stages. Contributions, suggestions, and complains are welcome! Feel free to create issues.