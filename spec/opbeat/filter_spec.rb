require File::expand_path('../../spec_helper', __FILE__)
require 'opbeat/filter'

describe Opbeat::Filter do
  it 'should filter http data by default' do
    data = {
      'http' => {
        'data' => {
          'foo' => 'bar',
          'password' => 'hello',
          'the_secret' => 'hello',
          'a_password_here' => 'hello',
          'mypasswd' => 'hello'
        }
      }
    }

    filter = Opbeat::Filter.new
    result = filter.process_event_hash(data)

    vars = result["http"]["data"]
    expect(vars["foo"]).to eq("bar")
    expect(vars["password"]).to eq(Opbeat::Filter::MASK)
    expect(vars["the_secret"]).to eq(Opbeat::Filter::MASK)
    expect(vars["a_password_here"]).to eq(Opbeat::Filter::MASK)
    expect(vars["mypasswd"]).to eq(Opbeat::Filter::MASK)
  end

  it 'should filter http query_string by default' do
    data = {
      'http' => {
        'query_string' => 'foo=bar&password=secret'
      }
    }

    filter = Opbeat::Filter.new
    result = filter.process_event_hash(data)

    expect(result["http"]["query_string"]).to eq('foo=bar&password=' + Opbeat::Filter::MASK)
  end

  it 'should filter http cookies by default' do
    data = {
      'http' => {
        'cookies' => 'foo=bar;password=secret'
      }
    }

    filter = Opbeat::Filter.new
    result = filter.process_event_hash(data)

    expect(result["http"]["cookies"]).to eq('foo=bar;password=' + Opbeat::Filter::MASK)
  end

  it 'should not filter env, extra or headers' do
    data = {
      'http' => {
        'env' => { 'password' => 'hello' },
        'extra' => { 'password' => 'hello' },
        'headers' => { 'password' => 'hello' }
      }
    }

    filter = Opbeat::Filter.new
    result = filter.process_event_hash(data)

    expect(result).to eq(data)
  end

  it 'should be configurable' do
    data = {
      'http' => {
        'data' => {
          'foo' => 'secret',
          'bar' => 'secret',
          '-baz-' => 'secret',
          'password' => 'public',
          'the_secret' => 'public',
          'a_password_here' => 'public',
          'mypasswd' => 'public'
        },
        'query_string' => 'foo=secret&password=public',
        'cookies' => 'foo=secret;password=public'
      }
    }

    filter = Opbeat::Filter.new [:foo, 'bar', /baz/]
    result = filter.process_event_hash(data)

    vars = result["http"]["data"]
    expect(vars["foo"]).to eq(Opbeat::Filter::MASK)
    expect(vars["bar"]).to eq(Opbeat::Filter::MASK)
    expect(vars["-baz-"]).to eq(Opbeat::Filter::MASK)
    expect(vars["password"]).to eq("public")
    expect(vars["the_secret"]).to eq("public")
    expect(vars["a_password_here"]).to eq("public")
    expect(vars["mypasswd"]).to eq("public")
    expect(result["http"]["query_string"]).to eq('foo=' + Opbeat::Filter::MASK + '&password=public')
    expect(result["http"]["cookies"]).to eq('foo=' + Opbeat::Filter::MASK + ';password=public')
  end
end
