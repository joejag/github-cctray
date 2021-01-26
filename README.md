# 🚗 StreetParking

## Environment Variables

### Required
- GitHub
  - `GITHUB_USERNAME`
  - `GITHUB_TOKEN`
    A personal access token for the given GitHub user.  This must have the `repo` permission.

- Redis
  - `REDIS_URL`

### Optional
- Redis Pool
  - `REDIS_POOL_SIZE`
    The number of concurrent connections Redis can provide.  Defaults to 25.
  - `REDIS_POOL_TIMEOUT`
    Timeout, in seconds, the connection pool will wait for a Redis connection. Defaults to 5.

# Github to CCTray example

A demo is available here: https://cryptic-stream-13380.herokuapp.com/build-canaries/nevergreen/nevergreen.yml

This is an example for how to convert from Github Actions to the CCTray format.

Ideally, this would be supported by Github directly, but this could be used as a proxy to convert between the formats.

Github could implement this by using something like `github_to_cctray.rb` being available as a `/cc.xml` url path at:

- https://api.github.com/repos/build-canaries/nevergreen/actions/workflows/nevergreen.yml/runs/cc.xml

It'd be great to also be able to get all the current build status at a higher level like:

- https://api.github.com/repos/build-canaries/cc.xml
- https://api.github.com/repos/build-canaries/nevergreen/cc.xml

This reduces the amount of http calls that are needed to poll for changes.

## How to use

```
bundle install
bundle exec rackup -p 4567 config.ru
open http://localhost:4567
```

To deploy

```
git push heroku master
```

## Links

- CCTray spec: https://cctray.org/v1/
- GitHub actions states doc: https://developer.github.com/v3/checks/runs/
- Nevergreen example: https://api.github.com/repos/build-canaries/nevergreen/actions/workflows/nevergreen.yml/runs
