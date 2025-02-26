This chart installs [Apache ActiveMQ Artemis](https://activemq.apache.org/components/artemis/)

## Docker image
This chart has been modified from the upstream to work with a 
[specially extended version the apache/activemq-artemis image](https://github.com/sherwin-williams-co/activemq-shw-extensions),
`sherwin-williams-co/activemq-shw-extensions` which adds the OAuth2LoginModule JAAS module.

## Usage

[Helm](https://helm.sh) must be installed and initialized to use the charts.
Please refer to Helm's [documentation](https://helm.sh/docs/) to get started.

Once Helm is set up properly, add the repo as follows:

```console
helm repo add rt https://artifactory.sherwin.com/artifactory/helm-local
```

Then you can install the chart:

```console
helm install my-artemis rt/activemq-artemis -f my-values.yaml
```

# Values Documentation
See the [README in the chart directory](./charts/artemis/README.md) for more information on the values that can be set.

