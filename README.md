#  Дипломная работа по профессии «Системный администратор»
# Сологуб Евгений SYS-31

Содержание
==========
* [Задача](#Задача)
* [Инфраструктура](#Инфраструктура)
    * [Сайт](#Сайт)
    * [Мониторинг](#Мониторинг)
    * [Логи](#Логи)
    * [Сеть](#Сеть)
    * [Резервное копирование](#Резервное-копирование)
* [Выполнение работы](#Выполнение-работы)
    * [Рабочая машина](#----рабочая-машина---- )
      * [Shell скрипты](#shell-скрипты)
      * [Подготовительные работы](#подготовительные-работы)
      * [Шаги](#Шаги)
    * [Облако](#----Облако----)
      * [Zabbix-server](#Zabbix-server)

---------

## Задача
Ключевая задача — разработать отказоустойчивую инфраструктуру для сайта, включающую мониторинг, сбор логов и резервное копирование основных данных. Инфраструктура должна размещаться в [Yandex Cloud](https://cloud.yandex.com/) и отвечать минимальным стандартам безопасности: запрещается выкладывать токен от облака в git. Используйте [инструкцию](https://cloud.yandex.ru/docs/tutorials/infrastructure-management/terraform-quickstart#get-credentials).

**Перед началом работы над дипломным заданием изучите [Инструкция по экономии облачных ресурсов](https://github.com/netology-code/devops-materials/blob/master/cloudwork.MD).**

## Инфраструктура
Для развёртки инфраструктуры используйте Terraform и Ansible.  

Не используйте для ansible inventory ip-адреса! Вместо этого используйте fqdn имена виртуальных машин в зоне ".ru-central1.internal". Пример: example.ru-central1.internal  - для этого достаточно при создании ВМ указать name=example, hostname=examle !! 

Важно: используйте по-возможности **минимальные конфигурации ВМ**:2 ядра 20% Intel ice lake, 2-4Гб памяти, 10hdd, прерываемая. 

**Так как прерываемая ВМ проработает не больше 24ч, перед сдачей работы на проверку дипломному руководителю сделайте ваши ВМ постоянно работающими.**

Ознакомьтесь со всеми пунктами из этой секции, не беритесь сразу выполнять задание, не дочитав до конца. Пункты взаимосвязаны и могут влиять друг на друга.

### Сайт
Создайте две ВМ в разных зонах, установите на них сервер nginx, если его там нет. ОС и содержимое ВМ должно быть идентичным, это будут наши веб-сервера.

Используйте набор статичных файлов для сайта. Можно переиспользовать сайт из домашнего задания.

Виртуальные машины не должны обладать внешним Ip-адресом, те находится во внутренней сети. Доступ к ВМ по ssh через бастион-сервер. Доступ к web-порту ВМ через балансировщик yandex cloud.

Настройка балансировщика:

1. Создайте [Target Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/target-group), включите в неё две созданных ВМ.

2. Создайте [Backend Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/backend-group), настройте backends на target group, ранее созданную. Настройте healthcheck на корень (/) и порт 80, протокол HTTP.

3. Создайте [HTTP router](https://cloud.yandex.com/docs/application-load-balancer/concepts/http-router). Путь укажите — /, backend group — созданную ранее.

4. Создайте [Application load balancer](https://cloud.yandex.com/en/docs/application-load-balancer/) для распределения трафика на веб-сервера, созданные ранее. Укажите HTTP router, созданный ранее, задайте listener тип auto, порт 80.

Протестируйте сайт
`curl -v <публичный IP балансера>:80` 

### Мониторинг
Создайте ВМ, разверните на ней Zabbix. На каждую ВМ установите Zabbix Agent, настройте агенты на отправление метрик в Zabbix. 

Настройте дешборды с отображением метрик, минимальный набор — по принципу USE (Utilization, Saturation, Errors) для CPU, RAM, диски, сеть, http запросов к веб-серверам. Добавьте необходимые tresholds на соответствующие графики.

### Логи
Cоздайте ВМ, разверните на ней Elasticsearch. Установите filebeat в ВМ к веб-серверам, настройте на отправку access.log, error.log nginx в Elasticsearch.

Создайте ВМ, разверните на ней Kibana, сконфигурируйте соединение с Elasticsearch.

### Сеть
Разверните один VPC. Сервера web, Elasticsearch поместите в приватные подсети. Сервера Zabbix, Kibana, application load balancer определите в публичную подсеть.

Настройте [Security Groups](https://cloud.yandex.com/docs/vpc/concepts/security-groups) соответствующих сервисов на входящий трафик только к нужным портам.

Настройте ВМ с публичным адресом, в которой будет открыт только один порт — ssh.  Эта вм будет реализовывать концепцию  [bastion host]( https://cloud.yandex.ru/docs/tutorials/routing/bastion) . Синоним "bastion host" - "Jump host". Подключение  ansible к серверам web и Elasticsearch через данный bastion host можно сделать с помощью  [ProxyCommand](https://docs.ansible.com/ansible/latest/network/user_guide/network_debug_troubleshooting.html#network-delegate-to-vs-proxycommand) . Допускается установка и запуск ansible непосредственно на bastion host.(Этот вариант легче в настройке)

Исходящий доступ в интернет для ВМ внутреннего контура через [NAT-шлюз](https://yandex.cloud/ru/docs/vpc/operations/create-nat-gateway).

### Резервное копирование
Создайте snapshot дисков всех ВМ. Ограничьте время жизни snaphot в неделю. Сами snaphot настройте на ежедневное копирование.

## Выполнение работы

Все операции выполняются под пользователем gekasologub либо с повышением прав sudo

### --- Рабочая машина ---

#### Shell скрипты:  
1) ./terrafotm/terraform_start.sh - запуск терраформирования с указанными параметрами по *.tf файлам текущей директории + запуск add_ip_to_ssh_config.sh  
2) ./terrafotm/add_ip_to_ssh_config.sh - извлечение output полученных в процессе тераформирования в файлик file_nat_ip.txt (при необходимости)  
3) ./terrafotm/terraform_destroy.sh - обратный процесс терраформирования (разрушения) удалить все созданные по текущим конфигурациям сущности (*на пракетике требуется дочищать вручную группы и машины привязанные к балансировщику. почему-то процесс уходит в цикл или подвисает)  
4) ./ansible/mv_ansible_start.sh - копирование конфигураций и плейбуков в ключевые директории ansible

#### Подготовительные работы:  
1) Создать пользователя gekasologub в группе sudo  
2) Установить Ansible  
3) Если отсутствует, Скачать terraform и поместить его в папку ./terraform  (в текущей сборке уже должно быть)  
4) Сгенерировать ssh ключ ed25519 для пользователя gekasologub, который будет ипользоваться в дальнейшем  
5) Иметь оплаченное облако YandexCloud. Получить yandex_cloud_token, folder_id, cloud_id, знать iso нужного образа ('Debian' image_id = "fd83df435lnopq6dbqdh")  

#### Шаги:  
0) Произвести подготовительные работы  
1) Перенести содержимое папки ./ansible/0_ansible_etc/ в /etc/ansible  
2) Перенести содержимое папки ./ansible/2_ansible_roles в /etc/ansible/roles/  
3) Выполнить команду: ```bash ./terrafotm/terraform_start.sh``` 
4) Выполнить команду: ```ansible-playbook --check /etc/ansible/roles/role_diplom_netology/files/all_playbooks.yml```  (проверяем корректность синтаксиса и связь. может быть ошибка из-за того что машины пока без установленных утилит)
5) Выполнить команду: ```ansible-playbook /etc/ansible/roles/role_diplom_netology/files/all_playbooks.yml``` (* либо ansible-playbook --private-key=/home/gekasologub/.ssh/id_ed25519  --ssh-common-args='-o StrictHostKeyChecking=no' /etc/ansible/roles/role_diplom_netology/files/all_playbooks.yml)  
6) Инфраструктура сформирована. Теперь ручная настройка в интерфейсах программ (zabbix, kibana), доступных по публичным адресам  

### --- Облако ---

*Нужные адреса можем посмотреть в файле ./terrafotm/file_nat_ip.txt*

#### Zabbix-server: 

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

3) Переходим в Dashboards и создаем отображение необходимых нам метрик. [Шаблоны Zabbix](https://www.zabbix.com/documentation/5.2/ru/manual/config/templates_out_of_the_box)


#### Kibana

0) Проходим по публичному адресу и подключаем кибану к эластику:
    - Выбрать подключение по адресу (Configure manually). Ввести: http://vm-elk:9200
    - Пройти на сервер: ```ssh -J bastion_netology gekasologub@vm-kibana```
    - Получить код: ```docker exec <id container/ or name> bash bin/kibana-verification-code``` (name: kibana)
1) *При необходимости перезапустить машины с установленными filebeat (vm-nginx-1,2), чтобы перезапустить модули внутри.
2) Проверяем что биты стучатся в эластик и кибану : Kibana/Stack Management/Index Management/Data streams
3) Создаем ссылки на потоки Kibana/Stack Management/Data views
4) Делаем дашборды Kibana/Analytics/Create dashboard

----
----
*Утилиты проверки сети которые пригодились в проекте nmap, netcat, ufw

```nmap <vm-hostname> -Pn
nc -vz <vm-hostname> <port>
ufw status```

Тестим балансировщик через терминал (запрос не кешируется)
```curl <ip application load balancer>```