import { BaseEntity, Entity, PrimaryColumn, Column } from 'typeorm';

@Entity('posts')
export class Post extends BaseEntity {
    @PrimaryColumn('text')
    eventid!: string;

    @Column('character', { length: '26' })
    postid!: string;

    @Column('boolean')
    primary!: boolean;
}
