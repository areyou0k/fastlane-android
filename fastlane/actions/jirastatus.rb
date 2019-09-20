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
              issue = item_strip.gsub(/.*\(https:\/\/jira.hellotalk8.com\/jira\/browse\//, '{"issue": "').gsub(/\).*\[Assignee\]/, '", "user": "') + '"}'
              issue_json = JSON.parse(issue)
              puts issue_json
              self.change_assignee(issue_json)
              self.change_workflow_status(issue_json)
            end
          end
        end
      end

      def self.change_workflow_status(issue)
        require 'net/http'
        require 'net/https'
        require 'uri'
        require 'json'
        api = "https://jira.hellotalk8.com/jira/rest/api/2/issue/"
        url = api + "#{issue['issue']}" + "/transitions"
        uri = URI(url)
        header = {"Content-Type": "application/json"}
        workflow_id = {"transition":{"id":"91"}}
      
        Net::HTTP.start(uri.host, uri.port,
          :use_ssl => uri.scheme == 'https', 
          :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
        
          request = Net::HTTP::Post.new(uri.request_uri, header)
          request.body = workflow_id.to_json
          request.basic_auth('zhangfeng', '12345678')
        
          response = http.request(request)
          puts "Change workflow to BUILT(id: 91)."
          puts response.code
        end 
      end

      def self.change_assignee(issue)
        require 'net/http'
        require 'net/https'
        require 'uri'
        require 'json'
        api = "https://jira.hellotalk8.com/jira/rest/api/2/issue/"
        url = api + "#{issue['issue']}"
        uri = URI(url)
        puts url
        header = {"Content-Type": "application/json"}
        if "#{issue['user']}" != nil
          assig = {"update": {"assignee": [{"set": {"name": "#{issue['user']}"}}]}}
      
          Net::HTTP.start(uri.host, uri.port,
            :use_ssl => uri.scheme == 'https', 
            :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
          
            request = Net::HTTP::Put.new(uri.request_uri, header)
            request.body = assig.to_json
            puts request.body
            request.basic_auth('zhangfeng', '12345678')
          
            response = http.request(request)
            
            puts "Change assignee to #{issue['user']}."
            puts response.code
          end
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
