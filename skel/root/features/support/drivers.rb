# capybara drivers for fast testing
#
# this one runs your entire test suite
require 'capybara/poltergeist'

# this one runs while you continuously test via guard
require 'persistent_selenium/driver'

# you can override the driver with the DRIVER environment variable
ENV['DRIVER'] ||= 'persistent_selenium'

