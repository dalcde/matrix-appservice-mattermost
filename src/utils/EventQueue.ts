import { EventEmitter } from 'events';
import Main from '../Main';
import log from '../Logging';

/**
 * The purpose of the event queue is to take a stream of events, and run an
 * asynchronous callback sequentially on the events. Specifically, it waits for
 * the previous callback to resolve before running it on the next event.
 */
export default class EventQueue<T> {
    private consuming?: Promise<void>;
    private queue: T[];
    private onEventBound: (data: T) => void;

    constructor(
        private opts: {
            emitter: EventEmitter;
            event: string;
            description: string;
            callback: (data: T) => Promise<void>;
            filter: (data: T) => Promise<boolean>;
            parent: Main;
        },
    ) {
        this.consuming = Promise.resolve();
        this.queue = [];
        this.onEventBound = this.onEvent.bind(this);
        opts.emitter.on(opts.event, this.onEventBound);
        opts.parent.on('initialize', () => {
            this.consuming = this.consume();
        });
    }

    public async kill(): Promise<void> {
        this.opts.emitter.off(this.opts.event, this.onEventBound);
        if (this.consuming) {
            await this.consuming;
        }
    }

    private onEvent(data: T): void {
        this.queue.push(data);
        if (!this.consuming) {
            this.consuming = this.consume();
        }
    }

    private async consume(): Promise<void> {
        // We must avoid the situation where, in fact, no asynchronous
        // operations were performed in the whole function, where it just
        // passes right through. If this happens, this function first sets
        // this.consuming to be undefined, then its return value, which is a
        // resolved Promise, is assigned to this.consuming by the caller. Thus,
        // despite the queue being empty, it is still in the consuming state.
        await new Promise(r => setTimeout(r, 0));
        let data;
        while ((data = this.queue.shift())) {
            log.time.debug(`Process ${this.opts.description} message queue`);
            try {
                if (await this.opts.filter(data)) {
                    log.debug(
                        `Skipping ${
                            this.opts.description
                        } message: ${JSON.stringify(data)}`,
                    );
                } else {
                    await this.opts.callback(data);
                }
            } catch (e) {
                log.error(
                    `Error when processing ${this.opts.description} message \n${e.stack}`,
                );
            }
            log.timeEnd.debug(`Process ${this.opts.description} message queue`);
            this.opts.parent.emit(this.opts.description);
        }
        this.consuming = undefined;
    }
}
