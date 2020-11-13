# frozen_string_literal: true

require_relative "../github_to_cctray"
require "rspec/match_fuzzy"
require "time"

describe GithubToCCTray do
  def template_github_job_status(overrides = {})
    { "workflow_runs" => [
      template_github_job(overrides)
    ] }
  end

  def template_github_job(overrides = {})
    { "status" => "completed",
      "run_number" => 1,
      "conclusion" => "success",
      "created_at" => "2020-03-09T21:03:53Z",
      "html_url" => "https://github.com/build-canaries/nevergreen/actions/runs/52530432",
      "repository" => { "full_name" => "a_group/a_repo" } }.merge(overrides)
  end

  it "should handle empty" do
    expect(subject.convert({})).to eq([])
  end

  it "should handle a single workflow run" do
    expect(subject.convert({
      "workflow_runs" => [
        { "status" => "completed",
          "run_number" => 1,
          "conclusion" => "success",
          "created_at" => "2020-03-09T21:03:53Z",
          "html_url" => "https://github.com/build-canaries/nevergreen/actions/runs/52530432",
          "repository" => { "full_name" => "a_group/a_repo" } }
      ]
    })).to eq([{
      name: "a_group/a_repo",
      lastBuildStatus: "Success",
      lastBuildLabel: 1,
      lastBuildTime: "2020-03-09T21:03:53Z",
      activity: "Sleeping",
      webUrl: "https://github.com/build-canaries/nevergreen/actions/runs/52530432"
    }])
  end

  it "handles all the workflow statues" do
    expect(subject.convert(template_github_job_status({ "status" => "queued" }))[0]).to include(activity: "Building")
    expect(subject.convert(template_github_job_status({ "status" => "in_progress" }))[0]).to include(activity: "Building")
    expect(subject.convert(template_github_job_status({ "status" => "completed" }))[0]).to include(activity: "Sleeping")
  end

  it "handles all the workflow conclusions" do
    expect(subject.convert(template_github_job_status({ "conclusion" => "success" }))[0]).to include(lastBuildStatus: "Success")
    expect(subject.convert(template_github_job_status({ "conclusion" => "failure" }))[0]).to include(lastBuildStatus: "Failure")
    expect(subject.convert(template_github_job_status({ "conclusion" => "cancelled" }))[0]).to include(lastBuildStatus: "Failure")
    expect(subject.convert(template_github_job_status({ "conclusion" => "timed_out" }))[0]).to include(lastBuildStatus: "Failure")
    expect(subject.convert(template_github_job_status({ "conclusion" => "neutral" }))[0]).to include(lastBuildStatus: "Unknown")
    expect(subject.convert(template_github_job_status({ "conclusion" => "action_required" }))[0]).to include(lastBuildStatus: "Unknown")
  end

  it "uses previous status for inflight jobs" do
    jobs = { "workflow_runs" => [
      { "status" => "in_progress",
        "run_number" => 3,
        "conclusion" => nil,
        "created_at" => Time.new(2020, 1, 1).utc.iso8601,
        "html_url" => "some_url",
        "repository" => { "full_name" => "OUR_PROJECT" } },
      { "status" => "completed",
        "run_number" => 2,
        "conclusion" => "success",
        "created_at" => Time.new(2019, 1, 1).utc.iso8601,
        "html_url" => "some_url",
        "repository" => { "full_name" => "IRRELEVANT_PROJECT" } },
      { "status" => "completed",
        "run_number" => 1,
        "conclusion" => "failure",
        "created_at" => Time.new(2018, 1, 1).utc.iso8601,
        "html_url" => "some_url",
        "repository" => { "full_name" => "OUR_PROJECT" } },
      { "status" => "completed",
        "run_number" => 0,
        "conclusion" => "success",
        "created_at" => Time.new(2017, 1, 1).utc.iso8601,
        "html_url" => "some_url",
        "repository" => { "full_name" => "OUR_PROJECT" } }
    ] }

    expect(subject.convert(jobs)[0]).to include(lastBuildStatus: "Failure")
  end

  it "only shows the most recent run of a job" do
    jobs = { "workflow_runs" => [
      template_github_job({
        "created_at" => Time.new(2020, 1, 1).utc.iso8601,
        "repository" => { "full_name" => "OUR_PROJECT" }
      }),
      template_github_job({
        "created_at" => Time.new(2019, 1, 1).utc.iso8601,
        "repository" => { "full_name" => "OUR_PROJECT" }
      })

    ] }

    expect(subject.convert(jobs).size).to eq(1)
    expect(subject.convert(jobs)[0]).to include(lastBuildTime: Time.new(2020, 1, 1).utc.iso8601)
  end

  it "should look alright in XML" do
    expect(subject.convert_to_xml(template_github_job_status)).to match_fuzzy(
      '<Projects>
                <Project name="a_group/a_repo" activity="Sleeping" lastBuildLabel="1" lastBuildStatus="Success" lastBuildTime="2020-03-09T21:03:53Z" webUrl="https://github.com/build-canaries/nevergreen/actions/runs/52530432" />
              </Projects>'
    )
  end
end

