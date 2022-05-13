import { S3Client, GetObjectCommand } from '@aws-sdk/client-s3'

const { BUCKET_NAME, AWS_REGION } = process.env

const s3 = new S3Client({ region: AWS_REGION })

export async function getObject(Key) {
    const getObjectCommand = new GetObjectCommand({ Bucket: BUCKET_NAME, Key })
    const object = await s3.send(getObjectCommand)
    return object
}
