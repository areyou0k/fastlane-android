module Fastlane
  module Actions
    class JirastatusAction < Action
      def self.run(params)
        options = params || {}

        [:log].each do |key|
          UI.user_error!("No #{key} given.") unless options[key]
        end

        log = options[:log]

        # params = {}
        # params["msgtype"] = "markdown"
        # params["markdown"] = {"content": markdown}
        # self.post_to_wechat(webhook, params)

        # if mentioned_mobile_list.empty? == false
        #   params = {}
        #   params["msgtype"] = "text"
        #   phone_list = mentioned_mobile_list.split(',').map{|item| item.to_i }
        #   params["text"] = {"content": "", "mentioned_mobile_list": phone_list}
        #   self.post_to_wechat(webhook, params)
        # end

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
          request.basic_auth('archon', '$ht412765707+1s')
        
          response = http.request(request)
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
        assig = {"update": {"assignee": [{"set": {"name": "#{issue['user']}"}}]}}
      
        Net::HTTP.start(uri.host, uri.port,
          :use_ssl => uri.scheme == 'https', 
          :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
        
          request = Net::HTTP::Put.new(uri.request_uri, header)
          request.body = assig.to_json
          puts request.body
          request.basic_auth('archon', '$ht412765707+1s')
        
          response = http.request(request)
          puts "Headers: #{response.to_hash.inspect}"
        
          puts response.code
        end   
      end


      # def self.check_response(response)
      #   case response.code.to_i
      #   when 200, 204
      #     UI.success('---Successfully sent wechatwork notification')
      #     true
      #   else
      #     UI.user_error!("--- Could not sent wechatwork notification")
      #   end
      # end

      def self.description
        "Post a markdown to [WeChat_Work](https://work.weixin.qq.com/api/doc#90000/90136/91770)"
      end

      def self.available_options
        [
          ['webhook', 'wechatwork webhook'],
          ['markdown', 'The markdown to post'],
          ['mentioned_mobile_list', 'The mentioned_mobile_list']
        ]
      end

      def self.author
        "Korol Zhu"
      end

      def self.is_supported?(platform)
        true
      end

      def self.example_code
        [
          'wechatwork(
              webhook: "url",
              markdown: "",
              mentioned_mobile_list: ["136***", "159***"]
          )'
        ]
      end

      def self.category
        :notifications
      end
    end
  end
end
