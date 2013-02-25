# Bintz's integration testing setup

_I'm writing this for my coworkers but putting it here in GitHub, because heck, why not? All of the
related projects are already here. Here's how I use them. YMMV. Do what you want, I don't care._

So for most purposes I only do integration testing using Cucumber and Capybara
now. I used to unit test very very heavily. I don't anymore. The reasons for this are:

* Integration testing focuses on the most important part of the application -
  how the end user interacts with it. If it doesn't work the way
  the user expects it to, no amount of code coverage or component testing will
  help it.
* My years of unit testing every possible thing in an application have honed my
  code smell detection abilities pretty well, so I tend to
  write smaller methods anyway, breaking code out to new classes when necessary.
* I made the feedback loop for integration testing with Cucumber and Capybara a
  *lot* smaller. Much of the process is automated and optimized for
  speed, at the cost of the occasional bit of code duplication in tests.
* A lot of the things that Rails wants you to test are silly. Did an instance
  variable get set in a controller action? Can a url get routed to a particular
  controller action? For routes testing, unless it's a complex route, it's usually just
  simpler to load the url in a browser and make sure you get what you want to
  get. For other things, a single integration test will catch everything that
  the other little isolated tests will catch, and will probably require a lot
  less code.

I still advocate full automated testing for applications, run as often as possible (for me,
before every commit). I just save unit
testing for individual pieces of the app where there are a ton of possible
inputs (like some sort of filter mechanism), and I try to get 90% or more of what
the app is going to do in user's hands written into Cucumber features,
saving that last ~10% to be caught during actual user testing and when the app is
in the wild.

The goal should be to replace as much of the development environment tweak-reload cycle that pretty
much all apps will have with something that is just as fast and infinitely repeatable.

## Silly code metrics!

I'm not a huge fan of code metrics-as-gospel, but they sure do help when you run them every once in a while to
find dead/untested/complex code. As an example of how much coverage you can get with as few well-designed tests as possible,
and with the discipline to only ever write enough code to get the test to pass, I ran SimpleCov on two apps built using
this method, without doing any cleanup work after this first metrics run:

<table border="1" cellpadding="2">
  <tr><th>Relevant LoC</th><th>Coverage</th><th>Executed Step Count</th><th>Run Time (:poltergeist driver)</th></tr>
  <tr><td>1453</td><td>94.22%</td><td>891</td><td>2m29.286s</td></tr>
  <tr><td>602</td><td>99.0%</td><td>72</td><td>0m20.228s</td></tr>
</table>

Not a lot of work needed to get these apps closer to 100%, just finding and eliminating some dead code and testing
a missed branch or two, probably inserted during moments of lacking discipline when I just hacked on a
project in `development` mode. I'm not perfect. :P

## Setting up your project

To get your project set up fast, this repo is also a gem that provides a binary that puts everything in how
I normally do things:

``` ruby
# Gemfile

gem 'bintz-integration_testing_setup', :git => 'git://github.com/johnbintz/bintz-integration_testing_setup.git'
```

`bundle install`, then run `bundle exec bintz-integration_testing_setup`. It's best to do this on a pristine
project, but it may work on one that already has some stuff in it.

## Gem setup

You'll need several gems to pull this off, some of them custom gems:

### For front-end development

These gems make it very easy for Capybara to target parts of the web page to
interact with.

``` ruby
gem 'semantic_rails_view_helpers', :git => 'git://github.com/johnbintz/semantic_rails_view_helpers.git'
```

### For testing

These gems set up the Cucumber environment and get it ready for super-fast integration testing.

``` ruby
group :cucumber do
  gem 'cucumber'
  gem 'cucumber-rails'
  gem 'cuke-pack', :git => 'git://github.com/johnbintz/cuke-pack.git'
  gem 'foreman'
  gem 'guard'
  gem 'guard-cucumber'
  gem 'rb-fsevent' # => for mac systems
  gem 'persistent_selenium', :git => 'git://github.com/johnbintz/persistent_selenium.git'
  gem 'poltergeist'
  gem 'capybara-rails-log-inspection', :git => 'git://github.com/johnbintz/capybara-rails-log-inspection.git'
  gem 'rspec'
end
```

### If you need to access a remote service in any way

``` ruby
group :cucumber do
  gem 'webmock', '~> 1.8.0', :require => nil
  gem 'vcr', :require => nil
end
```

### What everything does

Some of my custom gems are pretty cowboyed up, but they work for me, so YMMV.

#### `semantic_rails_view_helpers`

[This gem](http://github.com/johnbintz/semantic_rails_view_helpers) provides view helpers and Capybara finders that, when used with a form builder gem like Formtastic, allow for
very fast form & show construction, and makes it easy to write tests to target elements on those views.

#### `cuke-pack`

[This gem](http://github.com/johnbintz/cuke-pack) helps you set up a lot of common Cucumber environment settings, like support for Timecop, FakeFS, and Mocha;
helps with confirming JavaScript dialogs; enables `cucumber-step_writer`; sets up Guard for a work-in-process workflow; provides a one-at-a-time failed test rerun feature.

#### `cucumber-step_writer`

[Exactly what it sounds like](http://github.com/johnbintz/cucumber-step_writer). Writes out your missing Cucumber steps into `features/steps/(given|when|then)` so you don't
have to copy-paste them anymore.

#### `foreman` and `guard`

For testing, starting both Guard and persistent_selenium is made easy with Foreman. During development, if you have any
dependent services like a Delayed Job worker or API tunnel, Foreman makes it a lot easier to work with.

#### `persistent_selenium`

[Keep a Firefox or Chrome window open](http://github.com/johnbintz/persistent_selenium) while you test, and don't close or reset the page after a failed step. Very helpful
in quickly diagnosing problems and fixing them. Occasional DRb errors, but that's on about one of ever 100 runs or so.

#### `poltergeist`

When you're ready to run your whole test suite, use [the Poltergeist driver](http://github.com/jonleighton/poltergeist), which uses
[PhantomJS](http://phantomjs.org) to run the tests in a super-fast (and slightly finicky in a good way) headless browser.

#### `caypbara-rails-log-inspection`

Normally, errors go in your `log/test.log`. [This](http://github.com/johnbintz/capybara-rails-log-inspection) redirects them to `$stderr`, so you can see exceptions in your Guard
output.

### Remote API integration testing

If your app has to connect to an remote API, it's better to use [VCR](https://github.com/vcr/vcr) to record the actual output from the
API, rather than mocking it directly using WebMock. You may need to mock certain things (Varnish BANs are a common one I have to mock up), but
for the most part, use the actual data from the actual API, and if you're developing both in parallel, rebuild those cassettes often.

## The process

For your continuous integration work, you would want to run `bin/wip_cucumber`, to use both Guard and persistent_selenium.

Let's say you want to add a feature to your application where you see a list of users.
A good Cucumber scenario tries to avoid the nuts and bolts of how a scenario should happen,
instead focusing on as high a level as possible, while needing as few steps as possible.

The approach below is brittle, as it depends on precise text and regexp matches:

``` gherkin
Feature: My feature
  Scenario: Do something
    Given the user "my username" exists with the password "123456"
    Given I am on the home page
    When I click "Login"
    And I fill in "Username" with "my username"
    And I fill in "Password" with "123456"
    And I click "Login"
    ...
```

Knowing the particulars of the username and password, and enumerating how a login works, is
probably overkill, unless you're actually testing login, and even then the approach above is still brittle.
Instead, use a approach like this:

``` gherkin
Feature: My feature
  Scenario: Do something
    Given I exist as a user
    Given I am logged in
    Given I am on the home page
    ...
```

This prevents needing brittle "websteps"-style steps, which were deprecated from Cucumber
years ago. These higher level steps can store the necessary user data in instance variables
for use later:

``` ruby
Given /^I exist as a user$/ do
  @username = 'my username'
  @password = '123456'

  # use bang!-style creates to help catch validation errors as you test.
  # your test setup data should be valid anyway
  @user = User.create!(:username => @username, :password => @password)
end

Given /^I am logged in$/ do
  visit '/'

  # use within liberally, and ensure that your pages have enough
  # identifiers to use it effectively! good use of within means
  # you won't need to use xpath searching
  within '#login-form' do
    # find by CSS selector, since text matching is brittle!
    fill_in 'input[name="user[username]"]', :with => @username
    fill_in 'input[name="user[password]"]', :with => @password

    # this comes from semantic_rails_view_helpers
    find_submit.click
  end
end

Given /^I am on the home page$/ do
  visit '/'

  # find all by itself is an easy way to sanity check a page.
  # it will raise an exception if the element does not exist
  # after Capybara.default_timeout
  find('body.home_page')
end
```

A note about steps that call other steps: one could wrap up all those login steps into a meta-step:

``` ruby
Given /^I am logged in$/ do
  step %{the user "my username" exists with the password "123456"}
  step %{I am on the home page}
  step %{I click "Login"}
  step %{I fill in "Username" with "my username"}
  step %{I fill in "Password" with "123456"}
  step %{I click "Login"}
end
```

But this is even more brittle, since now you have to worry about the formatting of steps within not just
feature files, but in step files as well. My experience with these is to avoid them like the plague.
They will bite you later.

Normally, once you build a feature and run it through Cucumber, either manually or using
Guard, you'll get a list of steps to copy-paste to somewhere in `features/steps`. With this setup,
`cucumber-step_writer` will create the step files for you, with one step per appropriately-named file
in `features/steps/(given|when|then)`:

```
features/
  steps/
    given/
      i_exist_as_a_user.rb
      i_am_logged_in.rb
      i_am_on_the_home_page.rb
```

This makes it very easy to find a particular step using your editor's "find by filename" function,
like with Command-T in Textmate, Sublime Text 2, or with the Vim plugin (surprise) Command-T.

Once the steps are written, you can start filling in the steps, one at a time. Here's what would
happen during your typical test run with each possible driver, given my experience:

* `:rack_test`: Tests move super-fast, but inspecing output HTML requires lots of `puts`. If you can write
  all your finders perfectly the first or second time, and have no need for any JavaScript anywhere, `:rack_test` is very fast.
* `:selenium` and members, like `:firefox` or `:chrome`: The startup time of the browser is a pain, and it's nearly
  impossible to inspect the page state on a failed test. I used to use a `pause` command to pause test execution
  after a failure, inserting `pause` into the failing step, to see what was going on. This involved a lot of test re-running
  and wasted time.
* `:poltergeist` and `:capybara_webkit`: Very fast, JavaScript support, but during development, has the same problem
  as `:rack_test`: inspecting HTML requires `puts`. I save these for pre-commit or whole suite tests. `:poltergeist` is a
  little more stable than `:capybara_webkit` in my experience, and requires less (read: no) things to compile when you install a
  new copy of the gem.
* `:sauce`-based browsers: For when you care about Internet Explorer. A necessary evil.
* `:persistent_selenium`: When used with Foreman, keeps the browser open while testing, retaining the page state on
  a failed test so you can see what happened. Suffers from DRb recycled object errors, and can rack up memory while
  you use it, but it's as close to using `development` mode and reloading something in a browser that you can get.

So my new approach is:

* `:persistent_selenium` while you write and refine and fix your tests/code
* `:poltergeist` once you're ready to commit and re-test the entire application

While testing using `:persistent_selenium`, focus on exactly one scenario at a time (maybe two) by tagging that scenario
with the `@wip` tag:

``` gherkin
Feature: My feature
  @wip
  Scenario: Do something
    Given I exist as a user
    Given I am logged in
    Given I am on the home page
    ...
```

This hijacks the original meaning of `@wip` that Cucumber defined, which is "I am working on this feature, but it's OK,
you can commit this to the repository even though it's not done." The new meaning is "I'm working on this and won't
commit any code until it's done." It's in your best interests at that point to keep features small and focused. If it
takes too much time to set up a feature and run it, perhaps the feature is too complex and some refactoring may be
needed. Or maybe it's just a big feature and you have to deal with it.

Once a test fails or is pending, Firefox will still be open, in the state before the failed/pending test. Use the
inspection tools to diagnose the problem or to build the code necessary to go on to the next step. Keep going
until the test is complete. If you get a `DRb recycled object` error, just run the test again.

Once the scenario is complete, go on to the next one. With regards to feature organization, if working with a CRUD
asset, I often have two features: one for without an existing object and one with an existing object:

```
features/
  users.feature
  users/
    with_user.feature
```

I then copy-paste (oh noes) whatever steps necessary to get `users/with_user.feature` working. Honestly, it really
shouldn't be that many, otherwise you're probably doing something wrong, like being too granular in your
steps. Ideally, those step definitions should be written with an eye toward reusability anyway.

Once you're ready to commit code, if you used the `bintz-integration_testing_setup` binary to set up your project,
the default Rake task runs the `cucumber:precommit` task. Ideally, you should always run all your features all the time.
Sometimes, for practical reasons, you may want to turn a few of the slower/unchanging tests off with the `@no-precommit`
tag. Just remember that you turned them off if you're starting to see problems in your app!

When running a standard Cucumber run (using the `default` profile) or a `precommit` run, if you are using the cuke-pack
`in_progress` hook and there are test failures, you'll get an `in_progress.txt` file in your project root. This
file works very much like Cucumber `rerun.txt` style of testing, except instead of running all features at once (`@rerun.txt`'s
normal behavior), it runs them one at a time until each one passes, eliminating the passing one from the list as you go.
Internally, this uses `@rerun.txt` within a now-smart Cucumber profile, but it only passes in one feature at a time. There's
no need to use `@wip` tags for this either. It will run and eliminate passing scenarios until everything in the `in_progress.txt`
list is fixed. This takes over `@wip` tag processing, and will let you use `@wip` tags again once the list is empty or you
delete `in_progress.txt`.

For now, to make this work with Guard, use [my fork's `paths_from_profile` branch](https://github.com/johnbintz/guard-cucumber/tree/paths_from_profile) of `guard-cucumber`. Once this gets some more human
testing, I'll submit it as a pull request against `guard-cucumber`.

## Testing things that Capybara can't test

Sometimes you need to check HTTP headers, or load a file that Poltergeist of a browser will choke on (loading CSS or JS
files directly into Poltergeist is an error, actually). Then you have to drop to Rack::Test directly. Be sure you
have `Capybara.app_host` set correctly and Rack::Test should "just work":

``` ruby
When /^I request the JavaScript file$/ do
  get Capybara.app_host + '/file.js'
end

Then /^the cache header should be correct$/ do
  last_response.headers['Cache-Control'].should include(@max_age.to_s)
end
```

## Random tips

* Some JavaScript widgets, like WYSIWYG editors, are hard to test. Have an option that replaces them with
  their equivalent native widget during testing. This also falls into the "don't test the framework" category:
  the creator of the widget should be ensuring that the widget starts up and works, not you.
* Don't be afraid to break things up using Plain Old Ruby Objects. ActiveRecord isn't the be-all, end-all design
  pattern. If it's getting too big and you're passing a state around various methods, break it out.
* Make new folders in `app` for things. I usually have one for Delayed Job job objects, one for value objects,
  one for behaviors or concerns (in Rails 4 they have dedicated `app/model/concerns` and `app/controller/concerns`,
  but I also have those apply to other objects in the app's world, hence a dedicated directory for `app/behaviors`.
* VCR note: the innermost cassette is the one that gets recorded to when you're nesting.
* Testing using external services, like [Feed Validator](http://feedvalidator.org/): Force the application to start up
  by `visit`ing a safe page that doesn't do anything, or is wrapped by a VCR call. Then build the URL
  to give to the remote service using `Capybara.app_host`, like you would with `Rack::Test`.
* Sometimes Poltergeist and PhantomJS don't click the right element. This is due to the WebKit renderer being
  silly sometimes. If you're having intermittent problems with a `click` on an element, use `dom_click` instead:

  ``` ruby
  find_submit.dom_click
  ```

  This will use a DOM click in drivers that support DOM event firing, and a regular `click` on other browsers (like Selenium).

## Writing less better organized code

Rails gives you a lot of built-in tools to keep you from writing a lot of code. But there are gems out there that
let you get away with writing even less code, which means you have less things to test. You should never "test the
framework" when you write tests -- assume that the author of the tools you use have tested them thoroughly, unless
otherwise discovered (and then help the author by pinpointing the problem and sending code to fix it!) That's
why I'm not a fan of things like model validation tests: the model file clearly says `validates :something`, there's
no need to test that directly, unless you think Rails itself is broken. Indirect testing through integration
testing is fine, though (but probably mostly unnecessary).

For a "typical" Rails application which provides some sort of HTML-based interface to end users, I'll use
most of, of not all of, the following gems:

* [inherited_resources](http://github.com/josevalim/inherited_resources): Rails controller generators are OK, but this
  is way faster. With this, you don't even have to feel guilty about not having controller unit tests that are
  essentially "I have set an instance variable and called the render method".
* [formtastic](http://github.com/justinfrench/formtastic): Writing forms is lame. Formtastic lets you do it a lot
  faster, makes it easier to target your form elements using Capybara and semantic_rails_view_helpers, and
  makes writing custom form elements a snap, even ones that have JavaScript in them.
* [draper](http://github.com/drapergem/draper): Views shouldn't have any more logic than the occasional `if` statement.
  Put the rest of that logic in decorators. Combine that with [decorates_before_rendering](http://github.com/ohwillie/decorates_before_rendering)
  for stupid-simple decorators.
* [Active Admin](http://github.com/gregbell/active_admin): If you don't need to write an admin interface, don't do it.
* [cocoon](http://github.com/nathanvda/cocoon) and [my fork](http://github.com/johnbintz/cocoon): `accepts_nested_attributes_for` get some well-deserved hate, but
  if you truly are only putting nested attributes into an object in a single way, and you're doing it with a gem like cocoon, then it's perfectly acceptable IMHO.
  Write a Form Object to accept the input if you really care that much about that sort of thing.
* [virtus](http://github.com/solnic/virtus): For things like View Objects and Value Objects and Form Objects, make those objects behave like
  ActiveRecord objects. (Read [this article](http://blog.codeclimate.com/blog/2012/10/17/7-ways-to-decompose-fat-activerecord-models/) for some background on that.)

For something that's more of a "service", I'll still use what tools I can, but the test flow may be different.

Of course, you'll have your authentication gems and your asset-related gems and your pagination gems, but those
aren't about writing less code or better organized code.

## Thing will go wrong and my code will fail. Get over it.

I fully expect that I will make mistakes during development, either through incorrect assumptions or just plain shoddy work.
I'm getting better at programming, but I'm not perfect. I use, at the very least, [exception_notification](https://github.com/smartinez87/exception_notification)
to catch problems. If I have access to Errbit or Airbrake or something similar for catching and reporting exceptions, I'll use it. When it breaks,
if my actual code is clean enough, it should be easy to create a new feature, or fix a bad one, and get the problem resolved.

## Changelog

* v0.2.1 (2013-02-18): Note about using external validation services during testing
* v0.2 (2013-02-14): Add `cuke-pack`'s `in_progress` mode.'
* v0.1.2 (2013-01-30): Small update for VCR and finishing a sentence
* v0.1.1 (2013-01-28): Tiny spelling and pucntuation changes
* v0.1 (2013-01-25): Initial brain dump
