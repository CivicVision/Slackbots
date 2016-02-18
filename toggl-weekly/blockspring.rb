require 'blockspring'
require 'rest-client'
require 'json'

def week_start( date, offset_from_sunday=0 )
  date - (date.wday - offset_from_sunday)%7
end

def humanize_hours(milliseconds)
    hours, min = (milliseconds / 1000 / 60 ).divmod(60)
    "#{hours} h, #{min} min"
end

def webhook(team_domain, service_id, token, user_name, team_id, user_id, channel_id, timestamp, channel_name, text, trigger_word, raw_text,toggl_key,workspace_id)

    d = Date.today
    start_of_the_week = week_start(d,1).iso8601
    url = "https://#{toggl_key}:api_token@toggl.com/reports/api/v2/weekly?workspace_id=#{workspace_id}&since=#{start_of_the_week}&user_agent=api_test"
    r = RestClient.get(url)
    results = JSON.parse(r)
    hours = humanize_hours(results["total_grand"])
    response = "Weekly total: ~ #{hours}"

    return {
        text: response,  # send a text response (replies to channel if not blank)
        attachments: [], # add attatchments: https://api.slack.com/docs/attachments
        username: "Toggl Weekly Report",    # overwrite configured username (ex: MyCoolBot)
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
    toggl_key = request.params['TOGGL_KEY']
    workspace_id = request.params['workspace_id']

    # ignore all bot messages
    return if user_id == 'USLACKBOT'

    # Strip out trigger word from text if given
    if trigger_word
        text = text[trigger_word.length..text.length].strip
    end

    # Execute bot function
    output = webhook(team_domain, service_id, token, user_name, team_id, user_id, channel_id, timestamp, channel_name, text, trigger_word, raw_text,toggl_key,workspace_id)

    # set any keys that aren't blank
    output.keys.each do |k|
        response.addOutput(k, output[k]) unless output[k].nil? or output[k].empty?
    end

    response.end
end

Blockspring.define(block)
