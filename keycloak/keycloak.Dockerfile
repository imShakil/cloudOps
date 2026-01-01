FROM quay.io/keycloak/keycloak:latest as builder

# Environment variables
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true
ENV KC_DB=postgres
ENV KC_FEATURES=token-exchange,admin-fine-grained-authz,preview

# Build optimized Keycloak
RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:latest

COPY --from=builder /opt/keycloak/ /opt/keycloak/
WORKDIR /opt/keycloak
USER 1000

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
