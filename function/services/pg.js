import * as pg from 'pg'
import { getSecret } from './secretsManager.js'

const { Pool } = pg.default

const {
    DB_HOST,
    DB_PORT,
    DB_USER,
    DB_PASSWORD_SECRET_NAME,
} = process.env

const password = await getSecret(DB_PASSWORD_SECRET_NAME)

const pool = new Pool({
    host: DB_HOST,
    port: DB_PORT,
    user: DB_USER,
    database: 'postgres',
    password,
    idleTimeoutMillis: 300000,
    connectionTimeoutMillis: 2000,
})

export async function execQuery(query) {
    const client = await pool.connect()

    let response
    try {
        await client.query('BEGIN')
        try {
            response = await client.query(query)
            await client.query('COMMIT')
        } catch (err) {
            await client.query('ROLLBACK')
            throw err
        }
    } finally {
        client.release()
    }
    return response
}
