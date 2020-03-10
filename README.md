# Github to CCTray example

This is an example for how to convert from Github Actions to the CCTray format.

Ideally, this would be supported by Github directly, but this could be used as a proxy to convert between the formats.

Github could implement this by using something like `github_to_cctray.rb` being available as a `/cc.xml` url path at:

- https://api.github.com/repos/build-canaries/nevergreen/actions/workflows/nevergreen.yml/runs/cc.xml

It'd be great to also be able to get all the current build status at a higher level like:

- https://api.github.com/repos/build-canaries/cc.xml
- https://api.github.com/repos/build-canaries/nevergreen/cc.xml

## How to use

```
bundle install
bundle exec ruby ./server.rb
open http://localhost:4567
```

## Notes for other implementors (Joe: add this to the CCTray spec site)

- lastBuildStatus takes previous conlclusion if currently running
- only return the most recent run in the XML

## Links

- CCTray spec: https://cctray.org/v1/
- GitHub actions states doc: https://developer.github.com/v3/checks/runs/
- Nevergreen example: https://api.github.com/repos/build-canaries/nevergreen/actions/workflows/nevergreen.yml/runs
