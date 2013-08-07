Feature: cli/install
  In order to be worth anything
  Puppet librarian needs to install modules properly

  Scenario: Installing a module and its dependencies
    Given a file named "Puppetfile" with:
    """
    forge "http://forge.puppetlabs.com"

    mod 'puppetlabs/apt'
    """
    When I run `librarian-puppet install`
    Then the exit status should be 0
    And the file "modules/apt/Modulefile" should match /name *'puppetlabs-apt'/
    And the file "modules/stdlib/Modulefile" should match /name *'puppetlabs-stdlib'/

  Scenario: Installing an exact version of a module
    Given a file named "Puppetfile" with:
    """
    forge "http://forge.puppetlabs.com"

    mod 'puppetlabs/apt', '0.0.4'
    """
    When I run `librarian-puppet install`
    Then the exit status should be 0
    And the file "modules/apt/Modulefile" should match /name *'puppetlabs-apt'/
    And the file "modules/apt/Modulefile" should match /version *'0\.0\.4'/
    And the file "modules/stdlib/Modulefile" should match /name *'puppetlabs-stdlib'/


  Scenario: Installing a module with invalid versions in the forge
    Given a file named "Puppetfile" with:
    """
    forge "http://forge.puppetlabs.com"

    mod 'puppetlabs/apache', '0.4.0'
    mod 'puppetlabs/postgresql', '2.0.1'
    """
    When I run `librarian-puppet install`
    Then the exit status should be 0
    And the file "modules/apache/Modulefile" should match /name *'puppetlabs-apache'/
    And the file "modules/apache/Modulefile" should match /version *'0\.4\.0'/
    And the file "modules/postgresql/Modulefile" should match /name *'puppetlabs-postgresql'/
    And the file "modules/postgresql/Modulefile" should match /version *'2\.0\.1'/

  Scenario: Installing a module with invalid versions in git
    Given a file named "Puppetfile" with:
    """
    forge "http://forge.puppetlabs.com"

    mod "apache",
      :git => "https://github.com/puppetlabs/puppetlabs-apache.git", :ref => "0.5.0-rc1"
    """
    When I run `librarian-puppet install`
    Then the exit status should be 0
    And the file "modules/apache/Modulefile" should match /name *'puppetlabs-apache'/
    And the file "modules/apache/Modulefile" should match /version *'0\.5\.0-rc1'/

  Scenario: Installing a module with several constraints
    Given a file named "Puppetfile" with:
    """
    forge "http://forge.puppetlabs.com"

    mod 'puppetlabs/apt', '>=1.0.0', '<1.0.1'
    """
    When I run `librarian-puppet install`
    Then the exit status should be 0
    And the file "modules/apt/Modulefile" should match /name *'puppetlabs-apt'/
    And the file "modules/apt/Modulefile" should match /version *'1\.0\.0'/
    And the file "modules/stdlib/Modulefile" should match /name *'puppetlabs-stdlib'/

  Scenario: Switching a module from forge to git
    Given a file named "Puppetfile" with:
    """
    forge "http://forge.puppetlabs.com"

    mod 'puppetlabs/postgresql', '1.0.0'
    """
    When I run `librarian-puppet install`
    Then the exit status should be 0
    And the file "modules/postgresql/Modulefile" should match /name *'puppetlabs-postgresql'/
    And the file "modules/postgresql/Modulefile" should match /version *'1\.0\.0'/
    And the file "modules/stdlib/Modulefile" should match /name *'puppetlabs-stdlib'/
    When I overwrite "Puppetfile" with:
    """
    forge "http://forge.puppetlabs.com"

    mod 'puppetlabs/postgresql',
      :git => 'https://github.com/puppetlabs/puppet-postgresql.git', :ref => '1.0.0'
    """
    And I run `librarian-puppet install`
    Then the exit status should be 0
    And the file "modules/postgresql/Modulefile" should match /name *'puppetlabs-postgresql'/
    And the file "modules/postgresql/Modulefile" should match /version *'1\.0\.0'/
    And the file "modules/stdlib/Modulefile" should match /name *'puppetlabs-stdlib'/

  Scenario: Changing the path
    Given a directory named "puppet"
    And a file named "Puppetfile" with:
    """
    forge "http://forge.puppetlabs.com"

    mod 'puppetlabs/apt'
    """
    When I run `librarian-puppet install --path puppet/modules`
    And I run `librarian-puppet config`
    Then the exit status should be 0
    And the output from "librarian-puppet config" should contain "path: puppet/modules"
    And the file "puppet/modules/apt/Modulefile" should match /name *'puppetlabs-apt'/
    And the file "puppet/modules/stdlib/Modulefile" should match /name *'puppetlabs-stdlib'/

  Scenario: Handle range version numbers
    Given a file named "Puppetfile" with:
    """
    forge "http://forge.puppetlabs.com"

    mod 'puppetlabs/postgresql'
    """
    When I run `librarian-puppet install`
    Then the exit status should be 0
    And the file "modules/postgresql/Modulefile" should match /name *'puppetlabs-postgresql'/

    Given a file named "Puppetfile" with:
    """
    forge "http://forge.puppetlabs.com"

    mod 'puppetlabs/postgresql', :git => 'git://github.com/puppetlabs/puppet-postgresql'
    """
    When I run `librarian-puppet install`
    Then the exit status should be 0
    And the file "modules/postgresql/Modulefile" should match /name *'puppetlabs-postgresql'/


  Scenario: Installing a module with a release candidate
    Given a file named "Puppetfile" with:
    """
    forge "http://forge.puppetlabs.com"

    mod 'puppetlabs/apache', '0.5.0.rc1'
    """
    When I run `librarian-puppet install`
    Then the exit status should be 0
    And the file "Puppetfile.lock" should contain "puppetlabs/apache (0.5.0.rc1)"
    And the file "modules/apache/Modulefile" should match /version *'0.5.0-rc1'/


