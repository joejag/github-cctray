require "xmlsimple"

# Convert from Github Actions API format (dropping unused fields):
#
# { 'workflow_runs' => [
#   { 'status' => 'completed',
#     'run_number' => 10,
#     'conclusion' => 'success',
#     'created_at' => '2020-03-09T21:03:53Z',
#     'html_url' => 'https://github.com/build-canaries/nevergreen/actions/runs/52530432',
#     'repository' => { 'full_name' => 'a_group/a_repo' } }
# ]}
#
# To CCTray format:
#
# <Projects>
#   <Project name="a_group/a_repo" activity="Sleeping" lastBuildLabel="10" lastBuildStatus="Success" lastBuildTime="2020-03-09T21:03:53Z" webUrl="https://github.com/build-canaries/nevergreen/actions/runs/52530432" />
# </Projects>
class CCTray
  ACTIVITY_MAP = {
    "queued" => "Building",
    "in_progress" => "Building",
    "completed" => "Sleeping"
  }.freeze

  CONCLUSION_MAP = {
    "success" => "Success",
    "failure" => "Failure",
    "cancelled" => "Failure",
    "timed_out" => "Failure"
  }.freeze

  def initialize(github_client: nil, redis_pool: nil)
    @github_client = github_client ||
      GitHub::Client.new(username: ENV["GITHUB_USERNAME"], token: ENV["GITHUB_TOKEN"], redis_pool: redis_pool)
  end

  def status(group: , repo: , workflow: , xml: false)
    github_runs = github_client.runs(group: group, repo: repo, workflow: workflow)
    runs = github_runs.fetch("workflow_runs", [])
    most_recent_run = runs.max_by { |run| run["created_at"] }

    result = most_recent_run ? [generate_cctray_status_for(most_recent_run, all_runs: runs)] : []
    xml ? render_xml(result) : result
  end

  private

  attr_reader :github_client

  # rubocop:disable Metrics/MethodLength
  def generate_cctray_status_for(run, all_runs: )
    name = run["repository"]["full_name"]
    created_at = run["created_at"]
    conclusion = run["conclusion"] || previous_conclusion(name, created_at, all_runs)

    {
      name: name,
      activity: ACTIVITY_MAP.fetch(run["status"], "Unknown"),
      lastBuildLabel: run["run_number"],
      lastBuildStatus: CONCLUSION_MAP.fetch(conclusion, "Unknown"),
      lastBuildTime: created_at,
      webUrl: run["html_url"]
    }
  end
  # rubocop:enable Metrics/MethodLength

  # From all builds, find the one that ran before with the same name
  def previous_conclusion(project_name, before, all_runs)
    previous_run = all_runs
      .select { |run| run["repository"]["full_name"] == project_name }
      .select { |run| Time.parse(run["created_at"]) < Time.parse(before) }
      .max_by { |run| run["created_at"] }

    previous_run&.fetch("conclusion", nil)
  end

  def render_xml(status)
    XmlSimple.xml_out(status, { rootname: "Projects", anonymoustag: "Project" })
  end
end

