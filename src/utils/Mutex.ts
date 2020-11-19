export default class Mutex {
    private queue: (() => void)[];
    private locked: boolean;
    constructor() {
        this.queue = [];
        this.locked = false;
    }

    public async lock(): Promise<void> {
        if (this.locked) {
            await new Promise<void>(resolve => this.queue.push(resolve));
        } else {
            this.locked = true;
        }
    }

    public unlock(): void {
        const resolve = this.queue.shift();
        if (resolve === undefined) {
            this.locked = false;
        } else {
            resolve();
        }
    }
}
