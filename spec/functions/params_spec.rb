require 'spec_helper'

describe Puppet::Parser::Functions.function(:params) do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  context "when calling params() from puppet" do
    context "with the wrong number of arguments" do
      it "should not compile when no arguments are passed" do
        Puppet[:code] = '$foo = params()'
        expect {
          scope.compiler.compile
        }.to raise_error(Puppet::ParseError, /requires two arguments/)
      end

      it "should not compile when only one argument is passed" do
        Puppet[:code] = '$foo = params($options)'
        expect {
          scope.compiler.compile
        }.to raise_error(Puppet::ParseError, /requires two arguments/)
      end
    end

    context "either parameter is not a hash" do
      it 'should fail if the passed options is not a hash' do
        Puppet[:code] = <<-'EOP'
          $options = 'not a hash'
          $foo = params($options, 'ntp')
        EOP
        expect {
          scope.compiler.compile
        }.to raise_error(Puppet::ParseError, /not a hash/)
      end

      it 'should fail if the lookup defaults is not a hash' do
        Puppet[:code] = <<-'EOP'
          class ntp::params { $defaults = 'not a hash' }
          $options = { foo => 'bar' }
          include ntp::params

          $foo = params($options, 'ntp')
        EOP
        expect {
          scope.compiler.compile
        }.to raise_error(Puppet::ParseError, /not a hash/)
      end
    end

    it 'should fail if default parameters do not exist' do
      Puppet[:code] = <<-'EOP'
        class ntp::params { }
        $options = { foo => 'bar' }
        include ntp::params

        $foo = params($options, 'ntp')
      EOP
      expect {
        scope.compiler.compile
      }.to raise_error(Puppet::ParseError, /do not exist for module/)
    end

    context "merging hashes" do
      it 'should return the same value if options does not differ from defaults' do
        Puppet[:code] = <<-'EOP'
          class ntp::params { $defaults = { package => { foo => 'bar' } } }
          class test(
            $options = $ntp::params::defaults,
          ) inherits ntp::params {
            if params($options, 'ntp') != $ntp::params::defaults {
              fail('params() did not return what is expected')
            }
          }

          include test
        EOP
        scope.compiler.compile
      end

      it 'should include defaults in the event that a partial list is supplied' do
        Puppet[:code] = <<-'EOP'
          class ntp::params { $defaults = { package => { foo => 'bar' }, config => { steve => 'bob' } } }
          class test(
            $options = $ntp::params::defaults,
          ) inherits ntp::params {
            if params($options, 'ntp') != $ntp::params::defaults {
              fail('params() did not return what is expected')
            }
          }

          class { 'test':
            options => { package => { foo => 'bar' } },
          }
        EOP
        scope.compiler.compile
      end

      it 'should override defaults in the event that a partial list is supplied' do
        Puppet[:code] = <<-'EOP'
          class ntp::params { $defaults = { package => { foo => 'bar' }, config => { steve => 'bob' } } }
          class test(
            $options = $ntp::params::defaults,
          ) inherits ntp::params {
            $expected_return = {
              package => { foo => 'foobar' },
              config => { steve => 'bob' },
            }
            if params($options, 'ntp') != $expected_return {
              fail('params() did not return what is expected')
            }
          }

          class { 'test':
            options => { package => { foo => 'foobar' } },
          }
        EOP
        scope.compiler.compile
      end
    end
  end

  context "using non-default hashes" do
    it 'should be able to load a different hash than default' do
      Puppet[:code] = <<-'EOP'
        class ntp::params { $nodefault = { package => { foo => 'bar' }, config => { steve => 'bob' } } }
        class test(
          $options = $ntp::params::nodefault,
        ) inherits ntp::params {
          $expected_return = {
            package => { foo => 'foobar' },
            config => { steve => 'bob' },
          }
          if params($options, 'ntp', 'nodefault') != $expected_return {
            fail('params() did not return what is expected')
          }
        }

        class { 'test':
          options => { package => { foo => 'foobar' } },
        }
      EOP
      scope.compiler.compile
    end
  end
end
