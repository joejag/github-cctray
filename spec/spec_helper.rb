require "webmock/rspec"
require "srp/api/spec"
require "rspec/its"

module Helpers
  def template_github_job_status(overrides = {})
    {
      "workflow_runs" => [template_github_job(overrides)]
    }
  end

  def template_github_job(overrides = {})
    {
      "status" => "completed",
      "run_number" => 1,
      "conclusion" => "success",
      "created_at" => "2020-03-09T21:03:53Z",
      "html_url" => "https://github.com/build-canaries/nevergreen/actions/runs/52530432",
      "repository" => { "full_name" => "a_group/a_repo" }
    }.merge(overrides)
  end
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.before { WebMock.disable_net_connect! }
  config.include(Helpers)
end
