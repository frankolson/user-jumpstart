# Rails User Jumpstart

Start off your Rails app with bootstrap, users, administration abilities, and other useful defaults.

_Original inspiration: [https://github.com/excid3/jumpstart](https://github.com/excid3/jumpstart)_

## Requirements
- Ruby 2.5
- Bundler
- Rails 5.2
- Yarn

## Usage

To create a new rails app with this template run the following line into your terminal:
```
rails new my_app -d postgresql -m https://raw.githubusercontent.com/frankolson/user-jumpstart/master/template.rb
```

Then, because the template users the `foreman` gem, you can start your app like so:
```
cd my_app
bundle exec foreman start -f Procfile.dev
```
