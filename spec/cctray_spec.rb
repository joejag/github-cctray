require_relative "../lib/cctray"
require "rspec/match_fuzzy"
require "time"

describe CCTray do
  let(:cctray) { described_class.new(github_client: github_client) }
  let(:github_client) { double(:github, runs: github_runs) }
  let(:github_runs) { {} }

  describe "#status" do
    subject { cctray.status(group: group, repo: repo, workflow: workflow, **kwargs) }
    let(:group) { "wibble" }
    let(:repo) { "good-stuff" }
    let(:workflow) { "ci.yml" }
    let(:kwargs) { {} }

    it "fetches GitHub runs for the given group/repo/workflow" do
      subject
      expect(github_client).to have_received(:runs).with(group: group, repo: repo, workflow: workflow)
    end

    context "when github returns nothing" do
      let(:githhub_runs) { {} }
      it { should == [] }
    end

    context "when github returns a single run" do
      let(:github_runs) do
        {
          "workflow_runs" => [{
            "status" => "completed",
            "run_number" => 1,
            "conclusion" => "success",
            "created_at" => "2020-03-09T21:03:53Z",
            "html_url" => "https://github.com/build-canaries/nevergreen/actions/runs/52530432",
            "repository" => { "full_name" => "a_group/a_repo" }
          }]
        }
      end

      it {
        should == [{
          name: "a_group/a_repo",
          lastBuildStatus: "Success",
          lastBuildLabel: 1,
          lastBuildTime: "2020-03-09T21:03:53Z",
          activity: "Sleeping",
          webUrl: "https://github.com/build-canaries/nevergreen/actions/runs/52530432"
        }]
      }
    end

    { queued: "Building", in_progress: "Building", completed: "Sleeping" }.each do |github_status, cctray_status|
      context "with GitHub status #{github_status}" do
        let(:github_runs) { template_github_job_status({ "status" => github_status.to_s }) }
        its(:first) { should include(activity: cctray_status) }
      end
    end

    {
      success: "Success",
      failure: "Failure",
      cancelled: "Failure",
      timed_out: "Failure",
      neutral: "Unknown",
      action_required: "Unknown"
    }.each do |github_conclusion, cctray_status|
      context "with GitHub conclusion #{github_conclusion}" do
        let(:github_runs) { template_github_job_status({ "conclusion" => github_conclusion.to_s }) }
        its(:first) { should include(lastBuildStatus: cctray_status) }
      end
    end

    context "with multiple runs" do
      let(:github_runs) { { "workflow_runs" => [older_run, newer_run] } }
      let(:older_run) do
        template_github_job({
          "conclusion" => "failure",
          "created_at" => "2010-03-09T21:03:53Z"
        })
      end
      let(:newer_run) do
        template_github_job({
          "conclusion" => "success",
          "created_at" => "2020-03-09T21:03:53Z"
        })
      end
      its(:first) { should include(lastBuildStatus: "Success") }
    end

    context "with a run in progress" do
      let(:github_runs) { { "workflow_runs" => workflow_runs } }
      let(:workflow_runs) { [template_github_job({ "status" => "in_progress", "conclusion" => nil })] }

      context "when the previous run succeeded" do
        before do
          workflow_runs << template_github_job({
            "conclusion" => "success",
            "created_at" => "2010-03-09T21:03:53Z"
          })
        end
        its(:size) { should be(1) }
        its(:first) { should include(lastBuildStatus: "Success") }
      end

      context "when the previous run failed" do
        before do
          workflow_runs << template_github_job({
            "conclusion" => "failure",
            "created_at" => "2010-03-09T21:03:53Z"
          })
        end
        its(:first) { should include(lastBuildStatus: "Failure") }
      end

      context "with no previous run" do
        its(:first) { should include(lastBuildStatus: "Unknown") }
      end
    end

    context "with XML format" do
      let(:kwargs) { { xml: true } }
      let(:github_runs) { template_github_job_status }
      it { should match_fuzzy(<<~XML) }
        <Projects>
          <Project name="a_group/a_repo" activity="Sleeping" lastBuildLabel="1" lastBuildStatus="Success" lastBuildTime="2020-03-09T21:03:53Z" webUrl="https://github.com/build-canaries/nevergreen/actions/runs/52530432" />
        </Projects>
      XML
    end
  end
end

