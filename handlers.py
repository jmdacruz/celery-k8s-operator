import kopf
import yaml
import kubernetes.client

class literal(str): pass

def literal_representer(dumper, data):
    return dumper.represent_scalar('tag:yaml.org,2002:str', data, style='|')

yaml.add_representer(literal, literal_representer)



@kopf.on.create('celery.k8s.io', 'v1beta1', 'celeryapplications')
def create_fn(spec, meta, status, **kwargs):
    print(f"And here we are! Creating: {spec}")

    api = kubernetes.client.CoreV1Api()
    apps_v1 = kubernetes.client.AppsV1Api()

    annotations = meta.get('annotations', {})

    # Create configmap

    doc = yaml.safe_load(f"""
        apiVersion: v1
        kind: ConfigMap
        metadata:
            name: {meta['name']}-configmap
        data:
            config.yaml: 'PLACEHOLDER'
    """)
    doc['data']['config.yaml'] =  literal(yaml.dump(spec.get('celeryConfig')))
    doc['metadata']['annotations'] = annotations

    kopf.adopt(doc)

    configmap = api.create_namespaced_config_map(namespace=doc['metadata']['namespace'], body=doc)

    # create deployment for workers

    doc = yaml.safe_load(f"""
        apiVersion: apps/v1
        kind: Deployment
        metadata:
            name: {meta['name']}-worker
            labels:
                app: {meta['name']}-worker
        spec:
            replicas: {spec['workerConfig'].get('replicas', 1)}
            selector:
                matchLabels:
                    app: {meta['name']}-worker
            template:
                metadata:
                    labels:
                        app: {meta['name']}-worker
                spec:
                    containers:
                    - name: {meta['name']}-worker
                      image: {spec['image']}
                      imagePullPolicy: IfNotPresent
                      env:
                      - name: CELERY_CONFIG
                        value: /config.yaml
                      livenessProbe:
                          exec:
                              command:
                              - /bin/sh
                              - -c
                              - celery inspect ping -d celery@$(hostname)
                          initialDelaySeconds: 10
                          periodSeconds: 60
                          timeoutSeconds: 10
                      volumeMounts:
                      - name: config-volume
                        mountPath: /config.yaml
                        subPath: config.yaml
                    volumes:
                    - name: config-volume
                      configMap:
                        name: {meta['name']}-configmap

    """)

    doc['metadata']['annotations'] = annotations
    doc['spec']['template']['metadata']['annotations'] = annotations

    if 'resources' in spec['workerConfig']:
        doc['spec']['template']['spec']['containers'][0]['resources'] = spec['workerConfig']['resources']

    # copy containers[0].env
    # copy containers[0].envFrom

    kopf.adopt(doc)
    deployment = apps_v1.create_namespaced_deployment(namespace=doc['metadata']['namespace'], body=doc)


    # create deployment for flower

    flower_port = spec['celeryConfig'].get('port', 5555)

    doc = yaml.safe_load(f"""
        apiVersion: apps/v1
        kind: Deployment
        metadata:
            name: {meta['name']}-flower
            labels:
                app: {meta['name']}-flower
        spec:
            replicas: {spec['flowerConfig'].get('replicas', 1)}
            selector:
                matchLabels:
                    app: {meta['name']}-flower
            template:
                metadata:
                    labels:
                        app: {meta['name']}-flower
                spec:
                    containers:
                    - name: {meta['name']}-flower
                      image: {spec['image']}
                      imagePullPolicy: IfNotPresent
                      command: ['celery', 'flower', '--config', 'celeryconfig']
                      ports:
                      - containerPort: {flower_port}
                      env:
                      - name: CELERY_CONFIG
                        value: /config.yaml
                      volumeMounts:
                      - name: config-volume
                        mountPath: /config.yaml
                        subPath: config.yaml
                    volumes:
                    - name: config-volume
                      configMap:
                        name: {meta['name']}-configmap

    """)

    doc['metadata']['annotations'] = annotations
    doc['spec']['template']['metadata']['annotations'] = annotations
   
    if 'resources' in spec['flowerConfig']:
        doc['spec']['template']['spec']['containers'][0]['resources'] = spec['flowerConfig']['resources']

    if 'url_prefix' in spec['celeryConfig']:
        doc['spec']['template']['spec']['containers'][0]['command'].extend([f"--url_prefix={spec['celeryConfig']['url_prefix']}"])

    kopf.adopt(doc)
    flower_deployment = apps_v1.create_namespaced_deployment(namespace=doc['metadata']['namespace'], body=doc)

    # Create flower service
    doc = yaml.safe_load(f"""
        apiVersion: v1
        kind: Service
        metadata:
            name: {meta['name']}-flower
            labels:
                app: {meta['name']}-flower
        spec:
            ports:
            - port: {flower_port}
              protocol: TCP
            selector:
                app: {meta['name']}-flower
    """)
    doc['metadata']['annotations'] = annotations

    kopf.adopt(doc)
    flower_service = api.create_namespaced_service(namespace=doc['metadata']['namespace'], body=doc)

    return {'children': [configmap.metadata.uid, deployment.metadata.uid, flower_deployment.metadata.uid, flower_service.metadata.uid]}
