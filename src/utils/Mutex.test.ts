import * as test from 'tape';
import Mutex from './Mutex';

test('mutex', async t => {
    t.plan(1);

    const mutex = new Mutex();
    let string = '';
    await mutex.lock();
    setTimeout(() => {
        string += 'a';
        mutex.unlock();
    }, 100);
    await mutex.lock();
    string += 'b';
    mutex.unlock();
    t.equal(string, 'ab');
});
