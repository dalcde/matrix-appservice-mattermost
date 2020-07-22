export default class Mutex {
    queue: (() => void)[];
    locked: boolean;
    constructor() {
        this.queue = [];
        this.locked = false;
    }

    public async lock(): Promise<void> {
        if (this.locked) {
            await new Promise(resolve => this.queue.push(resolve));
            return;
        } else {
            this.locked = true;
            return;
        }
    }

    public unlock() {
        const resolve = this.queue.shift();
        if (resolve === undefined) {
            this.locked = false;
        } else {
            resolve();
        }
    }
}
