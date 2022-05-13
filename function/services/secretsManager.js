import { SecretsManagerClient, GetSecretValueCommand } from '@aws-sdk/client-secrets-manager'

const { AWS_REGION } = process.env

const secretsManager = new SecretsManagerClient({ region: AWS_REGION })

export async function getSecret(SecretId) {
    const getSecretValueCommand = new GetSecretValueCommand({ SecretId })
    const { SecretString } = await secretsManager.send(getSecretValueCommand)
    return SecretString
}
