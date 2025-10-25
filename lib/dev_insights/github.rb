require "httparty"
require "date"
# require "clipboard"
require_relative "../utils/main"
require_relative "../utils/colors"


module DevInsights

  class GitHub
    @@API_ROOT_URL = "https://api.github.com"

    attr_reader :username

    def initialize(username, token)
      @username = username
      @token = token
      @repos = []
      @user = {}

      @HEADERS = @token ? { "Authorization" => "token #{@token}" } : {}
    end

    def repos
      data = get("#{@@API_ROOT_URL}/users/#{@username}/repos")

      @repos = data.map do |repo|
        {
          repo_name: MainUtils.safe_value(repo["name"]),
          repo_url: MainUtils.safe_value(repo["html_url"]),
          repo_owner: MainUtils.safe_value(repo["owner"]["login"]),
          repo_stars: repo["stargazers_count"],
          repo_forks: repo["forks_count"],
          repo_open_issues: repo["open_issues_count"],
          repo_language: MainUtils.safe_value(repo["language"] || "NOT FOUND"),
          repo_created_at: MainUtils.safe_value(repo["created_at"]),
          repo_updated_at: MainUtils.safe_value(repo["updated_at"])
        }
      end

      @repos
    end

    def user
      data = get("#{@@API_ROOT_URL}/users/#{@username}")
      data_params = ["login", "name", "bio", "location", "company", "email", "blog", "public_repos", "followers", "following", "created_at", "updated_at", "avatar_url", "html_url"]

      data_params.each do |param|
        if !data[param].is_a?(Integer)
          @user[param.to_sym] = MainUtils.safe_value(data[param])
        else
          @user[param.to_sym] = data[param] || 0
        end
      end

      @user
    end

    def stats(repo_name)
      data = get("#{@@API_ROOT_URL}/repos/#{@username}/#{repo_name}")
      
      {
        name: data["name"],
        full_name: data["full_name"],
        description: MainUtils.safe_value(data["description"]),
        language: MainUtils.safe_value(data["language"]),
        stargazers_count: data["stargazers_count"],
        forks_count: data["forks_count"],
        watchers_count: data["watchers_count"],
        open_issues_count: data["open_issues_count"],
        size: data["size"],
        default_branch: data["default_branch"],
        license: data["license"] ? data["license"]["name"] : "NOT FOUND",
        visibility: data["visibility"],
        created_at: data["created_at"],
        updated_at: data["updated_at"],
        pushed_at: data["pushed_at"],
        html_url: data["html_url"],
        topics: data["topics"] || [],
        archived: data["archived"],
        disabled: data["disabled"]
      }
    end

    def contribution_analysis(repo)
      data = get("#{@@API_ROOT_URL}/repos/#{@username}/#{repo}/commits?author=#{@username}")
      contribution_data = []

      data.each do |commit|
        contribution = {
          sha: commit["sha"],
          date: DateTime.parse(commit["commit"]["committer"]["date"]).strftime("%m/%d/%Y %H:%M:%S"),
          additions: commit["commit"]["additions"] || 0,
          deletions: commit["commit"]["deletions"] || 0,
          message: commit["commit"]["message"]
        }

        commit_data = get("#{@@API_ROOT_URL}/repos/#{@username}/#{repo}/commits/#{commit["sha"]}")
        contribution[:additions] = commit_data["stats"]["additions"]
        contribution[:deletions] = commit_data["stats"]["deletions"]

        contribution_data.push(contribution)
      end

      contribution_data
    end

    private

    def get(url)
      response = HTTParty.get(url, headers: @HEADERS)
      
      unless response.code == 200
        message = respone.parsed_response["message"] rescue "Unknown error"
        puts "#{CLIColors.red("[ERROR]")}: Github API Error #{response.code}: #{message}"
        return nil
      end

      # Clipboard.copy(response)
      response.parsed_response
    end

  end

end