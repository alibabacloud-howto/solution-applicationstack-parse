# Deploy Application Stack Parse Server with MongoDB on Alibaba Cloud

You can access the tutorial artifact including deployment script (Terraform), related source code, sample data and instruction guidance from the github project:
[https://github.com/alibabacloud-howto/solution-applicationstack-parse/tree/main/parse-server-mongodb](https://github.com/alibabacloud-howto/solution-applicationstack-parse/tree/main/parse-server-mongodb)

More tutorial around Alibaba Cloud Database, please refer to:
[https://github.com/alibabacloud-howto/database](https://github.com/alibabacloud-howto/database)

---
### Overview

[Parse](https://parseplatform.org/) is the complete application stack for building applications faster with object and file storage, user authentication, push notifications, dashboard and more out of the box. Comparing with [Google Firebase](https://firebase.google.com/), Parse is a bunch of pure open source projects [https://github.com/parse-community](https://github.com/parse-community) for application building and life cycle management.
More readings about [Firebase vs. Parse Server](https://blog.back4app.com/firebase-parse/) by Back4App.

In this solution tutorial, let's see how to install and deploy Parse Server with [MongoDB](https://www.alibabacloud.com/product/apsaradb-for-mongodb) on Alibaba Cloud.

Deployment architecture:

![image.png](https://github.com/alibabacloud-howto/solution-applicationstack-parse/raw/main/parse-server-mongodb/images/archi.png)

---
### Index

- [Step 1. Use Terraform to provision ECS and MongoDB database on Alibaba Cloud]()
- [Step 2. Install and deploy parse-server with ECS and MongoDB]()
- [Step 3. Install parse-dashboard on ECS]()
- [Step 4. Post application data to verify parse-server and parse-dashboard]()
- [Step 5. Install Mongoku on ECS to manage data on MongoDB]()


---
### Step 1. Use Terraform to provision ECS and MongoDB database on Alibaba Cloud

Run the [terraform script](https://github.com/alibabacloud-howto/solution-applicationstack-parse/blob/main/parse-server-mongodb/deployment/terraform/main.tf) to initialize the resources (in this tutorial, we use MongoDB as backend database, so ECS and MongoDB are included in the Terraform script). Please specify the necessary information and region to deploy.

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-airflow/images/tf-parms.png)

After the Terraform script execution finished, the ECS instance information are listed as below.

![image.png](https://github.com/alibabacloud-howto/solution-mongodb-labs/raw/main/interactive-roadmap/images/tf-done.png)

- ``eip_ecs``: The public EIP of the ECS for web app host

For the MongoDB instance information, please go to the Alibaba Cloud MongoDB web console [https://mongodb.console.aliyun.com/](https://mongodb.console.aliyun.com/) to get the connection URI.

![image.png](https://github.com/alibabacloud-howto/solution-mongodb-labs/raw/main/interactive-roadmap/images/mongodb-1.png)

![image.png](https://github.com/alibabacloud-howto/solution-mongodb-labs/raw/main/interactive-roadmap/images/mongodb-2.png)

By default, the username and password are ``root`` and ``N1cetest`` respectively, which are preset in the terraform provision script. If you've already changed it, please update accordingly.

Please replace the string ``****`` with ``N1cetest`` in the connection URI string, such as:
``mongodb://root:N1cetest@dds-xxxx.mongodb.rds.aliyuncs.com:3717,dds-xxxx.mongodb.rds.aliyuncs.com:3717/admin?replicaSet=mgset-55560033``

The MongoDB connection URI will be used later when deploying the web application.

---
### Step 2. Install and deploy parse-server with ECS and MongoDB

Please log on to ECS with ``ECS EIP``. By default, the password is ``N1cetest``, which is preset in the terraform provision script in Step 1. If you've already changed it, please update accordingly.

```bash
ssh root@<ECS_EIP>
```

![image.png](https://github.com/alibabacloud-howto/opensource_with_apsaradb/raw/main/apache-ofbiz/images/ecs-logon.png)

Execute the following commands to install Node.js. Parse Server requires Node 8 or newer. Here we install the Node 12.

```bash
wget https://npm.taobao.org/mirrors/node/v12.0.0/node-v12.0.0-linux-x64.tar.xz
tar -xvf node-v12.0.0-linux-x64.tar.xz
rm node-v12.0.0-linux-x64.tar.xz  -f
mv node-v12.0.0-linux-x64/ node
ln -s ~/node/bin/node  /usr/local/bin/node
ln -s ~/node/bin/npm  /usr/local/bin/npm
```


```
npm install -g parse-server
ln -s ~/node/lib/node_modules/parse-server/bin/parse-server /usr/local/bin/parse-server
```

```
ll /usr/local/bin/
```

parse-server --appId my_application_id --masterKey 12345678 --databaseURI mongodb://root:N1cetest@dds-3ns2b89f85aaa3241.mongodb.rds.aliyuncs.com:3717,dds-3ns2b89f85aaa3242.mongodb.rds.aliyuncs.com:3717/admin?replicaSet=mgset-56564916 &


curl -X POST \
-H "X-Parse-Application-Id: my_application_id" \
-H "Content-Type: application/json" \
-d '{"score":99999,"playerName":"Sean Plott","cheatMode":false}' \
http://localhost:1337/parse/classes/GameScore


curl -X POST \
-H "X-Parse-Application-Id: APPLICATION_ID" \
-H "Content-Type: application/json" \
-d '{"score":120,"playerName":"Sean Plott","cheatMode":false}' \
http://localhost:1337/parse/classes/GameScore


{"objectId":"OIQwuQ5Rso","createdAt":"2021-11-02T09:57:43.170Z"}



curl -X GET \
  -H "X-Parse-Application-Id: APPLICATION_ID" \
  http://localhost:1337/parse/classes/GameScore/OFvYi0iuOf


{"objectId":"OFvYi0iuOf","score":123,"playerName":"Sean Plott","cheatMode":false,"createdAt":"2021-11-02T09:57:43.170Z","updatedAt":"2021-11-02T09:57:43.170Z"}

curl -X GET \
  -H "X-Parse-Application-Id: APPLICATION_ID" \
  http://localhost:1337/parse/classes/GameScore




```
npm install -g parse-dashboard
ln -s ~/node/lib/node_modules/parse-dashboard/bin/parse-dashboard /usr/local/bin/parse-dashboard
```

```
ll /usr/local/bin/
```

cd ~/node/lib/node_modules/parse-dashboard/bin
vim parse-dashboard.json

{
  "apps": [
    {
      "serverURL": "http://8.218.96.250:1337/parse",
      "appId": "my_application_id",
      "masterKey": "12345678",
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

parse-dashboard --dev --config parse-dashboard.json



---
### Step 4. Install Mongoku on ECS to manage data on MongoDB

Execute the following commands to install open source MongoDB Web Admin tool [Mongoku](https://github.com/huggingface/Mongoku) on ECS to manage data on MongoDB.

Usually, we need to run the Node.js app as daemon process. Now, let's install [pm2](https://pm2.io/) to start or manage the lifecycle of the Node.js app.
First, please execute the following commands to install ```pm2```.

```
npm i -g pm2
ln -s ~/node/lib/node_modules/pm2/bin/pm2 /usr/local/bin/pm2
```

```
cd ~
npm install -g mongoku
ln -s ~/node/lib/node_modules/mongoku/dist/cli.js /usr/local/bin/mongoku
mongoku start --pm2
```

![image.png](https://github.com/alibabacloud-howto/solution-mongodb-labs/raw/main/nextjs-mongodb-app/images/start-mongoku.png)

Then let's open ``http://<ECS_EIP>:3100/`` again in web browser to visit the Mongoku Web Admin. Mongoku use ``3100`` port for web app by default. I've already set this in the security group rule within the [Terraform script](https://github.com/alibabacloud-howto/solution-mongodb-labs/blob/main/nextjs-mongodb-app/deployment/terraform/main.tf).

Now we can add the MongoDB connection URI here as the server to navigate and manage the data for this social web app via Mongoku. Please enjoy.

![image.png](https://github.com/alibabacloud-howto/solution-mongodb-labs/raw/main/nextjs-mongodb-app/images/mongoku-1.png)

![image.png](https://github.com/alibabacloud-howto/solution-mongodb-labs/raw/main/nextjs-mongodb-app/images/mongoku-2.png)