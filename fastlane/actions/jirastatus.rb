module Fastlane
  module Actions
    class JirastatusAction < Action
      def self.run(params)
        options = params || {}

        [:log].each do |key|
          UI.user_error!("No #{key} given.") unless options[key]
        end

        log = options[:log]

        if log != nil
          log_arr = log.split("\n")
          for item in log_arr do
              item_strip = item.strip
            if item_strip.include? "https://jira.hellotalk8.com/jira/browse/"
              # issue = item_strip.gsub(/.*\(https:\/\/jira.hellotalk8.com\/jira\/browse\//, '{"issue": "').gsub(/\)/, '') + '"}'
              #issue = item_strip.gsub(/.*\(https:\/\/jira.hellotalk8.com\/jira\/browse\//, '').gsub(/\)/, '')
              issue = item_strip.gsub(/.*https:\/\/jira.hellotalk8.com\/jira\/browse\//, '').gsub(/\)/, '')
              puts issue
              self.change_assignee(issue)
              # self.change_workflow_status(issue)
            end
          end
        end
      end

      def self.change_workflow_status(issue, workflow)
        require 'net/http'
        require 'net/https'
        require 'uri'
        require 'json'
        api = "https://jira.hellotalk8.com/jira/rest/api/2/issue/"
        url = api + "#{issue}" + "/transitions"
        uri = URI(url)
        header = {"Content-Type": "application/json"}
        workflow_id = {"transition":{"id":"#{workflow}"}}

        Net::HTTP.start(uri.host, uri.port,
          :use_ssl => uri.scheme == 'https',
          :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|

          request = Net::HTTP::Post.new(uri.request_uri, header)
          request.body = workflow_id.to_json
          request.basic_auth('jenkins', 'jenkinsauto')

          response = http.request(request)
          puts "Change workflow status code: #{response.code}"
        end
      end

      def self.change_assignee(issue)
        require 'net/http'
        require 'net/https'
        require 'uri'
        require 'json'
        api = "https://jira.hellotalk8.com/jira/rest/api/2/issue/"
        url = api + "#{issue}"
        puts "Issue url:"
        puts url
        uri = URI(url)
        header = {"Content-Type": "application/json"}

        Net::HTTP.start(uri.host, uri.port,
          :use_ssl => uri.scheme == 'https', 
          :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|

          #Get assignee info.
          request = Net::HTTP::Get.new(uri.request_uri, header)
          request.basic_auth('jenkins', 'jenkinsauto')

          response = http.request(request)
          full_json = JSON.parse(response.body)
          puts "Get assignee info status code: #{response.code}"

          if full_json['fields']['issuetype']['name'] == "Story"
            puts "Issue #{issue} type is: Story."
            #workflow "Passed Build" statu id
            workflow = "91"
            puts "Change status to: Passed Build."
            change_workflow_status(issue, workflow)
            #workflow "Product Verify" statu id
            workflow = "211"
            puts "Change status to: Product Verify."
            change_workflow_status(issue, workflow)

            if full_json['fields']['customfield_10521']
              pm = full_json['fields']['customfield_10521']['name']
            end

            if full_json['fields']['customfield_10514']
              data = full_json['fields']['customfield_10514']['name']
            end

            if full_json['fields']['customfield_10515']
              operation = full_json['fields']['customfield_10515']['name']
            end

            if full_json['fields']['reporter']
              reporter = full_json['fields']['reporter']['name']
            end

            if pm
              user = pm
            elsif data
              user = data
            elsif operation
              user = operation
            else
              user = reporter
            end
          #elsif
          else
            full_json['fields']['issuetype']['name'] == "Story Bugs"
            puts "Issue #{issue} type is: Story Bugs."
            user = "sunshine"
            #workflow "Story Bug Fixed" statu id
            workflow = "11"
            puts "Change status to: Story Bug Fixed."
            change_workflow_status(issue, workflow)
          #else
          #  puts "Issue #{issue} type is: Bugs."
          #  #user = full_json['fields']['reporter']['name']
          #  user = "sunshine"
          #  #workflow "Passed Build" statu id
          #  workflow = "91"
          #  puts "Change status to: Passed Build."
          #  change_workflow_status(issue, workflow)
          end

          assignee = {"update": {"assignee": [{"set": {"name": "#{user}"}}]}}

          #set assignee.
          request = Net::HTTP::Put.new(uri.request_uri, header)
          request.body = assignee.to_json
          puts "assignee josn: #{request.body}"
          request.basic_auth('jenkins', 'jenkinsauto')

          response = http.request(request)

          puts "Change assignee to #{user}."
          puts "Set assignee status code: #{response.code}"
        end
      end

      def self.description
        "Change jira workflow status and assignee."
      end

      def self.available_options
        [
          ['log', 'log_from_changelog'],
        ]
      end

      def self.author
        "Archon"
      end

      def self.is_supported?(platform)
        true
      end

      def self.example_code
        [
          'jirastatus(
              log: "log_from_changelog"
          )'
        ]
      end

      def self.category
        :notifications
      end
    end
  end
end
