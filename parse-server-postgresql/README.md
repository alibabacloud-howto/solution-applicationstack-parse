# Deploy Application Stack Parse Server with RDS for PostgreSQL on Alibaba Cloud

You can access the tutorial artifact including deployment script (Terraform), related source code, sample data and instruction guidance from the github project:
[https://github.com/alibabacloud-howto/solution-applicationstack-parse/tree/main/parse-server-postgresql](https://github.com/alibabacloud-howto/solution-applicationstack-parse/tree/main/parse-server-postgresql)

More tutorial around Alibaba Cloud Database, please refer to:
[https://github.com/alibabacloud-howto/database](https://github.com/alibabacloud-howto/database)

---
### Overview

[Parse](https://parseplatform.org/) is the complete application stack for building applications faster with object and file storage, user authentication, push notifications, dashboard and more out of the box. Comparing with [Google Firebase](https://firebase.google.com/), Parse is a bunch of pure open source projects [https://github.com/parse-community](https://github.com/parse-community) for application building and life cycle management.
More readings about [Firebase vs. Parse Server](https://blog.back4app.com/firebase-parse/) by Back4App.

In this solution tutorial, let's see how to install and deploy Parse Server with [RDS for PostgreSQL](https://www.alibabacloud.com/product/apsaradb-for-rds-postgresql) on Alibaba Cloud.

Deployment architecture:

![image.png](https://github.com/alibabacloud-howto/solution-applicationstack-parse/raw/main/parse-server-postgresql/images/archi.png)

---
### Index

- [Step 1. Use Terraform to provision ECS and RDS for PostgreSQL database on Alibaba Cloud](https://github.com/alibabacloud-howto/solution-applicationstack-parse/tree/main/parse-server-postgresql#step-1-use-terraform-to-provision-ecs-and-rds-for-postgresql-database-on-alibaba-cloud)
- [Step 2. Install and deploy parse-server with ECS and RDS for PostgreSQL](https://github.com/alibabacloud-howto/solution-applicationstack-parse/tree/main/parse-server-postgresql#step-2-install-and-deploy-parse-server-with-ecs-and-rds-for-postgresql)
- [Step 3. Install parse-dashboard on ECS](https://github.com/alibabacloud-howto/solution-applicationstack-parse/tree/main/parse-server-postgresql#step-3-install-parse-dashboard-on-ecs)
- [Step 4. Post application data to verify parse-server and parse-dashboard](https://github.com/alibabacloud-howto/solution-applicationstack-parse/tree/main/parse-server-postgresql#step-4-post-application-data-to-verify-parse-server-and-parse-dashboard)

---
### Step 1. Use Terraform to provision ECS and RDS for PostgreSQL database on Alibaba Cloud

If you are the 1st time to use Terraform, please refer to [https://github.com/alibabacloud-howto/terraform-templates](https://github.com/alibabacloud-howto/terraform-templates) to learn how to install and use the Terraform on different operating systems.

Run the [terraform script](https://github.com/alibabacloud-howto/solution-applicationstack-parse/blob/main/parse-server-postgresql/deployment/terraform/main.tf) to initialize the resources (in this tutorial, we use RDS for PostgreSQL as backend database, so ECS and RDS for PostgreSQL are included in the Terraform script). Please specify the necessary information and region to deploy.

![image.png](https://github.com/alibabacloud-howto/solution-applicationstack-parse/raw/main/parse-server-mongodb/images/tf-parms.png)

After the Terraform script execution finished, the ECS instance information are listed as below.

![image.png](https://github.com/alibabacloud-howto/solution-applicationstack-parse/raw/main/parse-server-postgresql/images/tf-done.png)

- ``eip_ecs``: The public EIP of the ECS for parse server host
- ``rds_pg_port_parse_server_database``: The RDS for PostgreSQL database service port
- ``rds_pg_url_parse_server_database``: The RDS for PostgreSQL database connection URL

---
### Step 2. Install and deploy parse-server with ECS and RDS for PostgreSQL

Please log on to ECS with ``ECS EIP``. By default, the password is ``N1cetest``, which is preset in the terraform provision script in Step 1. If you've already changed it, please update accordingly.

```bash
ssh root@<ECS_EIP>
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-ofbiz/images/ecs-logon.png)

Node.js should have already been installed automatically via the ``remote-exec`` provisioner in the [Terraform script](https://github.com/alibabacloud-howto/solution-applicationstack-parse/blob/main/parse-server-postgresql/deployment/terraform/main.tf) within the Step 1. Parse Server requires Node 8 or newer. Here we install the Node 12. 

Execute the following commands to install ```parse-server```.

```
npm install -g parse-server
ln -s ~/node/lib/node_modules/parse-server/bin/parse-server /usr/local/bin/parse-server
```

![image.png](https://github.com/alibabacloud-howto/solution-applicationstack-parse/raw/main/parse-server-mongodb/images/parse-server_done.png)

Execute the following commands to verify the Node modules have been installed successfully.

```
ll /usr/local/bin/
```

![image.png](https://github.com/alibabacloud-howto/solution-applicationstack-parse/raw/main/parse-server-mongodb/images/node_verify.png)

Then execute the following command to start the installed ```parse-server```.

```
parse-server --appId <APP_ID> --masterKey <MASTER_KEY> --databaseURI <POSTGRESQL_URL> &
```

Please replace the parameters accordingly:
- ```<APP_ID>``` :  your application ID
- ```<MASTER_KEY>``` : your application secret key
- ```<POSTGRESQL_URL>``` : the PostgreSQL URL of the provisioned RDS for PostgreSQL instance in ```Step 1```.

For example, execute the command like the following. We've set the default database (``parse_server_db``), user name (``parse``) and password (``N1cetest``) of the RDS for PostgreSQL in the [terraform script](https://github.com/alibabacloud-howto/solution-applicationstack-parse/blob/main/parse-server-postgresql/deployment/terraform/main.tf).
Please update accordingly if you've changed them.

```
parse-server --appId my_application_id --masterKey 12345678 --databaseURI postgres://parse:N1cetest@pgm-xxxxxxx.pg.rds.aliyuncs.com:5432/parse_server_db &
```

![image.png](https://github.com/alibabacloud-howto/solution-applicationstack-parse/raw/main/parse-server-postgresql/images/parse-server_start.png)

Now the ```parse-server``` is running and listening the service port ```1337```. The service API URL is ```http://<ECS_EIP>:1337/parse```.

---
### Step 3. Install parse-dashboard on ECS

Actually, the ```parse-server``` is ready for serving the application now, you can go to ```Step 4``` to verify and interact with ```parse-server``` directly. But ```parse-dashboard``` is high recommended to be installed for administration and monitoring of the applications on ```parse-server```.
For more information about ```parse-dashboard```, please visit [https://github.com/parse-community/parse-dashboard](https://github.com/parse-community/parse-dashboard).

Now execute the following commands to install ```parse-dashboard```.

```
npm install -g parse-dashboard
ln -s ~/node/lib/node_modules/parse-dashboard/bin/parse-dashboard /usr/local/bin/parse-dashboard
ll /usr/local/bin/
```

![image.png](https://github.com/alibabacloud-howto/solution-applicationstack-parse/raw/main/parse-server-mongodb/images/parse-dashboard_done.png)

Then execute the following commands to create a configuration file for starting dashboard of the previous application started on ```parse-server```.

```
cd ~/node/lib/node_modules/parse-dashboard/bin
vim parse-dashboard.json
```

Input the following content into the file ```parse-dashboard.json```, please remember to
- replace ```<ECS_EIP>``` with the provisioned ECS EIP in ```Step 1```
- replace ```<APP_ID>``` with your application ID used when starting ```parse-server``` in ```Step 2```
- replace ```<MASTER_KEY>``` with your application secret key used when starting ```parse-server``` in ```Step 2```

And here we preset the user name and password as ```admin``` and ```admin``` for ```parse-dashboard``` log on. You can change it accordingly.

```
{
  "apps": [
    {
      "serverURL": "http://<ECS_EIP>:1337/parse",
      "appId": "<APP_ID>",
      "masterKey": "<MASTER_KEY>",
      "appName": "MyApp",
      "supportedPushLocales": ["en", "ru", "fr"]
    }
  ],
  "users": [
    {
      "user":"admin",
      "pass":"admin"
    }
  ]
}
```

![image.png](https://github.com/alibabacloud-howto/solution-applicationstack-parse/raw/main/parse-server-mongodb/images/parse-dashboard_config.png)

Then execute the following command to start the ```parse-dashboard```.

```
parse-dashboard --dev --config parse-dashboard.json &
```

![image.png](https://github.com/alibabacloud-howto/solution-applicationstack-parse/raw/main/parse-server-mongodb/images/parse-dashboard_start.png)

Now the ```parse-dashboard``` has been started, please visit ```http://<ECS_EIP>:4040```.

![image.png](https://github.com/alibabacloud-howto/solution-applicationstack-parse/raw/main/parse-server-mongodb/images/parse-dashboard_web_1.png)

Log on, then we can see dashboard of the application.

![image.png](https://github.com/alibabacloud-howto/solution-applicationstack-parse/raw/main/parse-server-mongodb/images/parse-dashboard_web_2.png)

---
### Step 4. Post application data to verify parse-server and parse-dashboard

Now the ```parse-server``` and ```parse-dashboard``` are ready. Let's post some data to simulate the interaction with the ```parse-server```.
Please execute the following commands on ECS and see the response. Remember to replace the ```my_application_id``` with the defined application ID when starting the ```parse-server```.

```
curl -X POST \
-H "X-Parse-Application-Id: my_application_id" \
-H "Content-Type: application/json" \
-d '{"score":100,"playerName":"Sean Plott","cheatMode":false}' \
http://localhost:1337/parse/classes/GameScore

curl -X POST \
-H "X-Parse-Application-Id: my_application_id" \
-H "Content-Type: application/json" \
-d '{"score":120,"playerName":"Sean Plott","cheatMode":false}' \
http://localhost:1337/parse/classes/GameScore

curl -X POST \
-H "X-Parse-Application-Id: my_application_id" \
-H "Content-Type: application/json" \
-d '{"score":999,"playerName":"Julian","cheatMode":true}' \
http://localhost:1337/parse/classes/GameScore

curl -X GET \
  -H "X-Parse-Application-Id: my_application_id" \
  http://localhost:1337/parse/classes/GameScore
```

![image.png](https://github.com/alibabacloud-howto/solution-applicationstack-parse/raw/main/parse-server-mongodb/images/parse_demo.png)

And go to the ```parse-dashboard```, refresh the web page, we can see the posted application data.

![image.png](https://github.com/alibabacloud-howto/solution-applicationstack-parse/raw/main/parse-server-mongodb/images/parse-dashboard_web_3.png)