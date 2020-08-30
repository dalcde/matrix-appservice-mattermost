import { User } from '../../entities/User';
import { Post } from '../../entities/Post';
import { createConnection } from 'typeorm';

const connection = createConnection({
    type: 'sqlite',
    database: ':memory:',
    entities: [User, Post],
    dropSchema: true,
    synchronize: true,
    logging: false,
});

export default connection;
