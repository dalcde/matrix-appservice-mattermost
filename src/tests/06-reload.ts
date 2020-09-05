import { startBridge, test, main } from './utils/Bridge';
import { config } from '../Config';
import log from '../Logging';

test('Start bridge', async t => {
    await startBridge();
    t.end();
});

test('reload log level', async t => {
    // A shallow copy is fine because we are editing a top level property.
    const newConfig = Object.assign({}, config());
    newConfig.logging = 'silent';
    await main().updateConfig(newConfig);

    t.equal(log.getLevel(), log.levels.SILENT);

    newConfig.logging = 'debug';
    await main().updateConfig(newConfig);

    t.end();
});

test('fail when changin non-reloadable config', async t => {
    // A shallow copy is fine because we are editing a top level property.
    const newConfig = Object.assign({}, config());
    const oldConfig = config();

    newConfig.mattermost_url = 'http://new.url';
    await main()
        .updateConfig(newConfig)
        .then(
            () => t.fail('Hot reloaded when non-reloadable key changed'),
            e =>
                t.equals(
                    e.message,
                    'Cannot hot reload config mattermost_url',
                    'Error when hot reloading config with non-reloadable key changed',
                ),
        );

    t.equals(config(), oldConfig, 'Changed config on failed hot reload');
    t.end();
});

test('Kill bridge', async t => {
    await main().killBridge(0);
    t.end();
});
