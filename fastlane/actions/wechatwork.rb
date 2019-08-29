module Fastlane
  module Actions
    class WechatworkAction < Action
      def self.run(params)
        options = params || {}

        [:markdown, :webhook, :mentioned_mobile_list].each do |key|
          UI.user_error!("No #{key} given.") unless options[key]
        end

        markdown = options[:markdown]
        webhook = options[:webhook]
        mentioned_mobile_list = options[:mentioned_mobile_list]

        params = {}
        params["msgtype"] = "markdown"
        params["markdown"] = {"content": markdown}
        self.post_to_wechat(webhook, params)

        if mentioned_mobile_list.empty? == false
          params = {}
          params["msgtype"] = "text"
          text = mentioned_mobile_list.split(',').map{|item| item.to_i }
          params["text"] = {"content": "", "mentioned_mobile_list": text}
          puts text
          self.post_to_wechat(webhook, params)
        end

      end

      def self.post_to_wechat(webhook, params)
        require 'net/http'
        require 'uri'
        require 'json'

        uri = URI.parse("#{webhook}")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        # 设置请求参数
        data = params.to_json

        # 设置请求头
        header = {'Content-Type':'application/json'}
        response = http.post(uri, data, header)
        self.check_response(response)

      end

      def self.check_response(response)
        case response.code.to_i
        when 200, 204
          UI.success('---Successfully sent wechatwork notification')
          true
        else
          UI.user_error!("--- Could not sent wechatwork notification")
        end
      end

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
