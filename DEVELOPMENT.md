# Testing

This repository has both unit and integration tests, using [tape](https://github.com/substack/tape) for both of them. It also uses [Prettier](https://prettier.io) to enforce code style and [ESLint](https://eslint.org) for linting.

## Linting

Running

```
$ npm run lint
```

checks the code with `prettier` and `eslint`. We do not permit any ESLint warnings.

To fix errors, we can use Prettier to autoformat the code via

```
$ npm run fmt.
```

One can also run ESLint's autofix with

```
$ npm run fix
```

which will correct some but not all of the eslint warnings.

## Unit tests

Unit tests are placed next to the source files, e.g. the unit tests for `src/utils/Functions.ts` are at `src/utils/Functions.test.ts`. These are run by the subcommand

```
$ npm run test
```

While attempts have been made to make the code more modular, hence more unit-testable, most of the code is not really amenable to unit testing. Instead, most of it is covered under integration tests.

## Integration tests

We use Docker to set up real instances of Mattermost and Synapse for integration tests, with the bridge running on the host so that we can modify the bridge to test different configurations. The tests are present in `src/tests`, while the Docker configuration is in `docker/`.

Integration tests are run with

```
$ npm run integration
```

which automatically fires up Docker instances for the test, and tears it down at the end of the test. This uses `docker-compose`, and runs `docker-compose` without `sudo` --- one can either use rootless Docker or add the user to the `docker` group. Alternatively one can start the docker instances by hand by setting the `INTEGRATION_MANUAL_DOCKER` environment variable to `true`:

```
$ docker-compose -f docker/docker-compose.yaml up
$ INTEGRATION_MANUAL_DOCKER=true npm run integration
$ docker-compose -f docker/docker-compose.yaml down -v
```

The rest of this section documents the containers used. They all run on the `alpine:3.12` base.

### appservice

This container allows synapse to access the appservice running on the host, since Docker generally doesn't like containers accessing the host. This container only runs an openssh server, which the bridge for reverse port forwarding.

### postgres

This is a standard postgres image pulled from DockerHub. It has two database, one for mattermost and one for synapse, with the mattermost one being the "default" one.

The tables are prepopulated with hardcoded values extracted from live instances. This makes it faster to start up and more convenient to write tests with known ids.

### synapse

This installs synapse from the alpine repositories. It uses `nc` to wait until `postgres` is up before starting synapse, since synapse crashes if the database is inaccessible.

### mattermost

This performs a standard Mattermost 5.26.0 install on alpine, removing the `client` and `prepackaged_plugins` directories for very significant image size reductions. The server complains a bit about the missing `client` directory but still manages to run the tests. The config file is changed minimally from the default one.

This again uses `nc` to wait until `postgres` is up. While Mattermost has built in support for retrying connecting to the database, it waits for 10 seconds between retries, which is generally too much.
