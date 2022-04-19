FROM haproxy:2.0
RUN mkdir --parents /var/lib/haproxy && chown -R haproxy:haproxy /var/lib/haproxy
RUN mkdir /run/haproxy
COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
CMD ["haproxy", "-db", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]
