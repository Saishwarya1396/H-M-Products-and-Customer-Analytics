# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.52.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
  }
  required_version = ">= 1.1.0"
}

#----------Bucket---Lake---------------
provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "bucket1" {
  bucket = "data-lake-h-m-as-5" 
  tags = {
    Name = "My bucket"
  }
}

resource "aws_s3_bucket_ownership_controls" "bucket1" {
  bucket = aws_s3_bucket.bucket1.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "bucket1" {
  bucket = aws_s3_bucket.bucket1.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "bucket1" {
  depends_on = [
    aws_s3_bucket_ownership_controls.bucket1,
    aws_s3_bucket_public_access_block.bucket1,
  ]

  bucket = aws_s3_bucket.bucket1.id
  acl    = "public-read"
}

resource "aws_s3_object" "object1_transaction" {
  bucket = aws_s3_bucket.bucket1.id
  key    = "Transactions/"
}

resource "aws_s3_object" "object2_customers" {
  bucket = aws_s3_bucket.bucket1.id
  key    = "Customers/"
}

resource "aws_s3_object" "object3_articles" {
  bucket = aws_s3_bucket.bucket1.id
  key    = "Articles/"
}

#---------------------Redshift-Log-Bucket--------------------

resource "aws_s3_bucket" "bucket2" {
  bucket = "redshift-logs-aishwarya-mylogs" 
  tags = {
    Name = "My bucket RS Logs"
  }
}

resource "aws_s3_bucket_ownership_controls" "bucket2" {
  bucket = aws_s3_bucket.bucket2.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "bucket2" {
  bucket = aws_s3_bucket.bucket2.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "bucket2" {
  depends_on = [
    aws_s3_bucket_ownership_controls.bucket2,
    aws_s3_bucket_public_access_block.bucket2,
  ]

  bucket = aws_s3_bucket.bucket2.id
  acl    = "public-read"
}


#-------------Redshift----Cluster----------------------------


resource "aws_redshift_cluster" "redshiftCluster1" {
  cluster_identifier = "tf-redshift-cluster"
  database_name      = "dev"
  master_username    = "awsuser"
  master_password    = "HM27march99" 
  node_type          = "dc2.large"
  cluster_type       = "single-node"
}

resource "aws_redshift_cluster_iam_roles" "redshiftCluster1" {
  cluster_identifier = aws_redshift_cluster.redshiftCluster1.cluster_identifier
  iam_role_arns      = ["arn:aws:iam::826763130387:role/LabRole"] 
} 

#----------------HIST-CUST-ART-SOURCE-LAKE-------------------------

resource "aws_glue_job" "glue_job1" {
  name = "Cust_Article_source_lake_upd"
  role_arn = "arn:aws:iam::826763130387:role/LabRole" 
  description = "Get Data from Source to Lake" 
  max_retries = "0"
  timeout = 60
  number_of_workers = 2
  worker_type = "Standard"
  command {
    script_location = "s3://handm-project-gluejob/Historic-Customer-Article-Source-to-Lake.py"
    python_version = "3"
  }
  glue_version = "4.0"
}

#------------------HIST-TRANSAC-SOURCE-LAKE-----------------------------

resource "aws_glue_job" "glue_job2" {
  name = "transac_hist_source-lake_upd"
  role_arn = "arn:aws:iam::826763130387:role/LabRole" 
  description = "Get Transaction Data from source to Lake"
  max_retries = "0"
  timeout = 60
  number_of_workers = 2
  worker_type = "Standard"
  command {
    script_location = "s3://handm-project-gluejob/Historic-Transaction-Source-to-Lake.py"
    python_version = "3"
  }
  glue_version = "4.0"
}

#--------------------HIST-LAKE-REDSHIFT---------------------------

resource "aws_glue_job" "glue_job3" {
  name = "Lake-Redshift-hist-upd"
  role_arn = "arn:aws:iam::826763130387:role/LabRole" 
  description = "DataWarehousing for historic Data"
  max_retries = "0"
  timeout = 60
  number_of_workers = 2
  worker_type = "Standard"
  command {
    script_location = "s3://handm-project-gluejob/Historic-data-from-lake-to-redshift.py"
    python_version = "3"
  }
  glue_version = "4.0"
}

#----------------------DATA-INGESTION-OF-LIVE-DATA(RDS)-TO-LAKE-------------------------

resource "aws_glue_job" "glue_job4" {
  name = "Transac_Cust_Art_Live_source_lake"
  role_arn = "arn:aws:iam::826763130387:role/LabRole" 
  description = "Data Ingestion of Live Data"
  max_retries = "0"
  timeout = 60
  number_of_workers = 2
  worker_type = "Standard"
  command {
    script_location = "s3://handm-project-gluejob/Transac-Cust-Article-Live-Source-to-Lake.py"
    python_version = "3"
  }
  glue_version = "4.0"
}

#------------------LIVE-DATA-LAKE-REDSHIFT-----------------------------

resource "aws_glue_job" "glue_job5" {
  name = "Live_data_lake_redshift"
  role_arn = "arn:aws:iam::826763130387:role/LabRole" 
  description = "DataWarehousing for Live Data"
  max_retries = "0"
  timeout = 60
  number_of_workers = 2
  worker_type = "Standard"
  command {
    script_location = "s3://handm-project-gluejob/Live-data-from-lake-to-redshift.py"
    python_version = "3"
  }
  glue_version = "4.0"
}

#---------------------HIST-DATA-PIPELINE-SFN--------------------------


resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "hist-data-lake-redshift"
  role_arn = "arn:aws:iam::826763130387:role/LabRole" 

  definition = <<EOF
{
  "Comment": "A description of my state machine",
  "StartAt": "cust-article-hist-source-lake",
  "States": {
    "cust-article-hist-source-lake": {
      "Type": "Task",
      "Resource": "arn:aws:states:::glue:startJobRun.sync",
      "Parameters": {
        "JobName": "Cust_Article_source_lake_upd"
      },
      "Next": "transaction-hist-source-lake"
    },
    "transaction-hist-source-lake": {
      "Type": "Task",
      "Resource": "arn:aws:states:::glue:startJobRun.sync",
      "Parameters": {
        "JobName": "transac_hist_source-lake_upd"
      },
      "Next": "Lake-Redshift-hist-upd"
    },
    "Lake-Redshift-hist-upd": {
      "Type": "Task",
      "Resource": "arn:aws:states:::glue:startJobRun.sync",
      "Parameters": {
        "JobName": "Lake-Redshift-hist-upd"
      },
      "End": true
    }
  }
}
EOF
}


#--------------------LIVE-DATA-PIPELINE-SFN---------------------------


resource "aws_sfn_state_machine" "sfn_state_machine1" {
  name     = "Live-data-lake-redshift"
  role_arn = "arn:aws:iam::826763130387:role/LabRole" 

  definition = <<EOF
{
  "Comment": "A description of my state machine",
  "StartAt": "Glue StartJobRun",
  "States": {
    "Glue StartJobRun": {
      "Type": "Task",
      "Resource": "arn:aws:states:::glue:startJobRun.sync",
      "Parameters": {
        "JobName": "Transac_Cust_Art_Live_source_lake"
      },
      "Next": "Live-Source-Redshift"
    },
    "Live-Source-Redshift": {
      "Type": "Task",
      "Resource": "arn:aws:states:::glue:startJobRun.sync",
      "Parameters": {
        "JobName": "Live_data_lake_redshift"
      },
      "End": true
    }
  }
}
EOF
}
