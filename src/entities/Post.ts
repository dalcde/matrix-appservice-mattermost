import {
    BaseEntity,
    Entity,
    PrimaryColumn,
    Column,
    getConnection,
} from 'typeorm';

/**
 * An row in Post corresponds to an event/post that exists on both sides of the
 * bridge. There may be posts that only exist on one side of the bridge, e.g.
 * posts sent when the bridge is down, or messages that are only deleted on one
 * side, or messages sent by users the bridge skips. These will not be recorded
 * in the database.
 */
@Entity('posts')
export class Post extends BaseEntity {
    @PrimaryColumn('text')
    public eventid!: string;

    @Column('character', { length: '26' })
    public postid!: string;

    @Column('character', { length: '26' })
    public rootid!: string;

    public static async removeAll(postid: string): Promise<void> {
        await getConnection()
            .createQueryBuilder()
            .delete()
            .from(Post)
            .where('postid = :postid OR rootid = :postid', {
                postid: postid,
            })
            .execute();
    }
}
