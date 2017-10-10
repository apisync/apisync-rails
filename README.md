# Apisync::Rails

Keep your product models synchronized with ApiSync.

* **DSL:** built-in DSL for ActiveRecord models that pushes your data
automatically to apisync.io.
* **Sidekiq:** when Sidekiq is present, this gem will push data assynchronously.
Otherwise, it will fallback to pushing data synchronously.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'apisync-rails'
```

And then execute:

    $ bundle

## Usage

1. **Set your API Key:** in `config/initializers/apisync.rb`, define your
key:

```ruby
Apisync.api_key = ENV["APISYNC_API_KEY"];
```

2. **Setup your product model:** you need to define which attributes in your
model map to the attributes in ApiSync.

Some attributes are required, others aren't. See
the [API reference](https://docs.apisync.io/api/) for details.

```ruby
class Product < ActiveRecord
  apisync do
    # required attributes
    attribute :ad_template_type, from: :category
    attribute :available,        from: :active?
    attribute :content_language, value: "pt-br"

    # recommended attributes
    attribute :brand,        from: :manufacturer
    attribute :condition,    from: :normalize_condition
    attribute :description
    attribute :images
    attribute :link
    attribute :model
    attribute :price
    attribute :reference_id, from: id # optional, defaults to :id
    attribute :title
    attribute :year

    # these are other attributes that you can send
    custom_attribute :owner, name: :owner_attr_name
    custom_attribute :city,  name: :city_attr_name
  end

  # this is the required format for :images
  def images
    [{
      uri: "https://page.com/image1.jpg",
      order: 1
    }, {
      uri: "https://page.com/image2.jpg",
      order: 2
    }]
  end

  # this is the required format for :price
  def price
    {
      amount: 1234, # equivalent to R$12,34
      currency: "BRL"
    }
  end

  # these give a human name to the custom attributes, called based on :name
  def owner_attr_name
    "Special owner"
  end

  def city_attr_name
    "Delivery city"
  end
end
```

where **attribute** specifies one value to be sent to ApiSync. Pass the
attribute name as parameter, e.g `attribute :brand`.

**from:** specifies what method has the values for the
respective attribute. If you leave it blank then we'll default to the attribute
name, e.g `attribute :brand` will call `def brand` whereas `attribute :brand, from:
:manufacturer` will call `def manufacturer`.

**value:** specifies a value for the respective attribute. Ideal for values that
don't change.

**custom_attribute** allows you to specify an attribute that is not part
of the documentation. You can use these values to create richer ad templates.

### Reference ID

The **reference_id** attribute is extremely important. We use the attribute to
keep track of records state. The first you send a record, we create it.
Second time you send a record we know that we only need to update it, not
create it. If you omit reference_id, we will keep creating the same record
over and over.

By default, `reference_id` is set to whatever **id** value is. You can set
another field, e.g `attribute :reference_id, from: :my_custom_id`.

### Note

This gem uses Rails' callbacks to trigger synchronization.
If you're bypassing methods like `after_commit`,
no data will be sent to ApiSync. For example, `update_attribute` doesn't
perform validations checks, so please use `update_attributes` instead.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kurko/apisync-rails.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
