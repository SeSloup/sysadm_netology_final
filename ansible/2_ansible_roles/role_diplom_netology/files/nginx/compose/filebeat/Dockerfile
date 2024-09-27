from public.ecr.aws/elastic/filebeat:8.15.1
COPY ./filebeat_cnf/filebeat.yml /usr/share/filebeat/filebeat.yml
COPY ./filebeat_cnf/nginx.yml /usr/share/filebeat/modules.d/nginx.yml
CMD bash -c "pwd && filebeat modules enable nginx && filebeat setup"
CMD rm /usr/share/filebeat/data/filebeat.lock
