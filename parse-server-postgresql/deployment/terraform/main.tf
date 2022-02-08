provider "alicloud" {
  #   access_key = "${var.access_key}"
  #   secret_key = "${var.secret_key}"
  region = "cn-hongkong"
}

variable "zone_1" {
  default = "cn-hongkong-b"
}

variable "name" {
  default = "parse_group"
}

######## Security group
resource "alicloud_security_group" "group" {
  name        = "sg_parse_app"
  description = "Security group for Parse app"
  vpc_id      = alicloud_vpc.vpc.id
}

resource "alicloud_security_group_rule" "allow_http_1337" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "1337/1337"
  priority          = 1
  security_group_id = alicloud_security_group.group.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_http_3100" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "3100/3100"
  priority          = 1
  security_group_id = alicloud_security_group.group.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_http_4040" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "4040/4040"
  priority          = 1
  security_group_id = alicloud_security_group.group.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_ssh_22" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "22/22"
  priority          = 1
  security_group_id = alicloud_security_group.group.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_rdp_3389" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "3389/3389"
  priority          = 1
  security_group_id = alicloud_security_group.group.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_all_icmp" {
  type              = "ingress"
  ip_protocol       = "icmp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "-1/-1"
  priority          = 1
  security_group_id = alicloud_security_group.group.id
  cidr_ip           = "0.0.0.0/0"
}

######## VPC
resource "alicloud_vpc" "vpc" {
  vpc_name   = var.name
  cidr_block = "192.168.0.0/16"
}

resource "alicloud_vswitch" "vswitch_1" {
  vpc_id       = alicloud_vpc.vpc.id
  cidr_block   = "192.168.0.0/24"
  zone_id      = var.zone_1
  vswitch_name = "vsw_on_zone_1"
}

######## ECS
resource "alicloud_instance" "instance" {
  security_groups = alicloud_security_group.group.*.id

  instance_type           = "ecs.c5.xlarge" # 4core 8GB
  system_disk_category    = "cloud_ssd"
  system_disk_name        = "parse_app_system_disk"
  system_disk_size        = 40
  system_disk_description = "parse_app_system_disk"
  image_id                = "centos_8_4_x64_20G_alibase_20210927.vhd"
  instance_name           = "parse_app"
  password                = "N1cetest" ## Please change accordingly
  instance_charge_type    = "PostPaid"
  vswitch_id              = alicloud_vswitch.vswitch_1.id
}

######## RDS PostgreSQL (Parse Server database)
resource "alicloud_db_instance" "parse_server_db" {
  engine           = "PostgreSQL"
  engine_version   = "13.0"
  instance_type    = "pg.n4.medium.1"
  instance_storage = "20"
  vswitch_id       = alicloud_vswitch.vswitch_1.id
  instance_name    = "parse_server_database"
  security_ips     = [alicloud_vswitch.vswitch_1.cidr_block]
}

resource "alicloud_db_database" "parse_server_db" {
  instance_id = alicloud_db_instance.parse_server_db.id
  name        = "parse_server_db"
}

resource "alicloud_rds_account" "parse_server_db_account" {
  db_instance_id   = alicloud_db_instance.parse_server_db.id
  account_name     = "parse"
  account_password = "N1cetest"
  account_type     = "Super"
}

resource "alicloud_db_account_privilege" "parse_server_db_privilege" {
  instance_id  = alicloud_db_instance.parse_server_db.id
  account_name = alicloud_rds_account.parse_server_db_account.name
  privilege    = "DBOwner"
  db_names     = alicloud_db_database.parse_server_db.*.name
}

######## EIP bind to setup ECS accessing from internet
resource "alicloud_eip" "setup_ecs_access" {
  bandwidth            = "5"
  internet_charge_type = "PayByBandwidth"
}

resource "alicloud_eip_association" "eip_ecs" {
  allocation_id = alicloud_eip.setup_ecs_access.id
  instance_id   = alicloud_instance.instance.id
}

resource "null_resource" "setup_ecs" {
  ## Provision to install Node.js
  provisioner "remote-exec" {
    inline = [
      "wget https://npm.taobao.org/mirrors/node/v12.0.0/node-v12.0.0-linux-x64.tar.xz",
      "tar -xvf node-v12.0.0-linux-x64.tar.xz",
      "rm node-v12.0.0-linux-x64.tar.xz  -f",
      "mv node-v12.0.0-linux-x64/ node",
      "ln -s ~/node/bin/node /usr/local/bin/node",
      "ln -s ~/node/bin/npm /usr/local/bin/npm"
    ]

    connection {
      type     = "ssh"
      user     = "root"
      password = alicloud_instance.instance.password
      host     = alicloud_eip.setup_ecs_access.ip_address
    }
  }
}

######### Output: EIP of ECS
output "eip_ecs" {
  value = alicloud_eip.setup_ecs_access.ip_address
}

######### Output: RDS PostgreSQL (Parse Server database) Connection String
output "rds_pg_url_parse_server_database" {
  value = alicloud_db_instance.parse_server_db.connection_string
}

######### Output: RDS PostgreSQL (Parse Server database) Connection Port
output "rds_pg_port_parse_server_database" {
  value = alicloud_db_instance.parse_server_db.port
}
