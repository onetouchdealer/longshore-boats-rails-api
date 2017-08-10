require 'open-uri'
require 'net/http'

class Message < ActiveRecord::Base
 belongs_to :conversation
 belongs_to :user

 validates_presence_of :body

 def message_time
  created_at.strftime("%m/%d/%y at %l:%M %p")
 end

 def upload_notification_to_ionic
   puts "UPLOADING USER MESSAGE NOTIFICATION"
   token = nil;
   user_id = nil;
   username = "";
   conversation = self.conversation

   if self.user_id == conversation.sender_id
     user_id   = conversation.recipient_id
     sender_id = conversation.sender_id
   else
     user_id   = conversation.sender_id
     sender_id = conversation.recipient_id
   end

   username = User.find(sender_id).name.present? ? User.find(sender_id).name : User.find(sender_id).email
   token = User.find(user_id).device_token
   message_text = username + ": " + self.body

   unless token.nil?
     badge_count = Conversation.where('(recipient_id= ? AND recipient_read= ?) OR (sender_id= ? AND sender_read= ?)', user_id, false, user_id, false).count;

     params = {
       "tokens" => token,
       "profile" => ENV['IONIC_PUSH_ENV'],
       "notification":{
         "message": message_text,
         "payload": {
           "user_message": "1",
           "conversation_id": conversation.id
         },
         "android":{
           "title": "One Touch Dealer",
           "badge": "1",
           "sound": "true"
         },
          "ios": {
               "title": "One Touch Dealer",
               "sound": "true",
               "badge": badge_count
             }
       }
     }

     uri = URI.parse('https://api.ionic.io/push/notifications')
     https = Net::HTTP.new(uri.host,uri.port)
     https.use_ssl = true
     req = Net::HTTP::Post.new(uri.path)
     req['Authorization'] = ENV['IONIC_API_TOKEN']
     req['Content-Type'] = 'application/json'
     req.body = params.to_json
     res = https.request(req)
     puts res.body
   end
 end
end
