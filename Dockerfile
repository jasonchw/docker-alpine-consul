FROM jasonchw/alpine-base

ARG CONSUL_VER=0.7.0
ARG CONSUL_TEMPLATE_VER=0.15.0

RUN mkdir -p /etc/consul.d/ && \
    mkdir -p /opt/consul-web-ui/ && \
    mkdir -p /var/consul/

RUN apk update && apk upgrade && \
    apk add unzip libcap openssl && \
    curl -Lfso /tmp/consul.zip https://releases.hashicorp.com/consul/${CONSUL_VER}/consul_${CONSUL_VER}_linux_amd64.zip && \
    cd /usr/local/bin/ && \
    unzip /tmp/consul.zip && \
    rm -f /tmp/consul.zip && \
    curl -Lfso /tmp/consul-web-ui.zip https://releases.hashicorp.com/consul/${CONSUL_VER}/consul_${CONSUL_VER}_web_ui.zip && \
    cd /opt/consul-web-ui/ && \
    unzip /tmp/consul-web-ui.zip && \
    rm -f /tmp/consul-web-ui.zip && \
    curl -Lfso /tmp/consul-template.zip https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VER}/consul-template_${CONSUL_TEMPLATE_VER}_linux_amd64.zip && \
    cd /usr/local/bin/ && \
    unzip /tmp/consul-template.zip && \
    rm -f /tmp/consul-template.zip && \
    apk del unzip && \
    addgroup consul && \
    adduser -S -G consul consul 

COPY etc/consul.d/agent.json \
     etc/consul.d/consul-ui.json \
     /etc/consul.d/
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY start-consul.sh      /usr/local/bin/start-consul.sh
COPY healthcheck.sh       /usr/local/bin/healthcheck.sh

RUN chown -R consul:consul /etc/consul.d/ && \
    chown -R consul:consul /opt/consul-web-ui/ && \
    chown -R consul:consul /var/consul/ && \
    chmod +x /usr/local/bin/docker-entrypoint.sh && \
    chmod +x /usr/local/bin/start-consul.sh && \
    chmod +x /usr/local/bin/healthcheck.sh

EXPOSE 8500

ENTRYPOINT ["docker-entrypoint.sh"]

HEALTHCHECK --interval=2s --timeout=2s --retries=30 CMD /usr/local/bin/healthcheck.sh

