Все операции выполняются под пользователем gekasologub либо с повышением прав sudo

--- Рабочая машина ---

Подготовительные работы:  
1) Создать пользователя gekasologub в группе sudo  
2) Установить Ansible  
3) Если отсутствует, Скачать terraform и поместить его в папку ./terraform  (в текущей сборке уже должно быть)  
4) Сгенерировать ssh ключ ed25519 для пользователя gekasologub, который будет ипользоваться в дальнейшем  
5) Иметь оплаченное облако YandexCloud. Получить yandex_cloud_token, folder_id, cloud_id, знать iso нужного образа ('Debian' image_id = "fd83df435lnopq6dbqdh")  


Shell скрипты:  
1) ./terrafotm/terraform_start.sh - запуск терраформирования с указанными параметрами по *.tf файлам текущей директории + запуск add_ip_to_ssh_config.sh  
2) ./terrafotm/add_ip_to_ssh_config.sh - извлечение output полученных в процессе тераформирования в файлик file_nat_ip.txt (при необходимости)  
3) ./terrafotm/terraform_destroy.sh - обратный процесс терраформирования (разрушения) удалить все созданные по текущим конфигурациям сущности (*на пракетике требуется дочищать вручную группы и машины привязанные к балансировщику. почему-то процесс уходит в цикл или подвисает)  
4) ./ansible/mv_ansible_start.sh - копирование конфигураций и плейбуков в ключевые директории ansible

Шаги:  
0) Произвести подготовительные работы  
1) Перенести содержимое папки ./ansible/0_ansible_etc/ в /etc/ansible  
2) Перенести содержимое папки ./ansible/2_ansible_roles в /etc/ansible/roles/  
3) Выполнить команду: bash ./terrafotm/terraform_start.sh  
4) Выполнить команду: ansible-playbook --check /etc/ansible/roles/role_diplom_netology/files/all_playbooks.yml  (проверяем корректность синтаксиса и связь. может быть ошибка из-за того что машины пока без установленных утилит)
5) Выполнить команду: ansible-playbook /etc/ansible/roles/role_diplom_netology/files/all_playbooks.yml (* либо ansible-playbook --private-key=/home/gekasologub/.ssh/id_ed25519  --ssh-common-args='-o StrictHostKeyChecking=no' /etc/ansible/roles/role_diplom_netology/files/all_playbooks.yml)  
6) Инфраструктура сформирована. Теперь ручная настройка в интерфейсах программ (zabbix, kibana), доступных по публичным адресам  

--- Облако ---

Zabbix-server: 

1) Добавим Hosts (Monitoring/Hosts/create host):  
- Host name (любое)
- Host groups (любое)
- Templates (настраиваем агентов , поэтому выбираем Linux by Zabbix agent)
- Interfaces /Add/Agent (Указываем имена DNS сервера, т.к. машины облачные и только имена не будут изменяться при пересоздании, соответствующий порт из конфига агента 10050, выбираем поиск по DNS.поле ip address оставим пустым)
- Добавляем настроку (жмем Add)

2) В Hosts появится созданный нами хост агента.
- Жмем на его Name и выбираем Ping
- Удостовериваемся, что пинг проходит
- Ждем когда в колонке Availiable загорится зеленый индикатор, который уведомит об установлении контакта и начале обмена.

3) Переходим в Dashboards и создаем отображение необходимых нам метрик. (https://www.zabbix.com/documentation/5.2/ru/manual/config/templates_out_of_the_box)


Kibana

0) Проходим по публичному адресу и подключаем кибану к эластику:
    - Выбрать подключение по адресу. Ввести: http://vm-elk:9200
    - Пройти на сервер: ssh -J bastion_netology gekasologub@vm-kibana
    - Получить код: docker exec <id container/ or name> /bin/kibana-verification-code (name: kibana)
1) 

----
----
*Утилиты проверки сети которые пригодились в проекте nmap, netcat, ufw

nmap <vm-hostname> -Pn
nc -vz <vm-hostname> <port>
ufw status

curl <ip application load balancer>