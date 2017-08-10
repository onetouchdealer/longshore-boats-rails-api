class Conversation < ActiveRecord::Base
 belongs_to :sender, :foreign_key => :sender_id, class_name: 'User'
 belongs_to :recipient, :foreign_key => :recipient_id, class_name: 'User'

 has_many :messages, dependent: :destroy

 validates_uniqueness_of :sender_id, :scope => :recipient_id

 # ---This validation takes the sender_id and recipient_id for the conversation and checks whether a
 # ---conversation exists between these two ids because we only want two users to have one conversation
 scope :between, -> (sender_id,recipient_id) do
   where("(conversations.sender_id = ? AND conversations.recipient_id =?) OR
          (conversations.sender_id = ? AND conversations.recipient_id =?)",
          sender_id,recipient_id, recipient_id, sender_id)
 end

 def matched_name(current_user)
   if self.sender_id == current_user.id
     return User.find(self.recipient_id).name
   else
     return User.find(self.sender_id).name
   end
 end

 def matched_id(current_user)
   if self.sender_id == current_user.id
     return self.recipient_id
   else
    return self.sender_id
   end
 end

 def matched_email(current_user)
   if self.sender_id == current_user.id
     return User.find(self.recipient_id).email
   else
    return User.find(self.sender_id).email
   end
 end

 def matched_image(current_user)
   if self.sender_id == current_user.id
     return User.find(self.recipient_id).image.url(:thumb)
   else
    return User.find(self.sender_id).image.url(:thumb)
   end
 end

 def matched_dealership(current_user)
   if self.sender_id == current_user.id
     return User.find(self.recipient_id).dealership ? User.find(self.recipient_id).dealership : nil
   else
    return User.find(self.sender_id).dealership ? User.find(self.sender_id).dealership : nil
   end
 end

 def last_message_date
   self.messages.last.created_at
 end

 def format_last_message_date
   date = self.updated_at
   if date < DateTime.now.days_ago(7)
     return date.in_time_zone('Eastern Time (US & Canada)').strftime("%m/%d/%Y")
   elsif date < DateTime.now.beginning_of_day()
     return date.in_time_zone('Eastern Time (US & Canada)').strftime("%A")
   else
     return date.in_time_zone('Eastern Time (US & Canada)').strftime("%l:%M %P")
   end
 end

 # -- For socket.io rooms
 def unique_id
   ENV['IONIC_APP_ID'] + '.' + self.id.to_s
 end

end
