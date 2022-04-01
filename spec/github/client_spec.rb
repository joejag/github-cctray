require "active_support/core_ext/module/delegation"
require "active_support/json"
require_relative "../../lib/github/client"

RSpec.describe GitHub::Client do
  let(:client) { described_class.new(username: username, token: token, cache: cache) }
  let(:username) { "jeff" }
  let(:token) { "meow" }
  let(:cache) { double(:cache, read: cached, write: nil) }
  let(:cached) { nil }

  describe "#runs" do
    subject { client.runs(group: group, repo: repo, workflow: workflow) }
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

    it "attempts to read the runs from the cache" do
      subject
      expect(cache).to have_received(:read).with(uri.to_s)
    end

    context "when the requested runs are in the cache" do
      let(:cached) { { etag: etag, runs: cached_data, until: cache_until }.as_json }
      let(:etag) { "badf00d" }
      let(:cached_data) { template_github_job_status({ "created_at" => "2020-03-09T21:03:53Z" }) }

      context "and the cache is fresh" do
        let(:cache_until) { 5.seconds.from_now.iso8601 }
        it { should_not have_requested(:get, uri) }
        it { should == cached_data }
        it "does not write to the cache" do
          subject
          expect(cache).not_to have_received(:write)
        end
      end

      context "and the cache is stale" do
        let(:cache_until) { 1.second.ago.iso8601 }

        context "and the request returns 304" do
          before { stub_request(:get, uri).to_return(status: 304) }
          it { should have_requested(:get, uri).with(headers: headers.merge("If-None-Match": etag)) }
          it { should == cached_data }

          it "re-writes the cached data to the cache with a new TTL" do
            subject
            expect(cache).to have_received(:write).with(uri.to_s, {
              etag: etag,
              runs: cached_data,
              until: (Time.current + GitHub::Client::CACHE_TTL).iso8601
            })
          end
        end

        context "and the request returns 200" do
          let(:new_etag) { "deadbeef" }
          before do
            stub_request(:get, uri).to_return(
              status: 200,
              body: response_data.to_json,
              headers: { "ETag" => new_etag }
            )
          end
          it { should have_requested(:get, uri).with(headers: headers) }
          it { should == response_data }

          it "writes the result to the cache" do
            subject
            expect(cache).to have_received(:write).with(uri.to_s, {
              etag: new_etag,
              runs: response_data,
              until: (Time.current + GitHub::Client::CACHE_TTL).iso8601
            })
          end
        end
      end
    end

    context "when the requested runs are not in the cache" do
      let(:cached) { nil }
      let(:new_etag) { "deadbeef" }
      before do
        stub_request(:get, uri).to_return(
          status: 200,
          body: response_data.to_json,
          headers: { "ETag" => new_etag }
        )
      end
      it { should have_requested(:get, uri).with(headers: headers) }
      it { should == response_data }

      it "writes the result to the cache" do
        subject
        expect(cache).to have_received(:write).with(uri.to_s, {
          etag: new_etag,
          runs: response_data,
          until: (Time.current + GitHub::Client::CACHE_TTL).iso8601
        })
      end
    end

    context "when the network request fails" do
      before { stub_request(:get, uri).to_return(status: 500) }
      it "raises an error" do
        expect { subject }.to raise_error(Srp::Api::RequestError)
      end
    end
  end
end
