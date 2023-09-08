import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.functions import *
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


df = spark.read.csv("s3://transaction-bucket-hm/Historic_transaction/historic_trans.csv",header=True,inferSchema=True)
df.repartition(1).write.mode("overwrite").parquet(f"s3://datalake-rawzone-group1dbda-8sep/Transactions/Transactions_historic/{current_date_string}/")

job.commit()
