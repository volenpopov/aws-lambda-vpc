import { getObject } from '../services/s3.js'
import { execQuery } from '../services/pg.js'

export const handler = async event => {
    const { s3_object_key } = event

    const { ContentType, LastModified } = await getObject(s3_object_key)

    const queryResult = await execQuery('SELECT NOW()')

    console.log(
        `Successfully downloaded file: ${s3_object_key}. File info: ${JSON.stringify({
            ContentType,
            LastModified,
        })}`
    )

    console.log(
        `Successfully ran query against the database. Query result: ${JSON.stringify(queryResult)}`
    )

    return {
        statusCode: 200,
        body: JSON.stringify('Success'),
    }
}
