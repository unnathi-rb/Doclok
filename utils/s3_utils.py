from dotenv import load_dotenv
import os
import boto3

load_dotenv()

s3 = boto3.client(
    "s3",
    aws_access_key_id=os.getenv("AWS_ACCESS_KEY"),
    aws_secret_access_key=os.getenv("AWS_SECRET_KEY"),
    region_name="ap-south-1"
)
def upload_to_s3(
    file_data,
    filename
):

    s3.put_object(
        Bucket="doclok-store",
        Key=filename,
        Body=file_data
    )

    return True
import boto3
import os
from dotenv import load_dotenv

load_dotenv()

s3 = boto3.client(
    "s3",
    aws_access_key_id=os.getenv("AWS_ACCESS_KEY"),
    aws_secret_access_key=os.getenv("AWS_SECRET_KEY"),
)

BUCKET = "doclok-store"


def download_from_s3(s3_key):
    obj = s3.get_object(
        Bucket=BUCKET,
        Key=s3_key
    )
    return obj["Body"].read()


def delete_from_s3(s3_key):
    s3.delete_object(
        Bucket=BUCKET,
        Key=s3_key
    )