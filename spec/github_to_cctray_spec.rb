require_relative "spec_helper"
require_relative "../github_to_cctray.rb"

describe GithubToCCTray do
  it "should handle empty" do
    expect(subject.convert(
      {}
    )).to eq([])
  end

  it "should handle a single workflow run" do
    expect(subject.convert(
      { workflow_runs: [
        { repository: { full_name: "a_group/a_repo" } },
      ] }
    )).to eq([{ project: { name: "a_group/a_repo" } }])
  end
end
