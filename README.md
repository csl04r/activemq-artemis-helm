This chart installs [Apache ActiveMQ Artemis](https://activemq.apache.org/components/artemis/)

## Docker image
This chart has been modified from the upstream to work with a 
[specially extended version the apache/activemq-artemis image](https://github.com/sherwin-williams-co/activemq-shw-extensions),
`sherwin-williams-co/activemq-shw-extensions` which adds the OAuth2LoginModule JAAS module.

## Installation

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


# Accessing the Broker
The broker can be accessed both from inside and outside of the cluster. All access requires TLS.

ActiveMQ Artemis exposes a number of messaging protocols, including JMS, AMQP, STOMP, and MQTT. The broker is configured to listen on the following ports:
 - 61616: OpenWire for JMS connections
 - 61613: STOMP
 - 1883: MQTT
 - 5672: AMQP
These are exposed as a headless service for access within the cluster, and using a metallb load balancer for access outside the cluster. 

# Authentication
The broker requires valid authentication and authorization to permit connecting and messaging operations. 
Two primary authentication methods are provided, both centering around the use of JWT tokens.

## In-Cluster Authentication
For applications running in the same cluster, you can use Kubernetes authentication. As a best practice, ensure that a unique, identifiable service account is created for your application, and bind it to your pods. Then load the token from the filesystem path `/var/run/secrets/kubernetes.io/serviceaccount/token` and use it as the connection password to authenticate with the broker.

## External Authentication
For applications running outside of the cluster, OAuth2 authentication is offered. You will need to establish and client ID and client secret in the Microsoft Entra platform, and use these to obtain a JWT authorization token. This token can then be used as the connection password to authenticate with the broker.

# JMS Example
Once you have a token, you can use the token in the "password" field of a JMS connection. Here is a quick example:

```java
import org.apache.activemq.artemis.jms.client.ActiveMQConnectionFactory;

import java.nio.file.Files;
import java.nio.file.Path;

public class JmsTest {
    public String getAccessToken() {
        // implement client credentials flow...
        // e.g. use spring's client registration manager
        return "";
    }

    static boolean inSameClusterAsBroker = false;

    public static void main(String[] args) throws Exception {
        String storeNumber = "lb0020";
        final var me = new JmsTest();
        final var password = me.inSameClusterAsBroker
                ? Files.readString(Path.of("/var/run/secrets/kubernetes.io/serviceaccount/token"))
                : me.getAccessToken();

        final var hostname = me.inSameClusterAsBroker
                ? "artemis." + storeNumber + "-service.stores.sherwin.com"
                : "artemis.shw-na-pos";

        var connectionFactory = new ActiveMQConnectionFactory(
                "tcp://" +
                        hostname +
                        ":61616?sslEnabled=true");
        // I recommend passing the password as a parameter to the createConnection method
        // instead of the connection factory constructor so that it can be refreshed.
        // the authentication is only checked upon connection creation, or perhaps when
        // you try to access new queues, topics, etc.
        try (var connection = connectionFactory.createConnection("my-app", password)) {
            connection.start();
            try (var session = connection.createSession()) {
                var destination = session.createQueue("test");
                try (var producer = session.createProducer(destination)) {
                    var message = session.createTextMessage("Hello, World!");
                    producer.send(message);
                }
                try (var consumer = session.createConsumer(destination)) {
                    var message = consumer.receive(1000);
                    if (message != null) {
                        System.out.println("Received message: " + message.getBody(String.class));
                    } else {
                        System.out.println("No message received");
                    }
                }
            }
        }
    }
}
```