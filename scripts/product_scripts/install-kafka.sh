#!/bin/bash
#This script is to install development kafka

export cluster_name=$1
export domain_name=$2
export openshift_user=$3
export openshift_password=$4
export namespace=$5
export release_name=$6

if [[ "$release_name" == "" ]]; then
  release_name="kafka-dev"
fi

echo "Logging to Openshift - https://api.${cluster_name}.${domain_name}:6443 .."
var=0
oc login "https://api.${cluster_name}.${domain_name}:6443" -u "$openshift_user" -p "$openshift_password" --insecure-skip-tls-verify=true
var=$?
echo "exit code: $var"

echo "Installing Kafka in Namespace: ${namespace} .."

cat << EOF | oc apply -f -
apiVersion: eventstreams.ibm.com/v1beta1
kind: EventStreams
metadata:
  name: ${release_name}
  namespace: ${namespace}
spec:
  version: 10.1.0
  license:
    accept: true
    use: CloudPakForIntegrationNonProduction
  adminApi: {}
  adminUI: {}
  apicurioRegistry: {}
  collector: {}
  restProducer: {}
  security:
    internalTls: TLSv1.2
  strimziOverrides:
    kafka:
      replicas: 1
      authorization:
        type: runas
      config:
        inter.broker.protocol.version: '2.6'
        interceptor.class.names: com.ibm.eventstreams.interceptors.metrics.ProducerMetricsInterceptor
        log.message.format.version: '2.6'
        offsets.topic.replication.factor: 1
        transaction.state.log.min.isr: 1
        transaction.state.log.replication.factor: 1
      listeners:
        external:
          authentication:
            type: scram-sha-512
          type: route
        tls:
          authentication:
            type: tls
      metrics: {}
      storage:
        type: ephemeral
    zookeeper:
      replicas: 1
      metrics: {}
      storage:
        type: ephemeral
EOF
        
echo "Validating Kafka installation.."
kafka=0
zookeeper=0
time=0

while [[ kafka -eq 0 ]]; do

	if [ $time -gt 5 ]; then
      		echo "Timed-out : Kafka Installation failed.."
      		exit 1
    	fi
	
	oc get pods -n ${namespace} | grep ${release_name} | grep kafka | grep Running | grep 1/1
	resp=$?
	if [[ resp -ne 0 ]]; then
		echo -e "No running pods found for ${release_name} Waiting.."
		time=$((time + 1))
		sleep 60
	else
		echo "Kafka Pod(s) are now running.." 
		kafka=1;
	fi
done

while [[ zookeeper -eq 0 ]]; do

	if [ $time -gt 5 ]; then
      		echo "Timed-out : Kafka Installation failed.."
      		exit 1
    	fi
	
	oc get pods -n ${namespace} | grep ${release_name} | grep zookeeper | grep Running | grep 1/1
	resp=$?
	if [[ resp -ne 0 ]]; then
		echo -e "No running pods found for ${release_name} Waiting.."
		time=$((time + 1))
		sleep 60
	else
		echo "Zookeeper Pod(s) are now running.." 
		zookeeper=1;
	fi
done

echo "Installation completed: Kafka Name: ${qm_name}, Broker Count: 1, Zookeeper count: 1"
