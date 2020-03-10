# frozen_string_literal: true

require 'active_support/core_ext'

# Nevergreen example: https://api.github.com/repos/build-canaries/nevergreen/actions/workflows/nevergreen.yml/runs
# CCTray spec: https://cctray.org/v1/

class GithubToCCTray
  def convert(github_workflow_runs)
    github_workflow_runs.fetch(:workflow_runs, []).map do |run2|
      name = run2[:repository][:full_name]
      { project: { name: name } }
    end
  end
end
