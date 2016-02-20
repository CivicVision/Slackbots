require 'blockspring'
require 'rest-client'
require 'json'

def get_json_result(url)
	r = RestClient.get(url)
    JSON.parse(r)
end

def get_campaigns(drip_key, account_id)
    url = "https://#{drip_key}:@api.getdrip.com/v2/#{account_id}/campaigns"
    result = get_json_result(url)
    campaigns = result["campaigns"].map do |campaign|
    	"#{campaign["name"]}: #{campaign["active_subscriber_count"]} Subscribers"
	end
    "Your campagins: \n#{campaigns.join("\n")}"
end

def get_subscribers(drip_key, account_id)
    status = status || "active"
    url = "https://#{drip_key}:@api.getdrip.com/v2/#{account_id}/subscribers?status=#{status}"
    result = get_json_result(url)
    "Subscribers: #{result["subscribers"].count}"
end

def webhook(team_domain, service_id, token, user_name, team_id, user_id, channel_id, timestamp, channel_name, text, trigger_word, raw_text,drip_key, account_id, type, status)
    if drip_key && account_id
        response = case type
        when "campaigns"
        	get_campaigns(drip_key, account_id)
		else
        	get_subscribers(drip_key, account_id)
		end
    else
        response = "No keys provided"
    end

    return {
        text: response,  # send a text response (replies to channel if not blank)
        attachments: [], # add attatchments: https://api.slack.com/docs/attachments
        username: "Drip Subscriber Report",    # overwrite configured username (ex: MyCoolBot)
        icon_url: "",    # overwrite configured icon (ex: https://mydomain.com/some/image.png
        icon_emoji: "",  # overwrite configured icon (ex: :smile:)
    }
end


block = lambda do |request, response|
    team_domain = request.params['team_domain']
    service_id = request.params['service_id']
    token = request.params['token']
    user_name = request.params['user_name']
    team_id = request.params['team_id']
    user_id = request.params['user_id']
    channel_id = request.params['channel_id']
    timestamp = request.params['timestamp']
    channel_name = request.params['channel_name']
    raw_text = text = request.params['text']
    trigger_word = request.params['trigger_word']
    drip_key = request.params['drip_key']
    account_id = request.params['account_id']
    status = request.params['status']
    type = request.params['type']


    # ignore all bot messages
    return if user_id == 'USLACKBOT'

    # Strip out trigger word from text if given
    if trigger_word
        text = text[trigger_word.length..text.length].strip
    end

    # Execute bot function
    output = webhook(team_domain, service_id, token, user_name, team_id, user_id, channel_id, timestamp, channel_name, text, trigger_word, raw_text, drip_key, account_id, type, status)

    # set any keys that aren't blank
    output.keys.each do |k|
        response.addOutput(k, output[k]) unless output[k].nil? or output[k].empty?
    end

    response.end
end

Blockspring.define(block)
