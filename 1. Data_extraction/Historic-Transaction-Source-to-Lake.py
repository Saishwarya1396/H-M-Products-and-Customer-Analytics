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
#shubham G's bucket
df = spark.read.csv("s3://transaction-bucket-hm/Historic_transaction/historic_trans.csv",header=True,inferSchema=True)
#own bucket
df.repartition(1).write.mode("overwrite").parquet("s3://data-lake-h-m-as-5/Transactions/Transactions_historic/")

job.commit()