import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from pyspark.sql.functions import col, when, sum as spark_sum

## @params: [JOB_NAME]
args = getResolvedOptions(sys.argv, ['JOB_NAME'])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)


current_date_df = spark.range(1).select(current_date().alias("current_date"))
date_string_df = current_date_df.select(date_format("current_date", "yyyy-MM-dd").alias("date_string"))
current_date_string = date_string_df.first()["date_string"]


jdbc_url = "jdbc:mysql://project-h-and-m-db.ciuejmixu9um.us-east-1.rds.amazonaws.com:3306/project_h_and_m_db" 
connect_prop={
"user":"admin",
"password":"12345678",
}

customers_df = spark.read.format("jdbc").option("url", "jdbc:mysql://project-h-and-m-db.ciuejmixu9um.us-east-1.rds.amazonaws.com:3306/project_h_and_m_db").option("dbtable", "customers").option("user", "admin").option("password", "12345678").load() 

articles_df = spark.read.format("jdbc").option("url", "jdbc:mysql://project-h-and-m-db.ciuejmixu9um.us-east-1.rds.amazonaws.com:3306/project_h_and_m_db").option("dbtable", "articles").option("user", "admin").option("password", "12345678").load() 


customers_df.repartition(1).write.parquet(f"s3://datalake-rawzone-group1dbda-8sep/Customers/Customers_historic/{current_date_string}/")

articles_df.repartition(1).write.parquet(f"s3://datalake-rawzone-group1dbda-8sep/Articles/Articles_historic/{current_date_string}/")


job.commit()