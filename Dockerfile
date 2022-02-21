FROM bitnami/kubectl
COPY ./entrypoint /entrypoint
ENTRYPOINT ["/entrypoint"]   