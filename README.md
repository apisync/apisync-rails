# apisync-rails

This gem gives you the tools to keep your product models synchronized with
ApiSync.

* **DSL:** built-in DSL for ActiveRecord models that pushes your data
automatically to apisync.io.
* **Sidekiq:** when Sidekiq is present, this gem will push data asynchronously.
Otherwise, it will fallback to pushing data synchronously. We strongly recommend
using Sidekiq so errors are handled automatically for you.

If you're not using Rails with ActiveRecord, please use
[apisync-ruby](https://github.com/apisync/apisync-ruby) instead.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'apisync-rails'
```

And then execute:

    $ bundle

## Usage

**Step 1: API Key:** in `config/initializers/apisync.rb`, define your
key:

```ruby
Apisync.api_key = ENV["APISYNC_API_KEY"];
```

**Step 2: setup your models:** you need to define which attributes in your
product models map to the attributes in ApiSync.

Some attributes are required. See
the [API reference](https://docs.apisync.io/api/) for details.

```ruby
class Product < ActiveRecord::Base
  apisync do
    # should the current item be synchronized?
    # remove it to always sync all items
    sync_if :should_sync?

    # Required attributes
    attribute :ad_template_type, from: :category
    attribute :available,        from: :active?
    attribute :content_language, value: "pt-br"

    # Recommended attributes
    attribute :brand,        from: :manufacturer
    attribute :condition,    from: :normalize_condition
    attribute :description
    attribute :images
    attribute :link
    attribute :model
    attribute :price
    attribute :reference_id, from: :id # optional, defaults to :id
    attribute :title
    attribute :year

    # Custom attributes
    custom_attribute :city, identifier: 'city-name',  label: 'City name'
  end

  private

  def should_sync?
    true
  end

  # required format (see reference docs)
  def images
    [{
      url: "https://page.com/image1.jpg",
      order: 1
    }, {
      url: "https://page.com/image2.jpg",
      order: 2
    }]
  end

  # required format (see reference docs)
  def price
    {
      amount: 1234, # equivalent to R$12,34
      currency: "BRL"
    }
  end

  # Custom attribute
  def city
    self.address.city
  end
end
```

**Step 3: test on the console:** on the Rails console, try saving the model.
The request and response should show up.

You can turn off these logs, use `Apisync.verbose = false`.

**Explanation**

**sync_if** defines if the item should be synchronized. The method with the
name of the symbol will be called. When `true`, the item will be saved on
ApiSync. Remove this if you always want to push to ApiSync (recommended).

**attribute** specifies one value to be sent to ApiSync. Pass the
attribute name as parameter, e.g `attribute :brand`.

**from** specifies what method has the values for the
respective attribute. If you leave it blank then we'll default to the attribute
name, e.g `attribute :brand` will call `def brand` whereas `attribute :brand, from:
:manufacturer` will call `def manufacturer`.

**value** specifies a value for the respective attribute. Ideal for values that
don't change.

**custom_attribute** allows you to specify an attribute that is not part
of the documentation. You can use these to create richer ad templates.

### Reference ID

The **reference_id** attribute is extremely important. We use the attribute to
keep track of the record's state. The first time a record is sent, ApiSync
creates it and saves the reference id. The second time a record is sent it
knows that it only needs to be updated, not created.
If you omit `reference_id`, we will keep creating the same record
over and over.

By default, `reference_id` is set to whatever **id** value is. You can
customize it, e.g `attribute :reference_id, from: :my_custom_id`.

### Failed requests

A `warning` will be logged (`Rails.logger.warn`) whenever a request fails.

In asynchronous cases (e.g Sidekiq), an exception will be raised
(`Apisync::RequestFailed`) so jobs can be retried.

### Note on callbacks

This gem uses Rails' callbacks to trigger synchronization.
If you're bypassing methods like `after_commit`,
no data will be sent to ApiSync. For example, `update_attribute` doesn't
perform validations checks, so please use `update_attributes` instead.

### TooManyRequests

When too many simultaneous requests are being made, a 429 status code will be
returned from the server to indicate to the client to slow down.

When using Sidekiq, this lib's algorithm will automatically throttle (slow down)
the requests. When not using any queue gem, `Apisync::TooManyRequests` exception
will be raised and you will have to catch it, therefore
**we strongly recommend using Sidekiq**.

Without Sidekiq, an ActiveRecord's `after_commit` callback is used so the exception
shouldn't prevent your record from being saved to the database, but you have
to rescue it manually.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/apisync/apisync-rails.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
