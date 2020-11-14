# frozen_string_literal: true

require "active_support/core_ext/module/delegation"
require_relative "../../lib/github/client"

RSpec.describe GitHub::Client do
  let(:client) { described_class.new(username: username, token: token) }
  let(:username) { "jeff" }
  let(:token) { "meow" }

  describe "#status" do
    subject { client.status(group: group, repo: repo, workflow: workflow) }
    let(:group) { "wibble" }
    let(:repo) { "good-stuff" }
    let(:workflow) { "ci.yml" }
    let(:uri) { URI("https://api.github.com/repos/#{group}/#{repo}/actions/workflows/#{workflow}/runs") }
    let(:headers) do
      {
        Accept: "application/json",
        Authorization: "Basic #{Base64.encode64("#{username}:#{token}").strip}"
      }
    end
    let(:response_data) { template_github_job_status }
    before { stub_request(:get, uri).to_return(status: 200, body: response_data.to_json) }

    it { should have_requested(:get, uri).with(headers: headers) }

    context "with no username" do
      let(:username) { nil }
      it "raises an error" do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context "with no token" do
      let(:token) { nil }
      it "raises an error" do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context "when the network request succeeds" do
      it { should == response_data }
    end

    context "when the network request fails" do
      before { stub_request(:get, uri).to_return(status: 500) }
      it "raises an error" do
        expect { subject }.to raise_error(Srp::Api::RequestError)
      end
    end
  end
end

