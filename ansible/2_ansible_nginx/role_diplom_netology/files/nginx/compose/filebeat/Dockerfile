from public.ecr.aws/elastic/filebeat:8.15.1
CMD bash -c "pwd && filebeat modules enable nginx && filebeat setup"
CMD rm /usr/share/filebeat/data/filebeat.lock
