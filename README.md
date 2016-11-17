# TokenUI

Text input components that allows to add 'tokens' rendered as pills.

## Development process

### Tools

Before you start you will need to install these tools:

* [Homebrew](http://brew.sh): `/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`
* [Xcode](https://developer.apple.com/xcode/) and the command-line tools: `xcode-select --install`
* [Carthage](https://github.com/Carthage/Carthage): `brew install carthage`
* [Fastlane](https://fastlane.tools): `gem install fastlane --verbose`
* [SwiftLint](https://github.com/realm/SwiftLint): `brew install swiftlint`

Optionally add this alias to your .zshrc or .bashrc file: `alias fl='bundle exec fastlane'`. It will save typing when running fastlane.

### After you clone for the first time

Run `bin/setup`. This will checkout and build the necessary dependencies.

### To make a change

1. Run `fl test` to make sure the unit tests pass.
2. Create a pull request and get it reviewed.
3. Merge the pull request.
4. Run `fl release` to create a new release tag with one of these options: `type:patch`, `type:minor` or `type:major`.
