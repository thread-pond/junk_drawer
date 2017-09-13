# JunkDrawer

`JunkDrawer` is a gem providing a handful of random utility that are commonly
useful across projects.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'junk_drawer'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install junk_drawer

If you want to include the Rails utilities, in your Gemfile you can instead use:

```ruby
gem 'junk_drawer', require: 'junk_drawer/rails'
```

### Contents

- [JunkDrawer::Callable](#junkdrawercallable)
- [JunkDrawer::Notifier](#junkdrawernotifier)
- [JunkDrawer::BulkUpdatable](#junkdrawerbulkupdatable)

## Usage

### JunkDrawer::Callable

`JunkDrawer::Callable` is a module that provides constraints and conveniences
for objects that implement a single method `#call`. It comes with the
philosophy that objects that *do* something, should do only one thing. When
including the `JunkDrawer::Callable` in one of your classes, you will get the
following:

1) It raises an error if you try to implement a public method other than
  `#call`.

  ```ruby
  class Foo
    include JunkDrawer::Callable
    def bar # Bad: can't define public method "#bar"
    end
  end
  ```

  produces:

  ```
  JunkDrawer::CallableError: invalid method name bar, only public method allowed is "call"
  ```

  Private methods are fine:

  ```ruby
  class Foo
    include JunkDrawer::Callable
  private
    def bar # private methods are okay!
    end
  end
  ```

2) It delegates `call` on the class to a new instance:

  ```ruby
  class Foo
    include JunkDrawer::Callable
    def call(stuff)
      puts "I am a Foo! I've got #{stuff}"
    end
  end
  ```

  ```
  > Foo.call('a brochure')
  I am a Foo! I've got a brochure
  > Foo.new.call('a brochure')
  I am a Foo! I've got a brochure
  ```

3) It implements `to_proc`, both on the class and instance, allowing operations
  such as:

  ```
  > ['puppies', 'a cold', 'cheeseburgers'].each(&Foo)
  I am a Foo! I've got puppies
  I am a Foo! I've got a cold
  I am a Foo! I've got cheeseburgers
  ```

  See here for a great explanation of `to_proc` and the `&` operator:

  http://www.brianstorti.com/understanding-ruby-idiom-map-with-symbol/

-------------------------------------------------------------------------------

### JunkDrawer::Notifier

`JunkDrawer::Notifier` is a class that provides simple notification strategies
for different environments. When you call it, it will send a notification via
your selected strategy. The strategies available are as follows:

1) `:raise` raises an error when you call the notifier:

  ```ruby
  JunkDrawer::Notifier.strategy = :raise
  JunkDrawer::Notifier.call('some message', some: 'context')
  ```

  produces:

  ```
  JunkDrawer::NotifierError: some message, context: {:some=>"context"}
  ```

2) `:honeybadger` will send a notification to Honeybadger. You'll need to make
  sure you have Honeybadger required in your application and configured for
  this to work.

3) `:null` is a noop. If you want to disable notifications temporarily, you can
  configure the strategy to `:null`.

If you're using Rails, you may want to configure `Notifier` based on the
environment, so in your `config/environments/development.rb` you might have:

```ruby
config.after_initialize do
  JunkDrawer::Notifier.strategy = :raise
end
```

While in `production.rb` you might want:

```ruby
config.after_initialize do
  JunkDrawer::Notifier.strategy = :honeybadger
end
```

-------------------------------------------------------------------------------

## Rails

For Rails specific tools, instead of requiring `'junk_drawer'`, you can require
`'junk_drawer/rails'`. This will pull in both the plain Ruby and the Rails
specific utilities.

### JunkDrawer::BulkUpdatable

`JunkDrawer::BulkUpdatable` is a utility to enable bulk updating of
`ActiveRecord` models.  To enable it, extend in your models:

```ruby
class MyModel < ApplicationRecord
  extend JunkDrawer::BulkUpdatable
end
```

If you want to enable it for all models, you can also add it to your
`ApplicationModel` class:

```ruby
class ApplicationRecord
  self.abstract_class = true
  extend JunkDrawer::BulkUpdatable
end
```

To make use of it, you can pass an array of records into the `.bulk_update`
class method on your model:

```ruby
my_model_1 = MyModel.find(1)
my_model_1.name = 'Jabba'
my_model_2 = MyModel.find(2)
my_model_2.name = 'JarJar'

MyModel.bulk_update([my_model_1, my_model_2])
```

This will generate a single SQL query to update both of the records in the
database.

#### Caveats

- Right now this only supports PostgreSQL. PR's welcome!
- It also only supports basic data types (including `hstore` and `jsonb`) for
  your columns, so if you've got something weird you may have a bad time. Also
  PR's welcome!
- General advice: if you're updating many thousands of records at the same
  time, you may still run into some performance bottlenecks. When you're
  dealing with massive amounts of data, we suggest pairing
  `JunkDrawer::BulkUpdatable` with Rails' built-in `find_in_batches`:

  ```ruby
  MyModel.find_in_batches(batch_size: 250) do |batch|
    batch.each { |my_model| my_model.name = 'Jar' * rand(100) }
    MyModel.bulk_update(batch)
  end
  ```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake spec` to run the tests, or `bin/test` to run tests for all supported
ActiveRecord versions. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/thread-pond/junk_drawer. This project is intended to be a
safe, welcoming space for collaboration, and contributors are expected to
adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
