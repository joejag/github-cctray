# frozen_string_literal: true

require 'xmlsimple'

# Convert from Github Actions API format (dropping unused fields):
#
# { 'workflow_runs' => [
#   { 'status' => 'completed',
#     'run_number' => 10,
#     'conclusion' => 'success',
#     'created_at' => '2020-03-09T21:03:53Z',
#     'html_url' => 'https://github.com/build-canaries/nevergreen/actions/runs/52530432',
#     'head_branch' => 'main',
#     'repository' => { 'full_name' => 'a_group/a_repo' } }
# ]}
#
# To CCTray format:
#
# <Projects>
#   <Project name="a_group/a_repo (main)" activity="Sleeping" lastBuildLabel="10" lastBuildStatus="Success" lastBuildTime="2020-03-09T21:03:53Z" webUrl="https://github.com/build-canaries/nevergreen/actions/runs/52530432" />
# </Projects>
class GithubToCCTray
  ACTIVITY_MAP = {
    'queued' => 'Building',
    'in_progress' => 'Building',
    'completed' => 'Sleeping'
  }.freeze

  CONCLUSION_MAP = {
    'success' => 'Success',
    'failure' => 'Failure',
    'cancelled' => 'Failure',
    'timed_out' => 'Failure'
  }.freeze

  def convert(github_workflow_runs, branch = nil)
    # We only want to show the status of the most recent run, so drop the older runs
    runs_to_show = []
    runs = github_workflow_runs.fetch('workflow_runs', [])
    runs = runs.select { |a| a['head_branch'] == branch } if branch
    runs_sorted_by_latest = runs.sort { |a, b| b['created_at'] <=> a['created_at'] }
    runs_sorted_by_latest.each do |run|
      unless runs_to_show.any? { |r| r['repository']['full_name'] == run['repository']['full_name'] }
        runs_to_show << run
      end
    end

    # We need to map from GitHub action format to the CCTray XML format
    runs_to_show.map do |workflow_run|
      name = workflow_run['repository']['full_name']
      status = workflow_run['status']
      conclusion = workflow_run['conclusion']
      created_at = workflow_run['created_at']
      run_number = workflow_run['run_number']
      lookup_url = workflow_run['html_url']

      # When conclusion is missing we take the previous runs status
      # This let's know what state we are building from
      # We know: Are we fixing a build or running a new version?
      if conclusion.nil?
        conclusion = previous_conclusion(name, created_at, runs)
      end

      name = "#{name} (#{branch})" if branch

      { name: name,
        activity: ACTIVITY_MAP.fetch(status, 'Unknown'),
        lastBuildLabel: run_number,
        lastBuildStatus: CONCLUSION_MAP.fetch(conclusion, 'Unknown'),
        lastBuildTime: created_at,
        webUrl: lookup_url }
    end
  end

  # From all builds, find the one that ran before with the same name
  def previous_conclusion(project_name, before, runs)
    previous_runs = runs
                    .select { |run| run['repository']['full_name'] == project_name }
                    .select { |run| Time.parse(run['created_at']) < Time.parse(before) }
                    .sort { |a, b| b['created_at'] <=> a['created_at'] }

    previous_runs.fetch(0, { 'conclusion': nil })['conclusion']
  end

  def convert_to_xml(github_workflow_runs, branch = nil)
    XmlSimple.xml_out(convert(github_workflow_runs, branch), {
                        rootname: 'Projects',
                        anonymoustag: 'Project'
                      })
  end
end
