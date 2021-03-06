FROM registry.svc.ci.openshift.org/openshift/release:golang-1.11 AS builder
WORKDIR /go/src/github.com/prometheus/prometheus
COPY . .
RUN make build

FROM  registry.svc.ci.openshift.org/openshift/origin-v4.0:base
LABEL io.k8s.display-name="OpenShift Prometheus" \
      io.k8s.description="The Prometheus monitoring system and time series database." \
      io.openshift.tags="prometheus,monitoring" \
      maintainer="The Prometheus Authors <prometheus-developers@googlegroups.com>" \
      version="v2.7.2"

ARG FROM_DIRECTORY=/go/src/github.com/prometheus/prometheus
COPY --from=builder ${FROM_DIRECTORY}/prometheus                            /bin/prometheus
COPY --from=builder ${FROM_DIRECTORY}/promtool                              /bin/promtool
COPY --from=builder ${FROM_DIRECTORY}/documentation/examples/prometheus.yml /etc/prometheus/prometheus.yml
COPY --from=builder ${FROM_DIRECTORY}/console_libraries/                    /usr/share/prometheus/console_libraries/
COPY --from=builder ${FROM_DIRECTORY}/consoles/                             /usr/share/prometheus/consoles/

RUN ln -s /usr/share/prometheus/console_libraries /usr/share/prometheus/consoles/ /etc/prometheus/
RUN mkdir -p /prometheus && \
    chgrp -R 0 /etc/prometheus /prometheus && \
    chmod -R g=u /etc/prometheus /prometheus

USER       nobody
EXPOSE     9090
WORKDIR    /prometheus
ENTRYPOINT [ "/bin/prometheus" ]
CMD        [ "--config.file=/etc/prometheus/prometheus.yml", \
             "--storage.tsdb.path=/prometheus", \
             "--web.console.libraries=/usr/share/prometheus/console_libraries", \
             "--web.console.templates=/usr/share/prometheus/consoles" ]
