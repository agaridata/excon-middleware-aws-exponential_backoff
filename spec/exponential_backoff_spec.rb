require "spec_helper"

class Stack
  def error_call(datum); end
  def request_call(datum); end
  def response_call(datum); end
end

RSpec.describe Excon::Middleware::AWS::ExponentialBackoff do
  subject { described_class.new(Stack.new) }

  it { is_expected.to respond_to :error_call }

  it "delays exponentially longer" do
    wait1 = subject.exponential_wait(backoff: {retry_count: 0 })
    wait2 = subject.exponential_wait(backoff: {retry_count: 1 })
    wait3 = subject.exponential_wait(backoff: {retry_count: 2 })
    expect(wait3).to be > wait2
    expect(wait2).to be > wait1
    expect(wait1).to be > 0
  end

  it "always retries if max_retries is 0" do
    expect(subject.should_retry?(backoff: {max_retries: 0})).to be true
  end

  it "retries if retry_count is < max_retries" do
    expect(subject.should_retry?(backoff: {retry_count:0, max_retries: 1})).to be true
    expect(subject.should_retry?(backoff: {retry_count:1, max_retries: 1})).to be false
  end

  it "backs off when throttled" do
    throttled = Excon::Errors.status_error({}, throttling_response)
    redirect = Excon::Errors.status_error({}, Excon::Response.new(status: 302))
    bad_request = Excon::Errors.status_error({}, Excon::Response.new(status: 400))

    expect(subject.throttle?(error: throttled)).to be true
    expect(subject.throttle?(error: redirect)).to be false
    expect(subject.throttle?(error: bad_request)).to be false
  end

  it "backs off when there is a server error" do
    expect(subject.server_error?(error: Excon::Errors.status_error({}, Excon::Response.new(status: 500)))).to be true
    expect(subject.server_error?(error: Excon::Errors.status_error({}, Excon::Response.new(status: 501)))).to be false
    expect(subject.server_error?(error: Excon::Errors.status_error({}, Excon::Response.new(status: 502)))).to be true
    expect(subject.server_error?(error: Excon::Errors.status_error({}, Excon::Response.new(status: 503)))).to be true
    expect(subject.server_error?(error: Excon::Errors.status_error({}, Excon::Response.new(status: 504)))).to be true
  end

  it "should call do_backoff when throttled" do
    throttled = Excon::Errors.status_error({}, throttling_response)
    expect(subject).to receive(:do_backoff)
    subject.error_call(error: throttled)
  end

  it "should call do_handoff when not throttled" do
    bad_request = Excon::Errors.status_error({}, Excon::Response.new(status: 400))
    expect(subject).to receive(:do_handoff)
    subject.error_call(error: bad_request)
  end

  pending "test do_backoff into existance"
  pending "test do_handoff into existance"
end