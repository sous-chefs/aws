# Contributing to Chef Software Cookbooks

We are glad you want to contribute to Chef Software Cookbooks! The first
step is the desire to improve the project.

You can find additional information about
[contributing to cookbooks](https://docs.chef.io/community_contributions.html)
on the Chef Docs site.

## Quick-contribute

* Create an account on [GitHub](http://github.com).
* Create an account on the [Chef Supermarket](https://supermarket.chef.io/).
* [Become a contributor](https://supermarket.chef.io/become-a-contributor) by
signing our Contributor License Agreement (CLA).
* Create a [pull request for your change on
GitHub](https://github.com/opscode-cookbooks/aws/pulls).

We try to regularly review contributions and will get back to you if we have
any suggestions or concerns.

## The Apache License and the CLA/CCLA

Licensing is very important to open source projects, it helps ensure
the software continues to be available under the terms that the author
desired. Chef uses the Apache 2.0 license to strike a balance between
open contribution and allowing you to use the software however you
would like to.

The license tells you what rights you have that are provided by the
copyright holder. It is important that the contributor fully
understands what rights they are licensing and agrees to them.
Sometimes the copyright holder isn't the contributor, most often when
the contributor is doing work for a company.

To make a good faith effort to ensure these criteria are met, Chef
Software Inc requires a Contributor License Agreement (CLA) or a Corporate
Contributor License Agreement (CCLA) for all contributions. This is
without exception due to some matters not being related to copyright
and to avoid having to continually check with our lawyers about small
patches.

It only takes a few minutes to complete a CLA, and you retain the
copyright to your contribution.

You can complete our contributor license agreement (CLA)
[ online at the Chef Supermarket](https://supermarket.chef.io).
If you're contributing on behalf of your employer, have your employer
fill out our
[Corporate Contributor License Agreement
(CCLA)](https://supermarket.chef.io/ccla-signatures/new) instead.

## Ticket Tracker (GitHub Issues)

The [ticket tracker](https://github.com/opscode-cookbooks/aws/issues) is
the most important documentation for the code base. It provides significant
historical information, such as:

* Which release a bug fix is included in
* Discussion regarding the design and merits of features
* Error output to aid in finding similar bugs

Each ticket should aim to fix one bug or add one feature.

## Using git

You can get a quick copy of the repository for this cookbook by
running `git clone
git://github.com/opscode-cookbooks/COOKBOOKNAME.git`.

For collaboration purposes, it is best if you create a GitHub account
and fork the repository to your own account. Once you do this you will
be able to push your changes to your GitHub repository for others to
see and use.

If you have another repository in your GitHub account named the same
as the cookbook, we suggest you suffix the repository with `-cookbook`.

### Branches and Commits

You should submit your patch as a git branch named after the ticket,
such as GH-22. This is called a _topic branch_ and allows users to
associate a branch of code with the ticket.

It is a best practice to have your commit message have a _summary
line_ that includes the ticket number, followed by an empty line and
then a brief description of the commit. This also helps other
contributors understand the purpose of changes to the code.

    [GH-22] - platform_family and style

    * use platform_family for platform checking
    * update notifies syntax to "resource_type[resource_name]" instead of
      resources() lookup
    * GH-692 - delete config files dropped off by packages in conf.d
    * dropped debian 4 support because all other platforms have the same
      values, and it is older than "old stable" debian release

Remember that not all users use Chef in the same way or on the same
operating systems as you, so it is helpful to be clear about your use
case and change so they can understand it even when it doesn't apply
to them.

### GitHub and Pull Requests

All of Chef's open source cookbook projects are available on
GitHub at either
[http://www.github.com/chef-cookbooks](http://www.github.com/chef-cookbooks) or
[http://www.github.com/opscode-cookbooks](http://www.github.com/opscode-cookbooks).

### More information

Additional help with git is available on the [Community
Contributions](https://docs.chef.io/community_contributions.html#use-git)
page on the Chef Docs site.

## Functional and Unit Tests

This cookbook is set up to run tests under
[Test Kitchen](https://github.com/test-kitchen). It
uses minitest-chef to run integration tests after the node has been
converged to verify that the state of the node.

Test kitchen should run completely without exception using the default
[baseboxes provided by Chef](https://github.com/chef/bento).
Because Test Kitchen creates VirtualBox machines and runs through
every configuration in the `.kitchen.yml` file, it may take some time for
these tests to complete.

If your changes are only for a specific recipe, run only its
configuration with Test Kitchen. If you are adding a new recipe, or
other functionality such as a LWRP or definition, please add
appropriate tests and ensure they run with Test Kitchen.

If any don't pass, investigate them before submitting your patch.

Any new feature should have unit tests included with the patch with
good code coverage to help protect it from future changes. Similarly,
patches that fix a bug or regression should have a _regression test_.
Simply put, this is a test that would fail without your patch but
passes with it. The goal is to ensure this bug doesn't regress in the
future. Consider a regular expression that doesn't match a certain
pattern that it should, so you provide a patch and a test to ensure
that the part of the code that uses this regular expression works as
expected. Later another contributor may modify this regular expression
in a way that breaks your use cases. The test you wrote will fail,
signalling to them to research your ticket and use case and accounting
for it.

If you need help writing tests, please ask on the Chef Developer's
mailing list, or the #chef-hacking IRC channel.

## Code Review

Chef Software regularly reviews code contributions and provides suggestions
for improvement in the code itself or the implementation.

## Release Cycle

The versioning for Chef Software Cookbook projects is X.Y.Z.

* X is a major release, which may not be fully compatible with prior
  major releases
* Y is a minor release, which adds both new features and bug fixes
* Z is a patch release, which adds just bug fixes

A released version of a cookbook will end in an even number, e.g.
"1.2.4" or "0.8.0". When development for the next version of the
cookbook begins, the "Z" patch number is incremented to the next odd
number, however the next release of the cookbook may be a major or
minor incrementing version.

Releases of Chef's cookbooks are usually announced on the Chef user
mailing list. Releases of several cookbooks may be batched together
and announced on the [Chef Software Blog](http://www.chef.io/blog).

## Working with the community

These resources will help you learn more about Chef and connect to
other members of the Chef community:

* [chef](http://lists.chef.io/sympa/info/chef) and
  [chef-dev](http://lists.chef.io/sympa/info/chef-dev) mailing
  lists
* #chef and #chef-hacking IRC channels on irc.freenode.net
* [Supermarket site](http://supermarket.chef.io)
* [Chef Docs](http://docs.chef.io)
* Chef Software Chef [product page](http://www.chef.io/chef)


## Cookbook Contribution Do's and Don't's

Please do include tests for your contribution. If you need help, ask
on the
[chef-dev mailing list](http://lists.chef.io/sympa/info/chef-dev)
or the
[#chef-hacking IRC channel](http://community.chef.io/chat/chef-hacking).
Not all platforms that a cookbook supports may be supported by Test
Kitchen. Please provide evidence of testing your contribution if it
isn't trivial so we don't have to duplicate effort in testing. Chef
10.14+ "doc" formatted output is sufficient.

Please do indicate new platform (families) or platform versions in the
commit message, and update the relevant ticket.

If a contribution adds new platforms or platform versions, indicate
such in the body of the commit message(s), and update the relevant
issues. When writing commit messages, it is helpful for others if
you indicate the issue. For example:

    git commit -m '[ISSUE-1041] - Updated pool resource to correctly
    delete.'

Please do use [foodcritic](http://acrmp.github.com/foodcritic) to
lint-check the cookbook. Except FC007, it should pass all correctness
rules. FC007 is okay as long as the dependent cookbooks are *required*
for the default behavior of the cookbook, such as to support an
uncommon platform, secondary recipe, etc.

Please do ensure that your changes do not break or modify behavior for
other platforms supported by the cookbook. For example if your changes
are for Debian, make sure that they do not break on CentOS.

Please do **not** modify the version number in the `metadata.rb`, Chef
will select the appropriate version based on the release cycle
information above.

Please do **not** update the `CHANGELOG.md` for a new version. Not all
changes to a cookbook may be merged and released in the same versions.
Chef Software will update the `CHANGELOG.md` when releasing a new version of
the cookbook.
